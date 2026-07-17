-- ============================================================================
-- GOLDEN STAFF AUTOFARM SCRIPT (SEQUENCE TARGETING)
-- Contains Model, View, and Controller logic in a single file
-- ============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Clean up any previously running instance of the script
if getgenv().StopAutofarm then
    pcall(function() getgenv().StopAutofarm() end)
    task.wait(0.2)
end
-- ==========================================
-- CONFIGURATION
-- ==========================================
-- The script will search for these targets in order.
-- Priority 1 is checked first. If not found, it moves to Priority 2.
local TARGET_SEQUENCE = {
    "Scientist",
    "Fishman Karate User",
    "FactoryPool"
}

local Y_LEVEL_DETECTION_RADIUS = 15 -- Max height difference allowed before breaking the path


local WAYPOINTS = {
    Vector3.new(8786.2, 72.4, 11626.6),
    Vector3.new(8785.9, 72.5, 11641.9),
    Vector3.new(8785.6, 72.6, 11657.2),
    Vector3.new(8785.4, 72.7, 11672.5),
    Vector3.new(8785.1, 72.9, 11688.1),
    Vector3.new(8784.6, 73.0, 11704.0),
    Vector3.new(8771.0, 69.1, 11697.3),
    Vector3.new(8760.4, 68.1, 11686.4),
    Vector3.new(8750.0, 68.1, 11675.1),
    Vector3.new(8739.6, 68.2, 11663.9),
    Vector3.new(8728.5, 68.5, 11653.5),
    Vector3.new(8716.4, 69.4, 11644.2),
    Vector3.new(8704.1, 70.4, 11635.0),
    Vector3.new(8689.0, 72.4, 11638.0),
    Vector3.new(8676.2, 78.1, 11644.1),
    Vector3.new(8663.4, 83.8, 11650.2),
    Vector3.new(8650.6, 89.4, 11656.4),
    Vector3.new(8638.8, 95.8, 11663.7),
    Vector3.new(8629.0, 104.7, 11671.1),
    Vector3.new(8618.9, 112.7, 11679.3),
    Vector3.new(8608.4, 120.3, 11687.6),
    Vector3.new(8597.8, 127.0, 11696.4),
    Vector3.new(8587.3, 133.5, 11705.3),
    Vector3.new(8577.0, 139.9, 11714.7),
    Vector3.new(8567.6, 145.7, 11725.2),
    Vector3.new(8558.8, 151.6, 11736.3),
    Vector3.new(8550.6, 157.6, 11747.8),
    Vector3.new(8543.4, 165.0, 11758.9),
    Vector3.new(8536.7, 173.6, 11769.6),
    Vector3.new(8530.6, 183.0, 11780.0),
    Vector3.new(8524.4, 192.1, 11790.7),
    Vector3.new(8518.3, 199.9, 11802.3),
    Vector3.new(8512.3, 206.3, 11814.9),
    Vector3.new(8506.8, 209.9, 11828.7),
    Vector3.new(8501.9, 211.3, 11843.2),
    Vector3.new(8499.2, 211.5, 11858.6),
    Vector3.new(8509.0, 211.2, 11870.8),
    Vector3.new(8524.0, 211.0, 11873.8),
    Vector3.new(8539.0, 210.9, 11876.9),
    Vector3.new(8554.0, 211.0, 11880.1),
    Vector3.new(8568.9, 211.2, 11883.4),
    Vector3.new(8583.8, 211.4, 11886.7),
    Vector3.new(8598.7, 211.6, 11890.1),
    Vector3.new(8613.6, 211.8, 11893.4),
    Vector3.new(8628.5, 212.0, 11896.7),
    Vector3.new(8643.4, 212.2, 11900.0),
    Vector3.new(8658.4, 212.4, 11903.4),
    Vector3.new(8673.3, 212.6, 11906.7),
    Vector3.new(8688.2, 212.8, 11910.0),
    Vector3.new(8703.1, 213.1, 11913.4),
    Vector3.new(8687.9, 212.8, 11910.0),
    Vector3.new(8672.9, 212.6, 11906.6),
    Vector3.new(8658.0, 212.4, 11903.3),
    Vector3.new(8643.1, 212.2, 11900.0),
    Vector3.new(8628.2, 212.0, 11896.6),
    Vector3.new(8613.3, 211.8, 11893.3),
    Vector3.new(8598.4, 211.6, 11890.0),
    Vector3.new(8583.5, 211.4, 11886.7),
    Vector3.new(8568.6, 211.2, 11883.3),
    Vector3.new(8553.7, 211.0, 11880.0),
    Vector3.new(8538.8, 210.7, 11876.7),
    Vector3.new(8523.9, 210.5, 11873.3),
    Vector3.new(8509.0, 210.3, 11870.0),
    Vector3.new(8495.5, 210.2, 11877.6),
    Vector3.new(8492.0, 210.2, 11893.4),
    Vector3.new(8486.0, 210.2, 11907.8),
    Vector3.new(8478.4, 210.2, 11920.7),
    Vector3.new(8475.6, 214.3, 11935.3),
    Vector3.new(8478.4, 221.6, 11948.4),
    Vector3.new(8481.2, 229.0, 11961.5),
    Vector3.new(8484.5, 236.4, 11974.5),
    Vector3.new(8488.8, 244.0, 11987.0),
    Vector3.new(8493.1, 251.6, 11999.5),
    Vector3.new(8497.7, 259.6, 12011.8),
    Vector3.new(8502.4, 267.6, 12023.9),
    Vector3.new(8508.3, 275.0, 12036.0),
    Vector3.new(8515.9, 281.4, 12047.5),
    Vector3.new(8527.0, 284.2, 12057.8),
    Vector3.new(8537.7, 285.1, 12068.6),
    Vector3.new(8546.8, 288.0, 12080.5),
    Vector3.new(8555.8, 291.2, 12092.4),
    Vector3.new(8571.0, 292.8, 12095.8),
    Vector3.new(8585.9, 293.5, 12092.8),
    Vector3.new(8599.5, 294.0, 12085.6),
    Vector3.new(8612.2, 294.5, 12077.2),
    Vector3.new(8624.7, 295.0, 12068.5),
    Vector3.new(8637.3, 295.5, 12059.9),
    Vector3.new(8651.1, 295.5, 12053.2),
    Vector3.new(8665.0, 295.3, 12046.9),
    Vector3.new(8678.9, 295.1, 12040.6),
    Vector3.new(8692.8, 294.5, 12034.2),
    Vector3.new(8706.7, 293.6, 12027.8),
    Vector3.new(8720.6, 292.7, 12021.5),
    Vector3.new(8734.5, 291.8, 12015.2),
    Vector3.new(8730.9, 297.4, 12001.5),
    Vector3.new(8726.5, 303.2, 11988.0),
    Vector3.new(8722.1, 308.9, 11974.5),
    Vector3.new(8717.7, 314.6, 11961.0),
    Vector3.new(8713.3, 320.3, 11947.5),
    Vector3.new(8708.9, 326.0, 11934.0),
    Vector3.new(8705.0, 332.9, 11921.1),
    Vector3.new(8701.6, 342.1, 11909.4),
    Vector3.new(8698.5, 353.2, 11899.5),
    Vector3.new(8695.5, 364.8, 11890.0),
    Vector3.new(8692.5, 376.5, 11880.5),
    Vector3.new(8689.3, 388.0, 11871.0),
    Vector3.new(8685.0, 399.8, 11859.7),
    Vector3.new(8680.5, 409.7, 11848.4),
    Vector3.new(8694.1, 370.2, 11885.6),
    Vector3.new(8688.5, 375.5, 11872.1),
    Vector3.new(8683.2, 379.8, 11858.5),
    Vector3.new(8680.4, 390.7, 11848.5),
    Vector3.new(8677.8, 402.4, 11838.9),
    Vector3.new(8674.6, 413.4, 11828.8),
    Vector3.new(8670.6, 423.3, 11817.9),
    Vector3.new(8664.9, 429.9, 11805.2)
}



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
    currentWaypointIndex = 1,
    patrolDirection = 1,
    routingToFloor = nil,
    routePath = {},
    routeIndex = 0,
    routeDirection = 1,
    patrolWaitTimer = 0,
    lastFactoryCheckTime = 0,
    factoryCachedStatus = true,
    botMode = "PATROL" -- Can be "PATROL" or "COMBAT"
}

local flySpeed = 50
local currentEnemy = nil
local targetSwitchTimer = 2
local switchInterval = 2
local ENEMY_DETECTION_RADIUS = math.huge -- Uncapped so we can fly out to fallen enemies and rubberband back

-- Helper to find valid enemies across multiple folders
local function getAllEnemies()
    local allEnemies = {}
    local foldersToSearch = {}
    
    if Workspace:FindFirstChild("NPCs") then table.insert(foldersToSearch, Workspace.NPCs) end
    if Workspace:FindFirstChild("Env") then table.insert(foldersToSearch, Workspace.Env) end
    
    for _, folder in pairs(foldersToSearch) do
        for _, npc in pairs(folder:GetChildren()) do
            allEnemies[#allEnemies + 1] = npc
        end
    end
    return allEnemies
end

local function isFactoryOpen()
    local currentTime = os.clock()
    if currentTime - Model.State.lastFactoryCheckTime < 5 then
        return Model.State.factoryCachedStatus
    end
    
    Model.State.lastFactoryCheckTime = currentTime
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then 
        Model.State.factoryCachedStatus = true
        return true
    end
    
    local isOpen = true
    
    -- 1. Check the BillboardGui on the Factory FrontDoor
    if not Model.State.cachedFactorySign or not Model.State.cachedFactorySign.Parent then
        local islands = Workspace:FindFirstChild("Islands")
        local roseKingdom = islands and islands:FindFirstChild("Rose Kingdom")
        local factory = roseKingdom and roseKingdom:FindFirstChild("Factory")
        
        local exactPath = factory
            and factory:FindFirstChild("FrontDoor") 
            and factory.FrontDoor:FindFirstChild("Top") 
            and factory.FrontDoor.Top:FindFirstChild("BillboardGui")
            
        if exactPath then
            Model.State.cachedFactorySign = exactPath:FindFirstChildOfClass("TextLabel")
        end
    end
        
    if Model.State.cachedFactorySign then
        if string.find(string.upper(Model.State.cachedFactorySign.Text), "FACTORY CLOSED") then
            isOpen = false
        end
    end

    -- 2. Fallback: Check PlayerGui as well, just in case
    if isOpen then
        local function searchGui(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("TextBox") or child:IsA("TextButton") then
                    if string.find(string.upper(child.Text), "FACTORY CLOSED") then
                        isOpen = false
                        return false
                    end
                end
                if searchGui(child) == false then return false end
            end
            return true
        end
        searchGui(pGui)
    end
    
    Model.State.factoryCachedStatus = isOpen
    return isOpen
end

local function isValidTarget(npc, targetName)
    if npc.Name ~= targetName then return false end
    
    if targetName == "FactoryPool" and not isFactoryOpen() then return false end
    
    if not npc:FindFirstChild("HumanoidRootPart") then return false end
    
    -- Check normal Humanoid
    local humanoid = npc:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then return true end
    
    -- Check FactoryPool barrelHP
    local barrelHP = npc:FindFirstChild("barrelHP")
    if barrelHP and barrelHP.Value > 0 then return true end
    
    return false
end

local function getFloorLevel(yPos)
    -- By separating the Ramps (1.5 and 2.5) from the flat floors,
    -- the bot is FORCED to stay on the path until it physically reaches the flat floor.
    if yPos >= 286 then
        return 3 -- 3rd Floor (Factory)
    elseif yPos > 215 then
        return 2.5 -- Ramp from 2nd to 3rd Floor
    elseif yPos >= 204 then
        return 2 -- 2nd Floor (Bridge)
    elseif yPos > 75 then
        return 1.5 -- Ramp from Ground to 2nd Floor
    else
        return 1 -- Ground Floor
    end
end

-- Find the highest priority target, prioritizing the closest one
local function findBestTarget(allEnemies)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local currentWP = WAYPOINTS[Model.State.currentWaypointIndex]
    
    if not currentWP then return nil end

    for _, targetName in ipairs(TARGET_SEQUENCE) do
        local closestSameFloor = nil
        local closestSameDist = math.huge
        
        local closestOtherFloor = nil
        local closestOtherDist = math.huge
        
        for _, npc in pairs(allEnemies) do
            if isValidTarget(npc, targetName) then
                if rootPart and npc:FindFirstChild("HumanoidRootPart") then
                    -- Base the expected floor on the WAYPOINT, ensuring the bot stays true to the path
                    local actualMyFloor = getFloorLevel(currentWP.Y)
                    local enemyFloor = getFloorLevel(npc.HumanoidRootPart.Position.Y)
                    
                    local flatWP = Vector3.new(currentWP.X, 0, currentWP.Z)
                    local flatEnemy = Vector3.new(npc.HumanoidRootPart.Position.X, 0, npc.HumanoidRootPart.Position.Z)
                    -- Calculate distance from the WAYPOINT, not the bot, so it stays focused on its path
                    local dist = (flatWP - flatEnemy).Magnitude
                    
                    if actualMyFloor == enemyFloor then
                        -- Same floor limit: keeps bot from flying across map and hitting walls
                        if dist <= ENEMY_DETECTION_RADIUS then
                            -- Prevent the bot from flying straight UP/DOWN through ceilings!
                            -- STRICT Y-level limit: Must be on the exact same elevation before breaking the path.
                            local isTooDifferentInHeight = (math.abs(npc.HumanoidRootPart.Position.Y - rootPart.Position.Y) > Y_LEVEL_DETECTION_RADIUS)
                            
                            if not isTooDifferentInHeight and dist < closestSameDist then
                                closestSameDist = dist
                                closestSameFloor = npc
                            elseif isTooDifferentInHeight and dist < closestOtherDist then
                                -- It's on the same floor level, but too high/low to fly safely. Use the macro path!
                                closestOtherDist = dist
                                closestOtherFloor = npc
                            end
                        end
                    else
                        -- Different floor: We use the safe macro path (stairs) so distance limit isn't needed!
                        -- This ensures the bot detects bridge enemies after killing a fallen enemy and walks back UP.
                        if dist < closestOtherDist then
                            closestOtherDist = dist
                            closestOtherFloor = npc
                        end
                    end
                else
                    return npc
                end
            end
        end
        
        if closestSameFloor then return closestSameFloor end
        if closestOtherFloor then return closestOtherFloor end
    end
    return nil
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
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
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
        if currentEnemy.Parent ~= nil then
            local hum = currentEnemy:FindFirstChild("Humanoid")
            local barrel = currentEnemy:FindFirstChild("barrelHP")
            if hum and hum.Health > 0 then isAlive = true end
            if barrel and barrel.Value > 0 then isAlive = true end
        end
        if not isAlive then
            currentEnemy = nil
            targetSwitchTimer = switchInterval
        end
    end

    local isPatrolling = false
    local targetDest = nil

    if Model.State.botMode == "PATROL" then
        currentEnemy = nil
        isPatrolling = true
        
        local currentWP = WAYPOINTS[Model.State.currentWaypointIndex]
        -- Rubberband effect: Only recalculate if we fell down/off the map (drastic Y change).
        -- Horizontal distance is explicitly ignored so the bot smoothly snaps back to its path after combat!
        if not currentWP or math.abs(rootPart.Position.Y - currentWP.Y) > 50 then
            -- Snap to the waypoint that best matches our current altitude to prevent flying through ceilings!
            local closestIdx = 1
            local closestScore = math.huge
            for i, wp in ipairs(WAYPOINTS) do
                local yDiff = math.abs(rootPart.Position.Y - wp.Y)
                local horizontalDiff = (Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z) - Vector3.new(wp.X, 0, wp.Z)).Magnitude
                -- Weight Y difference much higher (10x) to ensure we snap to the correct elevation on the ramp
                local score = (yDiff * 10) + horizontalDiff 
                
                if score < closestScore then
                    closestScore = score
                    closestIdx = i
                end
            end
            Model.State.currentWaypointIndex = closestIdx
            currentWP = WAYPOINTS[Model.State.currentWaypointIndex]
        end

        local flatTarget = Vector3.new(currentWP.X, 0, currentWP.Z)
        local flatCurrent = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
        local horizontalDistance = (flatTarget - flatCurrent).Magnitude

        if horizontalDistance < 15 then
            -- Reached checkpoint! Stop and look around.
            local bestTarget = findBestTarget(allEnemies)
            if bestTarget then
                local myFloor = getFloorLevel(currentWP.Y)
                local hrp = bestTarget:FindFirstChild("HumanoidRootPart")
                local enemyFloor = myFloor
                
                if hrp then
                    enemyFloor = getFloorLevel(hrp.Position.Y)
                elseif bestTarget.Name == "FactoryPool" then
                    enemyFloor = 3
                end
                
                local targetPos = hrp and hrp.Position or (bestTarget.PrimaryPart and bestTarget.PrimaryPart.Position or Vector3.new(8675, 289, 11824))
                local flatTarget = Vector3.new(targetPos.X, 0, targetPos.Z)
                
                -- Find the optimal waypoint to attack from (closest to enemy on the same floor)
                local bestWpIndex = 1
                local bestWpDist = math.huge
                for i, wp in ipairs(WAYPOINTS) do
                    if getFloorLevel(wp.Y) == enemyFloor then
                        -- Score based heavily on matching the Y-altitude, then horizontal distance
                        local yDiff = math.abs(wp.Y - targetPos.Y)
                        local flatWP = Vector3.new(wp.X, 0, wp.Z)
                        local horizontalDiff = (flatWP - flatTarget).Magnitude
                        
                        local score = (yDiff * 2) + horizontalDiff
                        if score < bestWpDist then
                            bestWpDist = score
                            bestWpIndex = i
                        end
                    end
                end
                
                if myFloor == enemyFloor and Model.State.currentWaypointIndex == bestWpIndex then
                    -- We have reached the optimal launching waypoint! WIPE THEM OUT!
                    Model.State.botMode = "COMBAT"
                    currentEnemy = bestTarget
                    print("[AutoFarm] Optimal waypoint reached! Attacking " .. currentEnemy.Name)
                    isPatrolling = false
                    targetDest = targetPos
                else
                    -- We need to keep patrolling strictly along the waypoints to reach the optimal launch point!
                    Model.State.botMode = "PATROL"
                    Model.State.patrolDirection = (bestWpIndex > Model.State.currentWaypointIndex) and 1 or -1
                    targetDest = currentWP 
                end
            else
                -- No enemies anywhere, just continue patrol
                targetDest = currentWP
            end
        else
            -- Still moving to checkpoint
            targetDest = currentWP
        end
        
    elseif Model.State.botMode == "COMBAT" then
        if not currentEnemy then
            -- Enemy dead or lost! Go back to PATROL to find next checkpoint/enemy
            Model.State.botMode = "PATROL"
            isPatrolling = true
            targetDest = WAYPOINTS[Model.State.currentWaypointIndex] or rootPart.Position
        else
            local myFloor = getFloorLevel(rootPart.Position.Y)
            local hrp = currentEnemy:FindFirstChild("HumanoidRootPart")
            local enemyFloor = myFloor
            if hrp then
                enemyFloor = getFloorLevel(hrp.Position.Y)
            elseif currentEnemy.Name == "FactoryPool" then
                enemyFloor = 3
            end
            
            if myFloor ~= enemyFloor then
                -- Enemy fell off! Go back to PATROL to walk the stairs to them.
                Model.State.botMode = "PATROL"
                currentEnemy = nil
                isPatrolling = true
                Model.State.patrolDirection = (enemyFloor > myFloor) and 1 or -1
                targetDest = WAYPOINTS[Model.State.currentWaypointIndex] or rootPart.Position
            else
                -- Target is on our floor! Fly straight to them and fight!
                isPatrolling = false
                if hrp then
                    targetDest = hrp.Position
                else
                    targetDest = currentEnemy.PrimaryPart and currentEnemy.PrimaryPart.Position or Vector3.new(8675, 289, 11824)
                end
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
        
        if isPatrolling and horizontalDistance < 15 then
            if Model.State.currentWaypointIndex == 2 and Model.State.patrolWaitTimer < 3 then
                Model.State.patrolWaitTimer = Model.State.patrolWaitTimer + deltaTime
            else
                Model.State.patrolWaitTimer = 0
                Model.State.currentWaypointIndex = Model.State.currentWaypointIndex + Model.State.patrolDirection
                
                -- Ping-pong logic: if reached the top, go back down point-by-point
                if Model.State.currentWaypointIndex > #WAYPOINTS then
                    Model.State.currentWaypointIndex = #WAYPOINTS - 1
                    Model.State.patrolDirection = -1
                elseif Model.State.currentWaypointIndex < 1 then
                    Model.State.currentWaypointIndex = 2
                    Model.State.patrolDirection = 1
                end
                
                targetDest = WAYPOINTS[Model.State.currentWaypointIndex]
                flatTarget = Vector3.new(targetDest.X, 0, targetDest.Z)
                horizontalDistance = (flatTarget - flatCurrent).Magnitude
                arrivalDistance = (targetDest - rootPart.Position).Magnitude
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
        elseif currentEnemy and currentEnemy.Name == "FactoryPool" then
            -- The exact position where the FactoryPool can take damage!
            local factoryPos = Vector3.new(8675, 289, 11824)
            desiredY = factoryPos.Y
            targetSpot = factoryPos
        else
            if isCloseToArrival then
                desiredY = targetDest.Y + 7.5 -- Go 7.5 studs above target's height when close to enemy
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
    end
end

function Model.EquipGoldenStaff()
    local character = LocalPlayer.Character
    if not character or character:FindFirstChild("Golden Staff") then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if humanoid and backpack then
        local staffTool = backpack:FindFirstChild("Golden Staff")
        if staffTool then humanoid:EquipTool(staffTool) end
    end
end

function Model.GetEnemiesInRange()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return {} end
    local enemiesList = {}
    local allEnemies = getAllEnemies()
    
    for _, npc in pairs(allEnemies) do
        for _, tName in ipairs(TARGET_SEQUENCE) do
            if isValidTarget(npc, tName) then
                local attackRange = (tName == "FactoryPool") and math.huge or 15
                if (character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude <= attackRange then
                    table.insert(enemiesList, npc)
                end
                break
            end
        end
    end
    return enemiesList
end

function Model.DoGoldenStaffCombo()
    local combatRegister = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CombatRegister")
    if not combatRegister then return end
    
    Model.EquipGoldenStaff()
    local targets = Model.GetEnemiesInRange()
    if #targets == 0 then
        task.wait(0.5)
        return
    end

    print("[AutoFarm] Enemies in range! Starting Golden Staff Combo...")
    for currentHit = 1, 4 do
        if not Model.State.isAutoFarming then break end
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then break end
        
        local myCFrame = character.HumanoidRootPart.CFrame
        local animName = (currentHit < 4) and ("Slash" .. currentHit) or ("GroundSlash" .. currentHit)
        local slashAnim = ReplicatedStorage:WaitForChild("Modules", 9e9)
            :WaitForChild("SwordHandle", 9e9)
            :WaitForChild("Swords", 9e9)
            :WaitForChild("Golden Staff", 9e9)
            :WaitForChild("Slashes", 9e9)
            :WaitForChild(animName, 9e9)
        
        local swingArgs = {
            [1] = {
                [1] = "swingsfx",
                [2] = "Sword",
                [3] = currentHit,
                [4] = "Ground",
                [5] = false,
                [6] = slashAnim,
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
                    [3] = "Melee",
                    [4] = {[1] = currentHit, [2] = "Ground", [3] = "Melee"},
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
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold Color for Golden Staff!
    toggleBtn.Text = "GOLDEN STAFF FARM: OFF"
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
        
        toggleBtn.Text = isFarming and "GOLDEN STAFF FARM: ON" or "GOLDEN STAFF FARM: OFF"
        toggleBtn.BackgroundColor3 = isFarming and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(255, 215, 0)
        
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
                Model.DoGoldenStaffCombo()
            end
        end)
        
        -- Automatically use Golden Staff Skills
        task.spawn(function()
            local skillEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Skill", 9e9)
            local skills = {"Rapid Thrust", "Golden Sweep"}
            
            while Model.State.isAutoFarming do
                local targets = Model.GetEnemiesInRange()
                if #targets > 0 then
                    for _, skillName in ipairs(skills) do
                        if not Model.State.isAutoFarming then break end
                        -- Fire the skill. We wrap in pcall AND task.spawn to prevent freezing.
                        task.spawn(function()
                            pcall(function()
                                local releaseEvent = skillEvent:InvokeServer(skillName)
                                if releaseEvent then
                                    -- Wait a tiny bit to "charge" the attack, then release it
                                    task.wait(0.5)
                                    releaseEvent:FireServer()
                                end
                            end)
                        end)
                        task.wait(1.5) -- Slight delay between skill casts
                    end
                end
                task.wait(5) -- Wait before checking cooldowns again
            end
        end)

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
    if Model.State.isAutoFarming then
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
    
    print("[Golden Staff Autofarm] Autofarm forcefully stopped and UI destroyed.")
end
