-- ============================================================================
-- MELEE AUTOFARM SCRIPT (SEQUENCE TARGETING)
-- Contains Model, View, and Controller logic in a single file
-- ============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer

-- Clean up any previously running instance of the script
if getgenv().StopAutofarm then
    pcall(function() getgenv().StopAutofarm() end)
    task.wait(0.2)
end
-- ==========================================
-- CONFIGURATION
-- ==========================================
local Y_LEVEL_DETECTION_RADIUS = 15 -- Max height difference allowed before breaking the path

local MACRO_WAYPOINTS = getgenv().MACRO_WAYPOINTS
if not MACRO_WAYPOINTS then
    warn("MACRO_WAYPOINTS not found! Make sure you run a Stage script first.")
    return
end
local currentStage = getgenv().CURRENT_STAGE or 1


local EVASION_DIRECTIONS = {
    Vector3.new(1, 0, 0),   -- Slide Right
    Vector3.new(0, 1, 0)    -- Climb Up
}

-- ==========================================
-- DEBUG VISUALIZERS
-- ==========================================
local visualizerFolder = Workspace:FindFirstChild("AutofarmVisuals")
if visualizerFolder then visualizerFolder:Destroy() end
visualizerFolder = Instance.new("Folder")
visualizerFolder.Name = "AutofarmVisuals"
visualizerFolder.Parent = Workspace

local function drawWaypoints(pathWaypoints)
    visualizerFolder:ClearAllChildren()
    for i, wp in ipairs(pathWaypoints) do
        local p = Instance.new("Part")
        p.Name = "WP_" .. tostring(i)
        p.Anchored = true
        p.CanCollide = false
        p.Size = Vector3.new(1, 1, 1)
        p.Material = Enum.Material.Neon
        p.Shape = Enum.PartType.Ball
        p.Color = Color3.new(0, 1, 0)
        p.Position = wp.Position
        p.Parent = visualizerFolder
    end
end

local function drawTarget(pos)
    local targetVisual = visualizerFolder:FindFirstChild("CurrentTarget")
    if not targetVisual then
        targetVisual = Instance.new("Part")
        targetVisual.Name = "CurrentTarget"
        targetVisual.Anchored = true
        targetVisual.CanCollide = false
        targetVisual.Size = Vector3.new(2, 2, 2)
        targetVisual.Material = Enum.Material.Neon
        targetVisual.Shape = Enum.PartType.Ball
        targetVisual.Color = Color3.new(1, 0, 0)
        targetVisual.Parent = visualizerFolder
    end
    targetVisual.Position = pos
end

local function blockcastSolid(cframe, extents, dir, params)
    local result = Workspace:Blockcast(cframe, extents, dir, params)
    local loops = 0
    while result and not result.Instance.CanCollide and loops < 10 do
        local currentList = params.FilterDescendantsInstances
        table.insert(currentList, result.Instance)
        params.FilterDescendantsInstances = currentList
        loops = loops + 1
        result = Workspace:Blockcast(cframe, extents, dir, params)
    end
    return result
end

-- ==========================================
-- MODEL
-- ==========================================
local Model = {}

Model.State = {
    isAutoFarming = false,
    evadingTimer = 0,
    evasionDir = Vector3.new(0, 0, 0),
    mazePath = {},
    mazeIndex = 1,
    stuckTimer = 0,
    lastMazeDist = 0,
    botMode = "NAVIGATE_MAZE", -- "NAVIGATE_MAZE", "ROOM_ROUND_UP", "ROOM_COMBAT"
    roundUpTimer = 0,
    macroIndex = 1,
    isComputingPath = false
}

local flySpeed = 50
local currentEnemy = nil
local targetSwitchTimer = 2
local switchInterval = 2
local ENEMY_DETECTION_RADIUS = 60 -- Only focus on close enemies so we don't try to round up the whole map

local lastStaminaTick = 0
local function drainStamina(character)
    local currentTick = tick()
    if currentTick - lastStaminaTick < 0.3 then return end
    lastStaminaTick = currentTick

    local staminaVal = nil
    local staminaObj = character:FindFirstChild("Stamina") or character:FindFirstChild("Energy")
    if staminaObj and staminaObj:IsA("NumberValue") then
        staminaVal = staminaObj
    else
        local attr = character:GetAttribute("Stamina") or character:GetAttribute("Energy")
        if attr ~= nil then
            if not character:FindFirstChild("_StaminaHolder") then
                local holder = Instance.new("NumberValue")
                holder.Name = "_StaminaHolder"
                holder.Value = attr
                holder.Parent = character
            end
            staminaVal = character:FindFirstChild("_StaminaHolder")
        end
    end
    if staminaVal then
        staminaVal.Value = math.max(0, staminaVal.Value - 1)
    end
end

-- Helper to find valid enemies across multiple folders
local function getAllEnemies()
    local allEnemies = {}
    if Workspace:FindFirstChild("NPCs") then
        for _, npc in ipairs(Workspace.NPCs:GetChildren()) do
            table.insert(allEnemies, npc)
        end
    end
    return allEnemies
end

local function isValidTarget(npc)
    if not npc:FindFirstChild("HumanoidRootPart") then return false end
    
    local humanoid = npc:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then return true end
    
    return false
end

-- Find the highest priority target, prioritizing the closest one that is in line of sight
local function findBestTarget(allEnemies)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local closestTarget = nil
    local closestDist = math.huge
    
    -- Setup Raycast for Line of Sight
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character, Workspace:FindFirstChild("NPCs")}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    for _, npc in ipairs(allEnemies) do
        if isValidTarget(npc) then
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (rootPart.Position - hrp.Position).Magnitude
                if dist <= ENEMY_DETECTION_RADIUS then
                    -- Cast a ray to the enemy to check for walls
                    local dir = (hrp.Position - rootPart.Position)
                    local result = Workspace:Raycast(rootPart.Position, dir, params)
                    
                    -- If result is nil, there are no walls in the way!
                    if not result then
                        if dist < closestDist then
                            closestDist = dist
                            closestTarget = npc
                        end
                    end
                end
            end
        end
    end
    
    return closestTarget
end


function Model.ResetPhysics()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        root.Anchored = false
        local bv = root:FindFirstChild("AntiGravity")
        if bv then bv:Destroy() end
    end
    currentEnemy = nil
    Model.State.mazePath = {}
    Model.State.isComputingPath = false
    Model.State.evadingTimer = 0
    Model.State.stuckTimer = 0
    visualizerFolder:ClearAllChildren()
end

function Model.ApplyNoclip()
    -- Disabled by user request: do not phase through walls
end

function Model.UpdateTracking(deltaTime)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return end
    
    local humanoid = character.Humanoid
    local rootPart = character.HumanoidRootPart
    
    local isRagdolled = (character.Parent and character.Parent.Name == "Ragdolls")
    local isStunned = character:FindFirstChild("Stun") or character:FindFirstChild("frozen") or _G.canuse == false
    local isDead = humanoid.Health <= 0
    
    if isRagdolled or isStunned or isDead then
        rootPart.Anchored = true
        rootPart.Velocity = Vector3.new(0, 0, 0)
        return
    else
        rootPart.Anchored = false
    end

    -- Checkpoint logic removed to allow Floor 2 navigation

    local allEnemies = getAllEnemies()

    -- Check if current enemy died
    if currentEnemy then
        local isAlive = false
        local cName = currentEnemy.Name
        if currentEnemy.Parent ~= nil then
            local hum = currentEnemy:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then isAlive = true end
        end
        if not isAlive then
            currentEnemy = nil
            targetSwitchTimer = switchInterval
        end
    end

    local isPatrolling = false
    local targetDest = nil

    Model.State.isWaitingAtSafeSpot = false

    -- Legacy fallback
    if Model.State.botMode == "PATROL" then Model.State.botMode = "NAVIGATE_MAZE" end
    if Model.State.botMode == "ROUND_UP" then Model.State.botMode = "ROOM_ROUND_UP" end
    if Model.State.botMode == "COMBAT" then Model.State.botMode = "ROOM_COMBAT" end

    if Model.State._lastLoggedState ~= Model.State.botMode then
        print("[AutoFarm Debug] State changed to: " .. tostring(Model.State.botMode))
        Model.State._lastLoggedState = Model.State.botMode
    end

    if Model.State.botMode == "NAVIGATE_MAZE" then
        currentEnemy = nil
        isPatrolling = true
        
        -- 1. Check for ANY enemy within 15 studs to clear first (ignore line of sight, 15 studs is contact)
        local contactEnemy = nil
        local contactDist = 15
        for _, npc in ipairs(allEnemies) do
            if isValidTarget(npc) then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (rootPart.Position - hrp.Position).Magnitude
                    if dist <= contactDist then
                        contactDist = dist
                        contactEnemy = npc
                    end
                end
            end
        end
        
        -- Combat is currently disabled/unimplemented. If enemies block the path, the stuck/noclip logic will bypass them.
        if contactEnemy then
            print("[AutoFarm] Enemy in contact! Clearing it first...")
            Model.State.botMode = "MAZE_COMBAT"
            currentEnemy = contactEnemy
            targetDest = contactEnemy:FindFirstChild("HumanoidRootPart").Position
            -- Model.State.mazePath = {} -- Preserve path so it doesn't freeze recomputing after killing
        else
            -- Check if we are blocked by an enemy further out (with Line of Sight)
            local bestTarget = findBestTarget(allEnemies)
            local targetHrp = bestTarget and bestTarget:FindFirstChild("HumanoidRootPart")
                if targetHrp and (rootPart.Position - targetHrp.Position).Magnitude <= ENEMY_DETECTION_RADIUS then
                    print("[AutoFarm Debug] Enemy blocking path! Punishing...")
                    Model.State.botMode = "MAZE_COMBAT"
                    currentEnemy = bestTarget
                    targetDest = targetHrp.Position
                    -- Model.State.mazePath = {} -- Preserve path so it doesn't freeze recomputing after killing
            else
                -- No enemies in the way, pathfind through the maze!
                local currentMacro = MACRO_WAYPOINTS[Model.State.macroIndex]
                
                local arrivalDist = (currentMacro and currentMacro.Action == "PULL_LEVER") and 5 or 15
                -- Auto-advance if we reached it
                if currentMacro and (rootPart.Position - currentMacro.Pos).Magnitude < arrivalDist then
                    if currentMacro.Action == "WAIT_TELEPORT" then
                        -- Don't advance! Just hover and wait for the game to teleport us.
                        -- The auto-skip logic below will catch us when we land on F2.
                        if rootPart.Position.Y > 2300 then
                            print("[AutoFarm] 🚀 Successfully teleported to Floor 2! Please run the Stage 2 Loader!")
                        end
                    elseif currentMacro.Action == "END_MAZE" then
                        print("[AutoFarm Debug] Reached the final destination! Securing the room...")
                        Model.State.botMode = "ROOM_ROUND_UP"
                        Model.State.roundUpTimer = 5
                        targetDest = rootPart.Position
                        currentMacro = nil
                    else
                        print("[AutoFarm] Reached Macro Waypoint " .. tostring(Model.State.macroIndex))
                        if currentMacro.Action == "PULL_LEVER" then
                            local islandsFolder = Workspace:FindFirstChild("Islands")
                            if islandsFolder then
                                local f2 = islandsFolder:FindFirstChild("Impel Base - Floor 2")
                                local interactables = f2 and f2:FindFirstChild("Interactables")
                                local lever = interactables and interactables:FindFirstChild("BossGateLever")
                                if lever then
                                    for _, desc in ipairs(lever:GetDescendants()) do
                                        if desc:IsA("ProximityPrompt") then
                                            print("[AutoFarm] Pulling Boss Gate Lever!")
                                            local bv = rootPart:FindFirstChild("AntiGravity")
                                            if bv then bv.Velocity = Vector3.new(0, 0, 0) end
                                            fireproximityprompt(desc)
                                            task.wait(1.5) -- wait for gate to animate
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        Model.State.macroIndex = Model.State.macroIndex + 1
                        currentMacro = MACRO_WAYPOINTS[Model.State.macroIndex]
                        Model.State.mazePath = {} -- Force recalculation
                        visualizerFolder:ClearAllChildren()
                    end
                end
                
                -- Auto-skip if we are closer to a future waypoint
                local closestIdx = Model.State.macroIndex
                local distToCurrent = currentMacro and (rootPart.Position - currentMacro.Pos).Magnitude or math.huge
                
                for i = Model.State.macroIndex + 1, #MACRO_WAYPOINTS do
                    local distToFuture = (rootPart.Position - MACRO_WAYPOINTS[i].Pos).Magnitude
                    -- ONLY skip if we teleported and a future waypoint is drastically closer (e.g. F2 vs F1)
                    -- We DO NOT skip based on pure distance (<50) to prevent skipping maze checkpoints!
                    if distToFuture < (distToCurrent - 1000) then
                        closestIdx = i
                        distToCurrent = distToFuture
                    end
                    
                    -- If this waypoint is a mandatory action (like pulling a lever), 
                    -- we CANNOT skip past it to future waypoints, otherwise we break the sequence!
                    if MACRO_WAYPOINTS[i].Action == "PULL_LEVER" then
                        break
                    end
                end
                
                if closestIdx > Model.State.macroIndex then
                    print("[AutoFarm Debug] Detected we are much closer to Macro Waypoint " .. tostring(closestIdx) .. ". Skipping ahead!")
                    Model.State.macroIndex = closestIdx
                    currentMacro = MACRO_WAYPOINTS[Model.State.macroIndex]
                    Model.State.mazePath = {}
                    visualizerFolder:ClearAllChildren()
                end
                
                if not currentMacro then
                    print("[AutoFarm Debug] Reached the final destination! Securing the room...")
                    Model.State.botMode = "ROOM_ROUND_UP"
                    Model.State.roundUpTimer = 5
                    targetDest = rootPart.Position
                elseif currentMacro.Action == "WAIT_TELEPORT" and distToCurrent < 15 then
                    targetDest = rootPart.Position -- We reached the pad, hover and wait for skip
                else
                    local currentGoal = currentMacro.Pos
                    if #Model.State.mazePath == 0 or Model.State.mazeIndex > #Model.State.mazePath then
                        if currentMacro.Action == "FLY_DIRECT" then
                            -- Bypass PathfindingService completely and just fly in a straight line
                            targetDest = currentMacro.Pos
                        elseif not Model.State.isComputingPath then
                            Model.State.isComputingPath = true
                            print("[AutoFarm] Calculating Maze Path to: " .. tostring(currentGoal))
                            
                            -- Spawn in a new thread to PREVENT Heartbeat lag spikes!
                            task.spawn(function()
                                local path = PathfindingService:CreatePath({
                                    AgentRadius = 4, -- Increased to 4 to prevent corner-cutting and wall-clipping
                                    AgentHeight = 4,
                                    AgentCanJump = true,
                                    AgentCanClimb = true, -- Crucial for ladders and stairs!
                                    WaypointSpacing = 4,
                                    Costs = { Water = 20 }
                                })
                                
                                -- The bot hovers, which makes startPos float in mid-air. We MUST raycast down to the floor so PathfindingService can find the NavMesh!
                                local startPos = rootPart.Position
                                local rpParams = RaycastParams.new()
                                rpParams.FilterDescendantsInstances = {character, Workspace:FindFirstChild("NPCs")}
                                rpParams.FilterType = Enum.RaycastFilterType.Exclude
                                
                                local floorRay = Workspace:Raycast(rootPart.Position, Vector3.new(0, -100, 0), rpParams)
                                if floorRay then
                                    startPos = floorRay.Position + Vector3.new(0, 2, 0)
                                end
                                
                                local goalPos = currentGoal
                                local goalRay = Workspace:Raycast(currentGoal + Vector3.new(0, 10, 0), Vector3.new(0, -100, 0), rpParams)
                                if goalRay then
                                    goalPos = goalRay.Position + Vector3.new(0, 2, 0)
                                end
                                
                                local success, err = pcall(function()
                                    path:ComputeAsync(startPos, goalPos)
                                end)
                                
                                if success and path.Status == Enum.PathStatus.Success then
                                    Model.State.mazePath = path:GetWaypoints()
                                    Model.State.mazeIndex = 2 -- Skip first waypoint (current pos)
                                    drawWaypoints(Model.State.mazePath)
                                else
                                    print("[AutoFarm Debug] Pathfinding failed! (Status: " .. tostring(path.Status) .. ") Retrying in 1 second...")
                                    task.wait(1)
                                end
                                Model.State.isComputingPath = false
                            end)
                        end
                    end
                    
                    if Model.State.isComputingPath then
                        -- Hover in place safely while computing without lagging the game
                        targetDest = rootPart.Position
                    elseif currentMacro.Action == "FLY_DIRECT" then
                        targetDest = currentMacro.Pos
                    elseif Model.State.mazePath and Model.State.mazeIndex <= #Model.State.mazePath then
                        local rawPos = Model.State.mazePath[Model.State.mazeIndex].Position
                        targetDest = rawPos + Vector3.new(0, 3.5, 0)
                    else
                        targetDest = rootPart.Position
                    end
                end
            end
        end
        
    elseif Model.State.botMode == "MAZE_COMBAT" then
        isPatrolling = false
        
        if not currentEnemy or not isValidTarget(currentEnemy) then
            print("[AutoFarm] Obstacle cleared! Resuming maze.")
            Model.State.botMode = "NAVIGATE_MAZE"
            targetDest = rootPart.Position
            local bv = rootPart:FindFirstChild("AntiGravity")
            if bv then bv.Velocity = Vector3.new(0, 0, 0) end
            rootPart.Velocity = Vector3.new(0, 0, 0)
        else
            -- Dive bomb the enemy
            local hrp = currentEnemy:FindFirstChild("HumanoidRootPart")
            if hrp then
                targetDest = hrp.Position
            end
        end
        
    elseif Model.State.botMode == "ROOM_ROUND_UP" then
        isPatrolling = false
        Model.State.roundUpTimer = Model.State.roundUpTimer - deltaTime
        
        local validEnemies = {}
        for _, npc in ipairs(allEnemies) do
            if isValidTarget(npc) then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                if hrp and (rootPart.Position - hrp.Position).Magnitude <= 200 then
                    table.insert(validEnemies, hrp)
                end
            end
        end
        
        if #validEnemies == 0 then
            -- No enemies left in room!
            targetDest = rootPart.Position
            local bv = rootPart:FindFirstChild("AntiGravity")
            if bv then bv.Velocity = Vector3.new(0, 0, 0) end
            rootPart.Velocity = Vector3.new(0, 0, 0)
        else
            -- Calculate Center Position
            local centerPos = Vector3.new(0, 0, 0)
            for _, hrp in ipairs(validEnemies) do
                centerPos = centerPos + hrp.Position
            end
            centerPos = centerPos / #validEnemies
            targetDest = centerPos
            
            currentEnemy = validEnemies[1].Parent -- Keep currentEnemy valid for raycast filters
            
            -- Check if all enemies are clumped (close to the center)
            local allClumped = true
            for _, hrp in ipairs(validEnemies) do
                if (centerPos - hrp.Position).Magnitude > 5 then
                    allClumped = false
                    break
                end
            end
            
            if allClumped or Model.State.roundUpTimer <= 0 then
                print("[AutoFarm] Enemies rounded up! Initiating COMBAT.")
                Model.State.botMode = "ROOM_COMBAT"
            end
        end
        
    elseif Model.State.botMode == "ROOM_COMBAT" then
        isPatrolling = false
        
        local validEnemies = {}
        for _, npc in ipairs(allEnemies) do
            if isValidTarget(npc) then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                if hrp and (rootPart.Position - hrp.Position).Magnitude <= 200 then
                    table.insert(validEnemies, hrp)
                end
            end
        end
        
        if #validEnemies == 0 then
            -- Enemies dead! Wait here for respawns.
            Model.State.botMode = "ROOM_ROUND_UP"
            targetDest = rootPart.Position
            local bv = rootPart:FindFirstChild("AntiGravity")
            if bv then bv.Velocity = Vector3.new(0, 0, 0) end
            rootPart.Velocity = Vector3.new(0, 0, 0)
        else
            -- Sort enemies by distance so we lock onto the closest one!
            table.sort(validEnemies, function(a, b)
                return (rootPart.Position - a.Position).Magnitude < (rootPart.Position - b.Position).Magnitude
            end)
            
            -- Dive bomb the closest enemy!
            targetDest = validEnemies[1].Position
            currentEnemy = validEnemies[1].Parent
        end
    end
    
    if targetDest then
        local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
        bv.Name = "AntiGravity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = rootPart
        
        local raycastParams = RaycastParams.new()
        if currentEnemy then
            raycastParams.FilterDescendantsInstances = {character, currentEnemy}
        else
            raycastParams.FilterDescendantsInstances = {character}
        end
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local flatTarget = Vector3.new(targetDest.X, 0, targetDest.Z)
        local flatCurrent = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
        local horizontalDistance = (flatTarget - flatCurrent).Magnitude
        
        -- Use true 3D distance to determine if we reached the waypoint, so we don't skip steep ramps!
        local arrivalDistance = (targetDest - rootPart.Position).Magnitude
        
        if isPatrolling then
            if not Model.State.isComputingPath then
                if not Model.State.lastMazeDist then Model.State.lastMazeDist = arrivalDistance end
                
                local distDiff = math.abs(Model.State.lastMazeDist - arrivalDistance)
                if distDiff < 0.05 then
                    Model.State.stuckTimer = Model.State.stuckTimer + deltaTime
                else
                    Model.State.stuckTimer = 0
                end
                Model.State.lastMazeDist = arrivalDistance
                
                if Model.State.stuckTimer > 0.5 then
                    print("[AutoFarm Debug] Stuck in maze! Noclipping & Dashing...")
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.CanCollide = false
                        end
                    end
                    if character:FindFirstChild("Humanoid") then
                        character.Humanoid.Jump = true
                    end
                    Model.State.mazePath = {} -- Force recalculation
                    Model.State.stuckTimer = -1.0 -- Wait before checking stuck again
                    
                    -- Restore collisions shortly after to prevent flying through the entire maze
                    task.delay(1.5, function()
                        if character then
                            for _, part in ipairs(character:GetDescendants()) do
                                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                    part.CanCollide = true
                                end
                            end
                        end
                    end)
                end
            else
                Model.State.stuckTimer = 0
            end
            
            if arrivalDistance <= 3.0 and #Model.State.mazePath > 0 and Model.State.mazeIndex <= #Model.State.mazePath then
                Model.State.mazeIndex = Model.State.mazeIndex + 1
                if Model.State.mazeIndex > #Model.State.mazePath then
                    print("[AutoFarm Debug] Reached Maze Destination!")
                    Model.State.mazePath = {} -- Re-compute or just hover
                    visualizerFolder:ClearAllChildren()
                else
                    local rawPos = Model.State.mazePath[Model.State.mazeIndex].Position
                    targetDest = rawPos + Vector3.new(0, 3.5, 0)
                    flatTarget = Vector3.new(targetDest.X, 0, targetDest.Z)
                    horizontalDistance = (flatTarget - flatCurrent).Magnitude
                    arrivalDistance = (targetDest - rootPart.Position).Magnitude
                end
            end
        end
        
        -- 2. EVASION LOGIC & LOOK DIRECTION
        local moveDir = (flatTarget - flatCurrent).Unit
        if horizontalDistance == 0 then moveDir = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z).Unit end

        -- 1. Determine Hovercraft Height via Downward Raycast (Look 5 studs ahead to anticipate stairs)
        local _, size = character:GetBoundingBox()
        local floorRayOrigin = rootPart.Position + (moveDir * 5) + Vector3.new(0, 10, 0)
        local floorRay = Workspace:Raycast(floorRayOrigin, Vector3.new(0, -50, 0), raycastParams)
        
        local currentFloorY = rootPart.Position.Y - 7.5
        if floorRay then
            currentFloorY = floorRay.Position.Y
        end
        

        local desiredY = currentFloorY + 4 -- Hover low to the ground
        local isCloseToArrival = (horizontalDistance <= 15)
        
        local targetSpot
        if isPatrolling then
            -- CRITICAL: When following macro paths, we MUST fly to their exact Y altitude!
            desiredY = targetDest.Y
            targetSpot = Vector3.new(targetDest.X, desiredY, targetDest.Z)
        else
            if isCloseToArrival then
                desiredY = targetDest.Y + 8 -- Go 8 studs above target's height when close to enemy
                
                -- Orbit like a halo above the enemy
                local orbitRadius = 6
                local orbitSpeed = 4
                local offsetX = math.cos(tick() * orbitSpeed) * orbitRadius
                local offsetZ = math.sin(tick() * orbitSpeed) * orbitRadius
                
                local centerOrbit = Vector3.new(targetDest.X, desiredY, targetDest.Z)
                local orbitOffset = Vector3.new(offsetX, 0, offsetZ)
                
                -- Prevent noclipping into walls during orbit!
                local orbitRayParams = RaycastParams.new()
                orbitRayParams.FilterDescendantsInstances = {character, currentEnemy}
                orbitRayParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local orbitRay = Workspace:Raycast(centerOrbit, orbitOffset, orbitRayParams)
                if orbitRay then
                    targetSpot = orbitRay.Position - (orbitOffset.Unit * 1.5)
                else
                    targetSpot = centerOrbit + orbitOffset
                end
            else
                targetSpot = Vector3.new(targetDest.X, desiredY, targetDest.Z)
            end
        end
        
        local wallCheckCFrame = rootPart.CFrame + Vector3.new(0, 3, 0)
        
        if Model.State.evadingTimer > 0 and not isCloseToArrival then
            Model.State.evadingTimer = Model.State.evadingTimer - deltaTime
            local evadeWallCast = blockcastSolid(wallCheckCFrame, size, Model.State.evasionDir * 10, raycastParams)
            
            if evadeWallCast and evadeWallCast.Distance <= 3 then
                Model.State.evasionDir = Vector3.new(0, 1, 0)
            else
                moveDir = Model.State.evasionDir
            end
        elseif not isPatrolling and not isCloseToArrival then
            local wallCast = blockcastSolid(wallCheckCFrame, size, moveDir * 8, raycastParams)
            if wallCast and wallCast.Distance <= 5 then
                local evaded = false
                local baseLook = CFrame.lookAt(flatCurrent, flatCurrent + moveDir)
                
                for _, evasionDir in ipairs(EVASION_DIRECTIONS) do
                    local relativeVector = evasionDir
                    if evasionDir.X ~= 0 then
                        relativeVector = baseLook:VectorToWorldSpace(evasionDir)
                    end
                    
                    local evadeCast = blockcastSolid(wallCheckCFrame, size, relativeVector * 10, raycastParams)
                    if not evadeCast then
                        Model.State.evadingTimer = 0.5 
                        Model.State.evasionDir = relativeVector
                        moveDir = relativeVector
                        evaded = true
                        break
                    end
                end
                if not evaded then
                    Model.State.evadingTimer = 0.5
                    Model.State.evasionDir = Vector3.new(0, 1, 0)
                    moveDir = Vector3.new(0, 1, 0)
                end
            end
        end
        
        local actualTarget
        if Model.State.evadingTimer > 0 then
            actualTarget = rootPart.Position + (moveDir * 50)
            if moveDir.Y == 0 then
                -- Lock Y coordinate to maintain ground height during horizontal evasion!
                actualTarget = Vector3.new(actualTarget.X, desiredY, actualTarget.Z)
            end
        else
            actualTarget = targetSpot
        end
        
        local distToActual = (rootPart.Position - actualTarget).Magnitude
        
        -- Face the target smoothly and safely
        local lookPos = Vector3.new(actualTarget.X, actualTarget.Y, actualTarget.Z)
        if Model.State.evadingTimer <= 0 then
            lookPos = Vector3.new(targetDest.X, actualTarget.Y, targetDest.Z)
        end
        
        local finalCFrame
        if (lookPos - actualTarget).Magnitude < 0.1 then
            finalCFrame = CFrame.new(actualTarget, actualTarget + rootPart.CFrame.LookVector)
        else
            finalCFrame = CFrame.lookAt(actualTarget, lookPos)
        end
        
        if distToActual > 0.5 then
            local lerpAlpha = math.clamp((flySpeed * deltaTime) / distToActual, 0, 1)
            rootPart.CFrame = rootPart.CFrame:Lerp(finalCFrame, lerpAlpha)
        else
            rootPart.CFrame = finalCFrame
        end
        
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
        
        drawTarget(actualTarget)

        -- Drain stamina silently while moving
        drainStamina(character)
    end
end

function Model.EquipMelee()
    local character = LocalPlayer.Character
    if not character then return end
    
    local swordFolder = ReplicatedStorage:FindFirstChild("Modules")
        and ReplicatedStorage.Modules:FindFirstChild("SwordHandle")
        and ReplicatedStorage.Modules.SwordHandle:FindFirstChild("Swords")

    local function isSword(toolName)
        if swordFolder and swordFolder:FindFirstChild(toolName) then
            return true
        end
        return false
    end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if equippedTool then
        if isSword(equippedTool.Name) or string.lower(equippedTool.Name) == "melee" then
            return
        end
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if humanoid and backpack then
        local targetTool = nil
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and isSword(tool.Name) then
                targetTool = tool
                break
            end
        end
        if not targetTool then targetTool = backpack:FindFirstChild("Melee") end
        if targetTool then humanoid:EquipTool(targetTool) end
    end
end

function Model.GetEnemiesInRange()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return {} end
    local enemiesList = {}
    local allEnemies = getAllEnemies()
    
    for _, npc in pairs(allEnemies) do
        if isValidTarget(npc) then
            local attackRange = 15
            if (character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude <= attackRange then
                table.insert(enemiesList, npc)
            end
        end
    end
    return enemiesList
end

function Model.DoMeleeCombo()
    local combatRegister = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CombatRegister")
    if not combatRegister then return end
    
    Model.EquipMelee()
    local targets = Model.GetEnemiesInRange()
    if #targets == 0 then
        task.wait(0.5)
        return
    end
    local equippedToolName = "Melee"
    local character = LocalPlayer.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            local swordFolder = ReplicatedStorage:FindFirstChild("Modules")
                and ReplicatedStorage.Modules:FindFirstChild("SwordHandle")
                and ReplicatedStorage.Modules.SwordHandle:FindFirstChild("Swords")
            if swordFolder and swordFolder:FindFirstChild(tool.Name) then
                equippedToolName = tool.Name
            end
        end
    end

    print("[AutoFarm] Enemies in range! Starting Combo with " .. equippedToolName)
    for currentHit = 1, 4 do
        if not Model.State.isAutoFarming then break end
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then break end
        
        local myCFrame = character.HumanoidRootPart.CFrame
        local myCFrame = character.HumanoidRootPart.CFrame
        
        local punchAnim
        local combatType = "Melee"
        
        if equippedToolName ~= "Melee" then
            combatType = "Sword"
            local swordSlashes = ReplicatedStorage:FindFirstChild("Modules") 
                and ReplicatedStorage.Modules:FindFirstChild("SwordHandle") 
                and ReplicatedStorage.Modules.SwordHandle:FindFirstChild("Swords") 
                and ReplicatedStorage.Modules.SwordHandle.Swords:FindFirstChild(equippedToolName) 
                and ReplicatedStorage.Modules.SwordHandle.Swords[equippedToolName]:FindFirstChild("Slashes")
            
            if swordSlashes then
                punchAnim = swordSlashes:FindFirstChild(tostring(currentHit)) or swordSlashes:GetChildren()[1]
            end
        end
        
        if not punchAnim then
            local animName = "Punch" .. currentHit
            punchAnim = ReplicatedStorage:WaitForChild("CombatAnimations", 9e9):WaitForChild("Melee", 9e9):WaitForChild(animName, 9e9)
        end
        
        local swingArgs = {
            [1] = {
                [1] = "swingsfx",
                [2] = combatType,
                [3] = currentHit,
                [4] = "Ground",
                [5] = false,
                [6] = punchAnim,
                [7] = 2,
                [8] = 1.5
            }
        }
        task.spawn(function() pcall(function() combatRegister:InvokeServer(unpack(swingArgs)) end) end)
        
        task.wait(0.35) 
        
        if not Model.State.isAutoFarming then break end
        
        local currentTargets = Model.GetEnemiesInRange()
        local roots = {}
        for _, npc in pairs(currentTargets) do
            if npc:FindFirstChild("HumanoidRootPart") then table.insert(roots, npc.HumanoidRootPart) end
        end
        
        if #roots > 0 then
            local damageArgs = {
                [1] = {
                    [1] = "damage",
                    [2] = roots,
                    [3] = combatType,
                    [4] = {[1] = currentHit, [2] = "Ground", [3] = combatType},
                    [5] = true,
                    [6] = myCFrame,
                    ["aircombo"] = "Ground"
                }
            }
            task.spawn(function() pcall(function() combatRegister:InvokeServer(unpack(damageArgs)) end) end)
        end
        task.wait(0.2)
    end
    if Model.State.isAutoFarming then task.wait(0.1) end
end

-- ==========================================
-- AUTO KEY SYSTEM (EMBEDDED)
-- ==========================================
local function startAutoKeyLoop()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    
    getgenv().CurrentPhase = "1. Auto Key"
    
    local function findTargetAndPrompt()
        -- 0. ALWAYS check for super rare items first in Effects, regardless of phase
        local priorityItems = {"Musashi", "Rose Katana", "SP Reset"}
        local effects = Workspace:FindFirstChild("Effects")
        if effects then
            for _, itemName in ipairs(priorityItems) do
                for _, desc in ipairs(effects:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
                        local pName = string.lower(desc.Parent.Name)
                        local ppName = desc.Parent.Parent and string.lower(desc.Parent.Parent.Name) or ""
                        local targetName = string.lower(itemName)
                        
                        if string.find(pName, targetName) or string.find(ppName, targetName) then
                            return desc.Parent, desc, itemName
                        end
                    end
                end
            end
        end
    
        if getgenv().CurrentPhase == "1. Auto Key" then
            -- 1. Prioritize Keys (Look in Effects first)
            if effects then
                local keyModel = effects:FindFirstChild("Key")
                if keyModel then
                    local keyPart = keyModel:FindFirstChild("Key")
                    if keyPart then
                        local prompt = keyPart:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and prompt.Enabled then
                            return keyPart, prompt, "Key"
                        end
                    end
                end
            end
            
            -- 2. Fallback for Keys
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
                    if desc.Parent.Name == "Key" then
                        return desc.Parent, desc, "Key"
                    end
                end
            end
            
            print("[AutoKey] Key collected or not found. Moving to 2. Looting phase...")
            getgenv().CurrentPhase = "2. Looting phase"
        end
        
        if getgenv().CurrentPhase == "2. Looting phase" then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return nil, nil, nil end
            
            local myPos = hrp.Position
            
            local bestTargetPart = nil
            local bestPrompt = nil
            local bestName = nil
            local bestDist = math.huge
            local bestHasLOS = false
            
            -- Search for Chests or any other loot
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
                    local actText = string.lower(desc.ActionText)
                    local objText = string.lower(desc.ObjectText)
                    
                    -- Target any prompt that looks like a Chest
                    if string.find(actText, "chest") or string.find(objText, "chest") then
                        local targetPart = desc.Parent
                        local targetPos = targetPart:IsA("Model") and targetPart:GetPivot().Position or targetPart.Position
                        local dist = (myPos - targetPos).Magnitude
                        
                        local name = desc.ObjectText ~= "" and desc.ObjectText or desc.ActionText
                        if name == "" then name = "Chest" end
                        
                        -- Check Line of Sight (LOS) so we don't try phasing through solid walls
                        local hasLOS = true
                        local dir = (targetPos - myPos)
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.IgnoreWater = true
                        
                        local currentIgnore = {char}
                        
                        -- Ignore the entire target model if it belongs to one
                        local tModel = targetPart:FindFirstAncestorOfClass("Model")
                        if tModel then
                            table.insert(currentIgnore, tModel)
                        else
                            table.insert(currentIgnore, targetPart)
                        end
    
                        for i = 1, 10 do
                            params.FilterDescendantsInstances = currentIgnore
                            local result = Workspace:Raycast(myPos, dir, params)
                            if result then
                                if result.Instance.CanCollide then
                                    hasLOS = false
                                    break
                                else
                                    -- It's a non-collide part (like an effect or zone), ignore it and cast again
                                    table.insert(currentIgnore, result.Instance)
                                end
                            else
                                break
                            end
                        end
                        
                        -- Smart Scoring Logic
                        if hasLOS and not bestHasLOS then
                            -- First unobstructed chest found! It automatically beats any obstructed ones.
                            bestTargetPart = targetPart
                            bestPrompt = desc
                            bestName = name
                            bestDist = dist
                            bestHasLOS = true
                        elseif hasLOS == bestHasLOS then
                            -- Both have LOS, or both don't have LOS. Pick the closer one.
                            if dist < bestDist then
                                bestTargetPart = targetPart
                                bestPrompt = desc
                                bestName = name
                                bestDist = dist
                            end
                        end
                    end
                end
            end
            
            return bestTargetPart, bestPrompt, bestName
        end
        
        return nil, nil, nil
    end
    
    local function flyToAndInteract()
        local targetPart, prompt, targetType = findTargetAndPrompt()
        
        if not targetPart or not prompt then
            return
        end
        
        if prompt and prompt:IsA("ProximityPrompt") then
            print("[" .. getgenv().CurrentPhase .. "] " .. targetType .. " found! Flying to it...")
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local bv = hrp:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
                bv.Name = "AntiGravity"
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.Parent = hrp
                
                local targetCFrame = targetPart:IsA("Model") and targetPart:GetPivot() or targetPart.CFrame
                local targetPos = (targetCFrame * CFrame.new(0, 0, 1.5)).Position
                local flySpeed = 50
                
                -- Fly towards the target smoothly
                while getgenv().AutoKey and targetPart.Parent and hrp.Parent do
                    local dist = (hrp.Position - targetPos).Magnitude
                    if dist <= 1.5 then
                        break
                    end
                    
                    local deltaTime = task.wait()
                    local lerpAlpha = math.clamp((flySpeed * deltaTime) / dist, 0, 1)
                    
                    local lookAtCFrame = CFrame.lookAt(hrp.Position, targetPos)
                    hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos) * lookAtCFrame.Rotation, lerpAlpha)
                    hrp.Velocity = Vector3.new(0, 0, 0)
                    hrp.RotVelocity = Vector3.new(0, 0, 0)
                end
                
                -- Keep the BodyVelocity alive so we don't fall during the interaction!
                if bv then bv.Velocity = Vector3.new(0, 0, 0) end
                
                -- Double check if the target is still valid after arriving
                if targetPart.Parent and prompt.Parent then
                    -- Bypass ProximityPrompt restrictions locally
                    local oldLOS = prompt.RequiresLineOfSight
                    local oldDist = prompt.MaxActivationDistance
                    pcall(function()
                        prompt.RequiresLineOfSight = false
                        prompt.MaxActivationDistance = math.huge
                    end)
                    
                    -- Face the chest explicitly
                    hrp.CFrame = CFrame.lookAt(hrp.Position, targetCFrame.Position)
                    task.wait(0.15)
                    
                    pcall(function()
                        -- Trigger both methods just to be absolutely sure
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration + 0.15)
                        if fireproximityprompt then
                            pcall(fireproximityprompt, prompt)
                        end
                        prompt:InputHoldEnd()
                    end)
                    
                    pcall(function()
                        prompt.RequiresLineOfSight = oldLOS
                        prompt.MaxActivationDistance = oldDist
                    end)
                    
                    print("[" .. getgenv().CurrentPhase .. "] Successfully interacted with " .. targetType .. "!")
                    
                    -- Attempt to equip it if it's a priority item that went into our backpack
                    if targetType == "Musashi" or targetType == "Rose Katana" or targetType == "SP Reset" then
                        task.wait(0.5) -- Give it time to enter backpack
                        local backpack = LocalPlayer:FindFirstChild("Backpack")
                        if backpack then
                            for _, tool in ipairs(backpack:GetChildren()) do
                                if tool:IsA("Tool") then
                                    local tName = string.lower(tool.Name)
                                    if string.find(tName, "musashi") or string.find(tName, "rose") or string.find(tName, "sp reset") then
                                        tool.Parent = char
                                        print("[AutoKey] Auto-Equipped " .. tool.Name .. "!")
                                    end
                                end
                            end
                        end
                    end
                    
                    if getgenv().CurrentPhase == "1. Auto Key" and targetType == "Key" then
                        print("[AutoKey] Key collected! Switching to 2. Looting phase...")
                        getgenv().CurrentPhase = "2. Looting phase"
                    elseif targetType == "Chest" then
                        task.wait(0.5) -- Wait a bit before flying to the next chest
                    end
                end
                
                if bv then bv:Destroy() end
            end
        end
    end
    
    -- Toggles for auto loop
    local getgenv = getgenv or function() return _G end
    getgenv().AutoKey = true
    getgenv().CurrentPhase = "1. Auto Key"
    
    local function createStopButton()
        local coreGui = game:GetService("CoreGui")
        local oldGui = coreGui:FindFirstChild("AutoKeyStopGui")
        if oldGui then oldGui:Destroy() end
        
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local oldPgui = pGui:FindFirstChild("AutoKeyStopGui")
            if oldPgui then oldPgui:Destroy() end
        end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "AutoKeyStopGui"
        screenGui.ResetOnSpawn = false
        
        local success = pcall(function() screenGui.Parent = coreGui end)
        if not success and pGui then screenGui.Parent = pGui end
    
        local stopBtn = Instance.new("TextButton")
        stopBtn.Size = UDim2.new(0, 150, 0, 40)
        stopBtn.Position = UDim2.new(0.5, -75, 0, 20)
        stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        stopBtn.Text = "STOP LOOTING"
        stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.TextSize = 14
        stopBtn.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = stopBtn
        
        stopBtn.MouseButton1Click:Connect(function()
            getgenv().AutoKey = false
            print("[AutoKey] Stopped via UI button!")
            screenGui:Destroy()
            
            -- Reset character velocity just in case it was flying
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local bv = char.HumanoidRootPart:FindFirstChild("AntiGravity")
                if bv then bv:Destroy() end
                char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    end
    
    createStopButton()
    
    print("[AutoKey] Started: Phase 1 (Auto Key) -> Phase 2 (Looting)")
    
    task.spawn(function()
        while getgenv().AutoKey and task.wait(1) do
            pcall(flyToAndInteract)
        end
    end)
    
end

-- ==========================================
-- VIEW
-- ==========================================
local View = {}

function View.Build(onToggleCallback)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFarmGui"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
    if not success then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 180, 0, 50)
    toggleBtn.Position = UDim2.new(0.5, -90, 0.1, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85) -- Red Color!
    toggleBtn.Text = "MUSASHI FARM: OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.Parent = screenGui

    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
    
    local speedFrame = Instance.new("Frame")
    speedFrame.Size = UDim2.new(1, 0, 0, 30)
    speedFrame.Position = UDim2.new(0, 0, 1, 5)
    speedFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    speedFrame.Parent = toggleBtn
    Instance.new("UICorner", speedFrame).CornerRadius = UDim.new(0, 5)
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.6, 0, 1, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "Speed:"
    speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 12
    speedLabel.Parent = speedFrame
    
    local speedInput = Instance.new("TextBox")
    speedInput.Size = UDim2.new(0.4, -5, 0.8, 0)
    speedInput.Position = UDim2.new(0.6, 0, 0.1, 0)
    speedInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    speedInput.Text = tostring(flySpeed)
    speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedInput.Font = Enum.Font.GothamBold
    speedInput.TextSize = 12
    speedInput.Parent = speedFrame
    Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 4)
    
    speedInput.FocusLost:Connect(function()
        local num = tonumber(speedInput.Text)
        if num then
            flySpeed = math.clamp(num, 5, 200)
            speedInput.Text = tostring(flySpeed)
        else
            speedInput.Text = tostring(flySpeed)
        end
    end)
    
    local posBtn = Instance.new("TextButton")
    posBtn.Size = UDim2.new(1, 0, 0, 30)
    posBtn.Position = UDim2.new(0, 0, 1, 40)
    posBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    posBtn.Text = "Pos: 0, 0, 0"
    posBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    posBtn.Font = Enum.Font.GothamBold
    posBtn.TextSize = 10
    posBtn.Parent = toggleBtn
    Instance.new("UICorner", posBtn).CornerRadius = UDim.new(0, 5)
    
    if getgenv().posConn then getgenv().posConn:Disconnect() end
    getgenv().posConn = RunService.RenderStepped:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local p = LocalPlayer.Character.HumanoidRootPart.Position
            posBtn.Text = string.format("Copy Pos: %.0f, %.0f, %.0f", p.X, p.Y, p.Z)
        end
    end)
    
    posBtn.MouseButton1Click:Connect(function()
        if setclipboard and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local p = LocalPlayer.Character.HumanoidRootPart.Position
            local str = string.format("Vector3.new(%.0f, %.0f, %.0f)", p.X, p.Y, p.Z)
            setclipboard(str)
            
            local oldText = posBtn.Text
            posBtn.Text = "Copied!"
            posBtn.TextColor3 = Color3.fromRGB(85, 255, 85)
            task.delay(1, function()
                posBtn.Text = oldText
                posBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            end)
        elseif not setclipboard then
            posBtn.Text = "Executor missing setclipboard!"
            posBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
            task.delay(1.5, function()
                posBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            end)
        end
    end)
    
    local autoKeyBtn = Instance.new("TextButton")
    autoKeyBtn.Size = UDim2.new(1, 0, 0, 30)
    autoKeyBtn.Position = UDim2.new(0, 0, 1, 75)
    
    -- Check if auto key is currently running to set initial color/text
    local isAutoKeyRunning = getgenv().AutoKey or false
    autoKeyBtn.BackgroundColor3 = isAutoKeyRunning and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(40, 40, 40)
    autoKeyBtn.Text = isAutoKeyRunning and "AUTO KEY: ON" or "AUTO KEY: OFF"
    autoKeyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    autoKeyBtn.Font = Enum.Font.GothamBold
    autoKeyBtn.TextSize = 10
    autoKeyBtn.Parent = toggleBtn
    Instance.new("UICorner", autoKeyBtn).CornerRadius = UDim.new(0, 5)
    
    autoKeyBtn.MouseButton1Click:Connect(function()
        if getgenv().AutoKey then
            -- Stop it
            getgenv().AutoKey = false
            autoKeyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            autoKeyBtn.Text = "AUTO KEY: OFF"
        else
            -- Start it! (Need to execute the external script logic)
            -- We assume the auto_key logic can be loaded if we simply read the file or 
            -- rely on the user having executed it once to put it in memory.
            -- However, to make it self-contained, we can just flip the global flag
            -- and let the external script handle it, or load it via loadstring if needed.
            getgenv().AutoKey = true
            getgenv().CurrentPhase = "1. Auto Key"
            autoKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            autoKeyBtn.Text = "AUTO KEY: ON"
            
            task.spawn(function()
                print("[AutoFarm UI] Auto Key Enabled!")
                -- Run embedded auto key logic
                task.spawn(startAutoKeyLoop)
            end)
        end
    end)


    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -12, 0, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = toggleBtn
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

    closeBtn.MouseButton1Click:Connect(function()
        if getgenv().StopAutofarm then
            getgenv().StopAutofarm()
        end
    end)

    local dragging = false
    local dragInput, dragStart, startPos
    local dragDistance = 0
    local isFarming = false
    
    local function setFarmingState(state)
        if isFarming == state then return end
        isFarming = state
        
        toggleBtn.Text = isFarming and "MUSASHI FARM: ON" or "MUSASHI FARM: OFF"
        toggleBtn.BackgroundColor3 = isFarming and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(255, 85, 85)
        
        onToggleCallback(isFarming)
    end

    getgenv().ToggleAutofarm = function()
        allowAutoStart = false
        setFarmingState(not isFarming)
    end
    
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position
            dragDistance = 0
            
            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                    changedConn:Disconnect()
                    
                    -- If the mouse barely moved, treat it as a CLICK!
                    if dragDistance < 10 then
                        allowAutoStart = false 
                        setFarmingState(not isFarming)
                    end
                end
            end)
        end
    end)

    toggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            dragDistance = delta.Magnitude
            toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)



    task.spawn(function()
        task.wait(5)
        if allowAutoStart and not isFarming then
            allowAutoStart = false
            setFarmingState(true)
        end
    end)
end

-- ==========================================
-- CONTROLLER
-- ==========================================

View.Build(function(isFarming)
    Model.State.isAutoFarming = isFarming

    if not isFarming then
        Model.ResetPhysics()
    else
        -- Smart Waypoint Initialization: Find the best macroIndex based on current location
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and MACRO_WAYPOINTS then
            if currentStage == 1 then
                -- Floor 1: If we are far into the maze, target F1 End. If at spawn, target F1 Start.
                local distToStart = (root.Position - MACRO_WAYPOINTS[1].Pos).Magnitude
                if distToStart < 150 then
                    Model.State.macroIndex = 1
                else
                    Model.State.macroIndex = 2
                end
            elseif currentStage == 2 then
                print("[AutoFarm] 🚀 Floor 2 Detected! Initializing Lever & Boss Room sequence...")
                -- Floor 2: Find the closest waypoint to resume from
                local closestIdx = 1
                local closestDist = math.huge
                for i = 1, #MACRO_WAYPOINTS do
                    local dist = (root.Position - MACRO_WAYPOINTS[i].Pos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestIdx = i
                    end
                    
                    -- THE FIX: Do not scan past mandatory actions to prevent wall-skipping!
                    if MACRO_WAYPOINTS[i].Action == "PULL_LEVER" then
                        break
                    end
                end
                
                if closestDist < 30 and closestIdx < #MACRO_WAYPOINTS then
                    Model.State.macroIndex = closestIdx + 1
                else
                    Model.State.macroIndex = closestIdx
                end
            else
                Model.State.macroIndex = 1
            end
        end

        task.spawn(function()
            while Model.State.isAutoFarming do
                Model.DoMeleeCombo()
            end
        end)
        
        -- Melee skills are currently disabled/unimplemented
    end
end)

local steppedConn = RunService.Stepped:Connect(function()
    if Model.State.isAutoFarming and not Model.State.isWaitingAtSafeSpot then
        Model.ApplyNoclip()
    end
end)

local heartbeatConn = RunService.Heartbeat:Connect(function(deltaTime)
    if not Model.State.isAutoFarming then return end
    Model.UpdateTracking(deltaTime)
end)

getgenv().hotkeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F4 then
        if getgenv().ToggleAutofarm then
            print("[AutoFarm Debug] Toggling via F4")
            getgenv().ToggleAutofarm()
        end
    end
end)

getgenv().StopAutofarm = function()
    Model.State.isAutoFarming = false
    Model.ResetPhysics()
    
    if steppedConn then steppedConn:Disconnect() end
    if heartbeatConn then heartbeatConn:Disconnect() end
    if getgenv().hotkeyConn then getgenv().hotkeyConn:Disconnect() end
    if getgenv().posConn then getgenv().posConn:Disconnect() end
    if visualizerFolder then visualizerFolder:Destroy() end
    
    local coreGui = game:GetService("CoreGui"):FindFirstChild("AutoFarmGui")
    if coreGui then coreGui:Destroy() end
    
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild("AutoFarmGui") then 
        pGui.AutoFarmGui:Destroy() 
    end
    
    print("[Melee Autofarm] Autofarm forcefully stopped and UI destroyed.")
end





