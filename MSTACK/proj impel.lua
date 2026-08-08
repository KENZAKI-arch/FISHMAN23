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
local DashTypes = require(ReplicatedStorage.Util.Movement.DashTypes)

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

local MAZE_TARGET_POSITION = Vector3.new(2605, 2075, -15410)


local EVASION_DIRECTIONS = {
    Vector3.new(1, 0, 0),   -- Slide Right
    Vector3.new(0, 1, 0)    -- Climb Up
}

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
    roundUpTimer = 0
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

    if Model.State.botMode == "NAVIGATE_MAZE" then
        currentEnemy = nil
        isPatrolling = true
        
        -- Check if an enemy is blocking our path (within 5 studs)
        local bestTarget = findBestTarget(allEnemies)
        local targetHrp = bestTarget and bestTarget:FindFirstChild("HumanoidRootPart")
        if targetHrp and (rootPart.Position - targetHrp.Position).Magnitude <= 5 then
            print("[AutoFarm] Enemy blocking path! Punishing...")
            Model.State.botMode = "MAZE_COMBAT"
            currentEnemy = bestTarget
            targetDest = targetHrp.Position
            Model.State.mazePath = {} -- Clear path so it recalculates after killing
        else
            -- No enemies in the way, pathfind through the maze!
            if #Model.State.mazePath == 0 or Model.State.mazeIndex > #Model.State.mazePath then
                print("[AutoFarm] Calculating Maze Path...")
                local path = PathfindingService:CreatePath({
                    AgentRadius = 3,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    WaypointSpacing = 4,
                    Costs = { Water = 20 }
                })
                local success, err = pcall(function()
                    path:ComputeAsync(rootPart.Position, MAZE_TARGET_POSITION)
                end)
                if success and path.Status == Enum.PathStatus.Success then
                    Model.State.mazePath = path:GetWaypoints()
                    Model.State.mazeIndex = 2 -- Skip first waypoint (current pos)
                else
                    print("[AutoFarm] Pathfinding failed!")
                end
            end
            
            if Model.State.mazePath and Model.State.mazeIndex <= #Model.State.mazePath then
            targetDest = Model.State.mazePath[Model.State.mazeIndex].Position
        else
            print("[AutoFarm] Reached the end of the maze! Securing the room...")
            Model.State.botMode = "ROOM_ROUND_UP"
            Model.State.roundUpTimer = 5
            targetDest = rootPart.Position
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
            -- Stay in the center to fight them all!
            local centerPos = Vector3.new(0, 0, 0)
            for _, hrp in ipairs(validEnemies) do
                centerPos = centerPos + hrp.Position
            end
            centerPos = centerPos / #validEnemies
            targetDest = centerPos
            currentEnemy = validEnemies[1].Parent
            
            -- Re-check clump, if they scattered too far, round up again
            local allClumped = true
            for _, hrp in ipairs(validEnemies) do
                if (centerPos - hrp.Position).Magnitude > 25 then
                    allClumped = false
                    break
                end
            end
            if not allClumped then
                print("[AutoFarm] Enemies scattered! Re-rounding up...")
                Model.State.botMode = "ROOM_ROUND_UP"
                Model.State.roundUpTimer = 5
            end
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
            -- Stuck Detection: If we haven't moved closer by at least 0.1 studs
            if Model.State.lastMazeDist - arrivalDistance < 0.1 then
                Model.State.stuckTimer = Model.State.stuckTimer + deltaTime
            else
                Model.State.stuckTimer = 0
                Model.State.lastMazeDist = arrivalDistance
            end
            
            -- If stuck for more than 0.5 seconds, Noclip & Dash!
            if Model.State.stuckTimer > 0.5 then
                print("[AutoFarm] Stuck in maze! Noclipping & Dashing...")
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                task.spawn(DashTypes.dash, DashTypes, false)
                Model.State.stuckTimer = 0
                task.wait(0.2)
            end
            
            if arrivalDistance <= 0.5 then
                Model.State.mazeIndex = Model.State.mazeIndex + 1
                if Model.State.mazeIndex > #Model.State.mazePath then
                    print("[AutoFarm] Reached Maze Destination!")
                    Model.State.mazePath = {} -- Re-compute or just hover
                else
                    targetDest = Model.State.mazePath[Model.State.mazeIndex].Position
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
            end
            targetSpot = Vector3.new(targetDest.X, desiredY, targetDest.Z)
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
        task.spawn(function()
            while Model.State.isAutoFarming do
                Model.DoMeleeCombo()
            end
        end)
        
        -- Melee skills are currently disabled/unimplemented, but stats level up below

        task.spawn(function()
            local statsEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("stats", 9e9)
            local args = { "Strength", nil, 1 }
            
            while Model.State.isAutoFarming do
                pcall(function()
                    statsEvent:FireServer(unpack(args))
                end)
                task.wait(3) 
            end
        end)
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

getgenv().StopAutofarm = function()
    Model.State.isAutoFarming = false
    Model.ResetPhysics()
    
    if steppedConn then steppedConn:Disconnect() end
    if heartbeatConn then heartbeatConn:Disconnect() end
    
    local coreGui = game:GetService("CoreGui"):FindFirstChild("AutoFarmGui")
    if coreGui then coreGui:Destroy() end
    
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild("AutoFarmGui") then 
        pGui.AutoFarmGui:Destroy() 
    end
    
    print("[Melee Autofarm] Autofarm forcefully stopped and UI destroyed.")
end
