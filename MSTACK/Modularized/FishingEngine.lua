-- Fishing Engine

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or shared
local GlobalMem = env

-- Bind state variables locally for ease of use in this file
local _running = getgenv().FishmanState._running
local _connections = getgenv().FishmanState._connections
local Tabs = getgenv().FishmanState.Tabs
local Fluent = getgenv().FishmanState.Fluent
local addConn = getgenv().FishmanState.addConn
local disconnectAll = getgenv().FishmanState.disconnectAll
local TriggerSafeguardShutdown = getgenv().FishmanState.TriggerSafeguardShutdown
local SaveConfig = getgenv().FishmanState.SaveConfig
local isLobby = getgenv().FishmanState.isLobby


-- ======================================================================
-- 🎣 FISHING ENGINE CORE (Only initialized if NOT in lobby)
-- ======================================================================
getgenv().FishmanState.Model = { State = {} }
local shopEvent, buyableItems, sellEvent, questEvent, craftingRemote, Remote
local statsFolder, inventoryObj, peliObject
local cachedBaitItems = nil
    local loadedAnimations = {}
    getgenv().FishmanState.addConn(LocalPlayer.CharacterAdded:Connect(function() table.clear(loadedAnimations) end))
    
    -- 📍 LOCATION-BASED RECOVERY SYSTEM (AUTO SPAWN SHIP)
    task.spawn(function()
        local timeAtSafezone = 0
        local safezonePos = Vector3.new(-6852, 27, 9233)
        local debugCounter = 0
        while getgenv().FishmanState._running do
            task.wait(1)
            debugCounter = debugCounter + 1
            local fluent = getgenv().FishmanState.Fluent
            if fluent and fluent.Options then
                local isAutoSpawnON = fluent.Options.T_AutoSpawnShip and fluent.Options.T_AutoSpawnShip.Value
                                       
                if isAutoSpawnON and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    local dist = (hrp.Position - safezonePos).Magnitude
                    
                    if debugCounter >= 3 then
                        print(string.format("[Fishman Debug] AutoSpawnShip: ON | Dist to Safezone: %d | Timer: %d/8", math.floor(dist), timeAtSafezone))
                        debugCounter = 0
                    end
                    
                    if dist < 600 then 
                        timeAtSafezone = timeAtSafezone + 1
                        if timeAtSafezone >= 8 then
                            print("[Fishman] Back to safezone player died now retriggering auto spawn ship something")
                            
                            if fluent.Options.T_MegStack then fluent.Options.T_MegStack:SetValue(false) end
                            if fluent.Options.T_MegStackPassive then fluent.Options.T_MegStackPassive:SetValue(false) end
                            
                            task.spawn(function()
                                if fluent.Options.T_AutoSpawnShip then
                                    fluent.Options.T_AutoSpawnShip:SetValue(false)
                                    task.wait(2)
                                    fluent.Options.T_AutoSpawnShip:SetValue(true)
                                end
                            end)
                            
                            timeAtSafezone = 0 -- Reset counter
                        end
                    else
                        timeAtSafezone = 0
                    end
                else
                    if debugCounter >= 3 then
                        print("[Fishman Debug] Location Loop running, but AutoSpawnShip is OFF or Character is missing.")
                        debugCounter = 0
                    end
                    timeAtSafezone = 0
                end
            end
        end
    end)
    getgenv().FishmanState.isAFKModeActive = false
    getgenv().FishmanState.secondsSinceLastInput = 0
local craftHeartbeatConn = nil
local craftFlyTarget = nil

    local EVASION_DIRECTIONS = {
        Vector3.new(1, 0, 0),   -- 1. Slide Right
        Vector3.new(0, 1, 0)    -- 2. Climb Up (Only if cornered/trapped)
    }

    getgenv().FishmanState.Model.State = {
        isFishing             = false,
        strictReel            = false,
        autoBuy               = not isLobby,
        autoSell              = false,
        isBuying              = false,
        isAutoTraveling       = false,
        travelStage           = 1,
        waypoint1             = Vector3.new(406.69, 48.32, -32.21),
        waypoint2             = Vector3.new(174.10, 10.32, -48.09),
        finalTarget           = Vector3.new(104, 9, -56),
        travelMessage         = "",
        autoCraft             = false,
        isCurrentlyCrafting   = false,
        waitingForArrivalToFish = false,
        isCraftFlying         = false,
        activeNavigation      = nil,
        shipSpeed             = 60,
    }

if not isLobby then
    shopEvent      = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Shop", 9e9)
    buyableItems   = workspace:WaitForChild("BuyableItems", 9e9)
    sellEvent      = ReplicatedStorage:WaitForChild("FishingShopRemote", 9e9)
    questEvent     = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Quest", 9e9)
    craftingRemote = ReplicatedStorage:WaitForChild("CraftingRemote", 9e9)
    Remote         = ReplicatedStorage:WaitForChild("Fishing", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("Action", 9e9)
    statsFolder    = ReplicatedStorage:WaitForChild("Stats" .. LocalPlayer.Name, 9e9)
    inventoryObj   = statsFolder:WaitForChild("Inventory", 9e9):WaitForChild("Inventory", 9e9)
    peliObject     = statsFolder:WaitForChild("Stats", 9e9):WaitForChild("Peli", 9e9)
    
    local LEGENDARY_FISHES  = { "Anglerfish", "Golden Ribbon Angelfish", "Golden Polka Puffer", "Golden Tigerfin" }
    local MAX_PELI            = 1000000
    local BAIT_NAME           = "Common Fish Bait"
    local MIN_BAIT            = 1
    local BUY_AMOUNT          = 300
    local BAIT_SEARCH_RADIUS  = 25
    local THROW_ANIMATION_ID  = "rbxassetid://140322334422224"
    local REEL_ANIMATION_ID   = "rbxassetid://136623058564703"
    local fishToSell = { "Crimson Snapper", "Exotic Tigerfin", "Fangfish", "Zebra Ribbon Angelfish", "Blue-Lip Grouper", "Tigerfin", "Crimson Polka Puffer", "Common Fish", "Seaweed", "Old Boot", "Tin Can" }
    local VALID_RODS = { "Devil Fruit Rod", "Merchants Banana Rod", "Lovestruck Rod", "Fishing Rod" }
    
    local function clearAnimationCache()
        for _, track in pairs(loadedAnimations) do pcall(function() track:Stop(0) end) end
        table.clear(loadedAnimations)
    end

    local function playAnimation(animationId)
        local character = LocalPlayer.Character
        if not character then return nil end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

        local track = loadedAnimations[animationId]
        if track and not track.IsPlaying and not pcall(function() return track.Length end) then
            loadedAnimations[animationId] = nil
            track = nil
        end

        if not track then
            local anim = Instance.new("Animation")
            anim.AnimationId = animationId
            track = animator:LoadAnimation(anim)
            track.Priority = Enum.AnimationPriority.Action
            loadedAnimations[animationId] = track
        end

        track:Play(0.1)
        return track
    end
    
    -- ======================================================================
    -- 🚀 FLIGHT & MOVEMENT SUBSYSTEM
    -- ======================================================================
    getgenv().FishmanState.Model.EnableFlight = function()
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if rootPart and humanoid then
            humanoid.PlatformStand = true
            local bg = rootPart:FindFirstChild("AutoTravel_Gyro") or Instance.new("BodyGyro")
            bg.Name = "AutoTravel_Gyro"
            bg.P = 9e4
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.CFrame = rootPart.CFrame
            bg.Parent = rootPart
            local bv = rootPart:FindFirstChild("AutoTravel_Velocity") or Instance.new("BodyVelocity")
            bv.Name = "AutoTravel_Velocity"
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = rootPart
        end
    end

    getgenv().FishmanState.Model.DisableFlight = function()
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if rootPart then
            for _, child in ipairs(rootPart:GetChildren()) do
                if child.Name == "AutoTravel_Gyro" or child.Name == "AutoTravel_Velocity" or child.Name == "AntiRotation" or child.Name == "AntiGravity" or child.Name == "FishingSpotBV" or child.Name == "FishingSpotBG" or child:IsA("BodyVelocity") or child:IsA("BodyGyro") then
                    pcall(function() child:Destroy() end)
                end
            end
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            rootPart.Velocity = Vector3.zero
            rootPart.RotVelocity = Vector3.zero
        end
        if humanoid then humanoid.PlatformStand = false end
        if getgenv().FishmanState.Model.State then
            getgenv().FishmanState.Model.State.isCraftFlying = false
        end
    end
    
    getgenv().FishmanState.Model.NavigateTo = function(object, targetPosition, speed, arrivalDistance)
        speed = speed or 100
        arrivalDistance = arrivalDistance or 20
        
        local primaryPart = object:IsA("Model") and object.PrimaryPart or (object:IsA("BasePart") and object or nil)
        if not primaryPart then return nil end

        local startPosition = primaryPart.Position
        local size = primaryPart.Size
        if object:IsA("Model") then
            local _, modelSize = object:GetBoundingBox()
            size = modelSize
        end

        local downwardParams = RaycastParams.new()
        downwardParams.FilterType = Enum.RaycastFilterType.Exclude
        downwardParams.FilterDescendantsInstances = {object, LocalPlayer.Character}
        downwardParams.IgnoreWater = false 

        local forwardParams = RaycastParams.new()
        forwardParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local ignoreList = {object, LocalPlayer.Character}
        local OCEAN_LEVEL = 0 
        
        local oceanModel = workspace:FindFirstChild("Ocean")
        if oceanModel then 
            table.insert(ignoreList, oceanModel) 
            local highestWater = -math.huge
            for _, part in ipairs(oceanModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    local topSurface = part.Position.Y + (part.Size.Y / 2)
                    if topSurface > highestWater then
                        highestWater = topSurface
                    end
                end
            end
            if highestWater ~= -math.huge then
                OCEAN_LEVEL = highestWater
            end
        end
        
        local envFolder = workspace:FindFirstChild("Env")
        if envFolder then
            local waterStuff = envFolder:FindFirstChild("WaterStuff")
            if waterStuff then
                table.insert(ignoreList, waterStuff)
                local highestWater = -math.huge
                for _, part in ipairs(waterStuff:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local topSurface = part.Position.Y + (part.Size.Y / 2)
                        if topSurface > highestWater then
                            highestWater = topSurface
                        end
                    end
                end
                if highestWater ~= -math.huge and highestWater > OCEAN_LEVEL then
                    OCEAN_LEVEL = highestWater
                end
            end
        end
        
        local npcsFolder = workspace:FindFirstChild("NPCs")
        if npcsFolder then
            table.insert(ignoreList, npcsFolder)
            local downIgnore = downwardParams.FilterDescendantsInstances
            table.insert(downIgnore, npcsFolder)
            downwardParams.FilterDescendantsInstances = downIgnore
        end
        
        forwardParams.FilterDescendantsInstances = ignoreList
        forwardParams.IgnoreWater = true 

        local humanoid = object:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = true end

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.zero
        bv.Parent = primaryPart

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.CFrame = primaryPart.CFrame
        bg.Parent = primaryPart

        local navigator = { 
            _isNavigating = true,
            _isPaused = false,
            _evadingTimer = 0,
            _evasionDir = nil,
            _roboTarget = nil,
            _lastScan = 0,
            Distance = 0
        }
        local connection = nil
        local noclipConnection = nil
        
        function navigator:Cancel()
            self._isNavigating = false
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
            if humanoid then humanoid.PlatformStand = false end
            if connection then connection:Disconnect() end
            if noclipConnection then noclipConnection:Disconnect() end
        end
        
        function navigator:TogglePause()
            self._isPaused = not self._isPaused
            if self._isPaused then
                if bv then bv.Velocity = Vector3.zero end
            end
            return self._isPaused
        end

        local function raycastSolid(origin, direction, params)
            local result = workspace:Raycast(origin, direction, params)
            local loops = 0
            while result and not result.Instance.CanCollide and loops < 10 do
                local currentList = params.FilterDescendantsInstances
                table.insert(currentList, result.Instance)
                params.FilterDescendantsInstances = currentList
                loops = loops + 1
                result = workspace:Raycast(origin, direction, params)
            end
            return result
        end

        local function blockcastSolid(cframe, extents, dir, params)
            local result = workspace:Blockcast(cframe, extents, dir, params)
            local loops = 0
            while result and not result.Instance.CanCollide and loops < 10 do
                local currentList = params.FilterDescendantsInstances
                table.insert(currentList, result.Instance)
                params.FilterDescendantsInstances = currentList
                loops = loops + 1
                result = workspace:Blockcast(cframe, extents, dir, params)
            end
            return result
        end

        local cachedParts = {}
        for _, part in ipairs(object:GetDescendants()) do
            if part:IsA("BasePart") then table.insert(cachedParts, part) end
        end
        local descAdded = object.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then table.insert(cachedParts, part) end
        end)

        noclipConnection = RunService.Stepped:Connect(function()
            if not getgenv().FishmanState._running then 
                if descAdded then descAdded:Disconnect() end
                navigator:Cancel() 
                return 
            end
            if not navigator._isNavigating or navigator._isPaused then return end
            for _, part in ipairs(cachedParts) do
                if part.CanCollide then part.CanCollide = false end
            end
        end)
        
        local originalCancel = navigator.Cancel
        function navigator:Cancel()
            if descAdded then descAdded:Disconnect() end
            originalCancel(self)
        end

        connection = RunService.Heartbeat:Connect(function(deltaTime)
            if not getgenv().FishmanState._running then navigator:Cancel() return end
            if not navigator._isNavigating then
                navigator:Cancel()
                return
            end
            
            if navigator._isPaused then return end
            
            local currentPos = primaryPart.Position
            local flatCurrent = Vector3.new(currentPos.X, 0, currentPos.Z)
            local flatTarget = Vector3.new(targetPosition.X, 0, targetPosition.Z)
            
            local directionToTarget = (flatTarget - flatCurrent)
            local distToTarget = directionToTarget.Magnitude
            
            navigator.Distance = math.floor(distToTarget)
            
            if not navigator._roboTarget and distToTarget <= 1500 then
                local now = tick()
                if now - navigator._lastScan > 1 then
                    navigator._lastScan = now
                    if npcsFolder then
                        local closestRobo = nil
                        local shortestDist = 1500
                        
                        for _, npc in ipairs(npcsFolder:GetChildren()) do
                            if string.find(string.lower(npc.Name), "robo") then
                                local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
                                if root then
                                    local distToDestination = (root.Position - targetPosition).Magnitude
                                    local distToStart = (root.Position - startPosition).Magnitude
                                    
                                    if distToDestination < shortestDist and distToDestination < distToStart then
                                        shortestDist = distToDestination
                                        closestRobo = root
                                    end
                                end
                            end
                        end
                        
                        if closestRobo then
                            navigator._roboTarget = closestRobo
                        end
                    end
                end
            end
            
            if navigator._roboTarget then
                local roboPos = navigator._roboTarget.Position
                local roboLook = navigator._roboTarget.CFrame.LookVector
                targetPosition = roboPos + (roboLook * 15)
                flatTarget = Vector3.new(targetPosition.X, 0, targetPosition.Z)
                directionToTarget = (flatTarget - flatCurrent)
                distToTarget = directionToTarget.Magnitude
                arrivalDistance = 8 
            end
            
            local moveDir = directionToTarget.Unit
            if distToTarget == 0 then moveDir = primaryPart.CFrame.LookVector end
            
            local targetVelocity = (moveDir * speed)
            local targetRotation = CFrame.lookAt(currentPos, currentPos + moveDir)
            
            local lookAheadPos = flatCurrent + (targetVelocity.Unit * 5)
            local rayOrigin = Vector3.new(lookAheadPos.X, currentPos.Y + 500, lookAheadPos.Z)
            local groundHit = raycastSolid(rayOrigin, Vector3.new(0, -1000, 0), downwardParams)
            
            if distToTarget <= arrivalDistance then
                if navigator._roboTarget then
                    navigator:Cancel()
                    return
                else
                    if groundHit and groundHit.Position.Y > (OCEAN_LEVEL + 3) then
                        navigator:Cancel()
                        return
                    end
                    if distToTarget <= 20 then
                        navigator:Cancel()
                        return
                    end
                end
            end
            
            local targetY = currentPos.Y
            if groundHit then
                targetY = groundHit.Position.Y + 5 + (size.Y / 2)
            end
            
            local minAllowedHeight = OCEAN_LEVEL + 5 + (size.Y / 2)
            if targetY < minAllowedHeight then targetY = minAllowedHeight end
            
            local wallCheckCFrame = primaryPart.CFrame + Vector3.new(0, 3, 0)
            local isCloseToArrival = (distToTarget <= arrivalDistance + 15)
            
            if navigator._evadingTimer > 0 and not isCloseToArrival then
                navigator._evadingTimer = navigator._evadingTimer - deltaTime
                local evadeWallCast = blockcastSolid(wallCheckCFrame, size, navigator._evasionDir * 15, forwardParams)
                if evadeWallCast and evadeWallCast.Distance <= 5 then
                    navigator._evadingTimer = 0
                else
                    targetVelocity = (navigator._evasionDir * speed)
                    if navigator._evasionDir.Y >= 0.99 or navigator._evasionDir.Y <= -0.99 then
                        targetRotation = CFrame.lookAt(currentPos, currentPos + navigator._evasionDir + (moveDir * 0.01))
                    else
                        targetRotation = CFrame.lookAt(currentPos, currentPos + navigator._evasionDir)
                    end
                end
            elseif not isCloseToArrival then
                local wallCast = blockcastSolid(wallCheckCFrame, size, moveDir * 10, forwardParams)
                if wallCast and wallCast.Distance <= 5 then
                    if wallCast.Distance > 0.5 then
                        local evaded = false
                        local baseLook = CFrame.lookAt(currentPos, currentPos + moveDir)
                        for _, evasionDir in ipairs(EVASION_DIRECTIONS) do
                            local relativeVector = evasionDir
                            if evasionDir.X ~= 0 then relativeVector = baseLook:VectorToWorldSpace(evasionDir) end
                            local evadeCast = blockcastSolid(wallCheckCFrame, size, relativeVector * 15, forwardParams)
                            if not evadeCast then
                                navigator._evadingTimer = 0.3 
                                navigator._evasionDir = relativeVector
                                targetVelocity = (relativeVector * speed)
                                if relativeVector.Y >= 0.99 or relativeVector.Y <= -0.99 then
                                    targetRotation = CFrame.lookAt(currentPos, currentPos + relativeVector + (moveDir * 0.01))
                                else
                                    targetRotation = CFrame.lookAt(currentPos, currentPos + relativeVector)
                                end
                                evaded = true
                                break
                            end
                        end
                        if not evaded then
                            navigator._evadingTimer = 0.3
                            navigator._evasionDir = Vector3.new(0, 1, 0)
                        end
                    end
                end
            end
            
            if navigator._evadingTimer <= 0 or isCloseToArrival then
                local heightDiff = targetY - currentPos.Y
                local yVelocity = math.clamp(heightDiff * 5, -speed, speed)
                targetVelocity = Vector3.new(targetVelocity.X, yVelocity, targetVelocity.Z)
            end
            
            bv.Velocity = targetVelocity
            bg.CFrame = targetRotation
        end)
        
        return navigator
    end
    
    local cachedTravelParams = RaycastParams.new()
    cachedTravelParams.FilterType = Enum.RaycastFilterType.Exclude

    getgenv().FishmanState.Model.HandleMovement = function(deltaTime)
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local cur = rootPart.Position
        
        local tgt
        if getgenv().FishmanState.Model.State.travelStage == 1 then tgt = getgenv().FishmanState.Model.State.waypoint1
        elseif getgenv().FishmanState.Model.State.travelStage == 2 then tgt = getgenv().FishmanState.Model.State.waypoint2
        else tgt = getgenv().FishmanState.Model.State.finalTarget end
        
        local tgtY = tgt.Y
        local nextPoint
        local goingUp = (tgtY > cur.Y)

        if goingUp and math.abs(cur.Y - tgtY) > 1 then nextPoint = Vector3.new(cur.X, tgtY, cur.Z)
        elseif math.abs(cur.X - tgt.X) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, cur.Z)
        elseif math.abs(cur.Z - tgt.Z) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, tgt.Z)
        elseif not goingUp and math.abs(cur.Y - tgtY) > 1 then nextPoint = Vector3.new(tgt.X, tgtY, tgt.Z)
        else
            if getgenv().FishmanState.Model.State.travelStage == 1 then
                getgenv().FishmanState.Model.State.travelStage = 2
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.PlatformStand = false end
                return
            elseif getgenv().FishmanState.Model.State.travelStage == 2 then
                getgenv().FishmanState.Model.State.travelStage = 3
                return
            end
            
            getgenv().FishmanState.Model.State.isAutoTraveling = false
            getgenv().FishmanState.Model.DisableFlight()
            getgenv().FishmanState.Model.State.travelMessage = "Arrived at Bait"
            return
        end

        local newX, newZ = cur.X, cur.Z
        local horizNext = Vector3.new(nextPoint.X, cur.Y, nextPoint.Z)
        local horizDist = (Vector3.new(cur.X, 0, cur.Z) - Vector3.new(nextPoint.X, 0, nextPoint.Z)).Magnitude
        
        if horizDist > 0 then
            local alpha = math.clamp((90 * deltaTime) / horizDist, 0, 1)
            local hLerp = cur:Lerp(horizNext, alpha)
            newX, newZ = hLerp.X, hLerp.Z
        end

        local newY = cur.Y
        if getgenv().FishmanState.Model.State.travelStage > 1 and not goingUp then
            cachedTravelParams.FilterDescendantsInstances = {LocalPlayer.Character}

            local floorY = tgtY
            local rayStart = Vector3.new(newX, cur.Y + 10, newZ)
            local remainingDist = 500
            
            while remainingDist > 0 do
                local res = workspace:Raycast(rayStart, Vector3.new(0, -remainingDist, 0), cachedTravelParams)
                if res then
                    if res.Instance.CanCollide and res.Instance.Anchored then
                        floorY = math.max(tgtY, res.Position.Y + 3.5)
                        break
                    else
                        local advance = (rayStart - res.Position).Magnitude + 0.1
                        rayStart = res.Position - Vector3.new(0, 0.1, 0)
                        remainingDist = remainingDist - advance
                    end
                else
                    break
                end
            end

            if cur.Y > floorY then
                newY = cur.Y - (150 * deltaTime)
                if newY < floorY then newY = floorY end
            else
                newY = floorY
            end
        else
            local yDist = math.abs(nextPoint.Y - cur.Y)
            if yDist > 0 then
                local alpha = math.clamp((90 * deltaTime) / yDist, 0, 1)
                newY = cur.Y + (nextPoint.Y - cur.Y) * alpha
            end
        end

        rootPart.CFrame = CFrame.new(newX, newY, newZ) * rootPart.CFrame.Rotation
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end
    
    getgenv().FishmanState.Model.StartTraveling = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local pos = hrp.Position
        local d1 = (pos - getgenv().FishmanState.Model.State.waypoint1).Magnitude
        local d2 = (pos - getgenv().FishmanState.Model.State.waypoint2).Magnitude
        local d3 = (pos - getgenv().FishmanState.Model.State.finalTarget).Magnitude

        if d3 < d2 and d3 < d1 then getgenv().FishmanState.Model.State.travelStage = 3
        elseif d2 < d1 then getgenv().FishmanState.Model.State.travelStage = 2
        else getgenv().FishmanState.Model.State.travelStage = 1 end

        getgenv().FishmanState.Model.State.travelMessage = "Traveling..."
        getgenv().FishmanState.Model.State.isAutoTraveling = true
        getgenv().FishmanState.Model.EnableFlight()
    end

    local isMovingToSpot = false
    local spotMoveThread = nil
    local spotNoclipConn = nil
    local spotDescAddedConn = nil
    local spotAnimConn = nil
    local spotSeatedConn = nil

    getgenv().FishmanState.Model.StopMovingToFishingSpot = function()
        isMovingToSpot = false

        -- Destroy any leftover safety platform
        local oldPlat = workspace:FindFirstChild("FishingSafetyPlatform")
        if oldPlat then
            pcall(function() oldPlat:Destroy() end)
        end

        if spotSeatedConn then
            spotSeatedConn:Disconnect()
            spotSeatedConn = nil
        end
        if spotAnimConn then
            spotAnimConn:Disconnect()
            spotAnimConn = nil
        end
        if spotNoclipConn then
            spotNoclipConn:Disconnect()
            spotNoclipConn = nil
        end
        if spotDescAddedConn then
            spotDescAddedConn:Disconnect()
            spotDescAddedConn = nil
        end
        
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, child in ipairs(hrp:GetChildren()) do
                if child.Name == "FishingSpotBV" or child.Name == "FishingSpotBG" or child.Name == "AutoTravel_Velocity" or child.Name == "AutoTravel_Gyro" or child:IsA("BodyVelocity") or child:IsA("BodyGyro") then
                    pcall(function() child:Destroy() end)
                end
            end
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end

        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and (p.Name == "UpperTorso" or p.Name == "LowerTorso" or p.Name == "Torso" or p.Name == "Head") then
                    p.CanCollide = true
                end
            end
        end

        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then 
            humanoid.PlatformStand = false 
            pcall(function()
                humanoid:Move(Vector3.zero, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            end)
        end

        local fluent = getgenv().FishmanState.Fluent
        if fluent and fluent.Options and fluent.Options.T_MoveToFishingSpot and fluent.Options.T_MoveToFishingSpot.Value == true then
            fluent.Options.T_MoveToFishingSpot:SetValue(false)
        end

        pcall(function()
            if spotMoveThread and spotMoveThread ~= coroutine.running() then
                task.cancel(spotMoveThread)
            end
        end)
        spotMoveThread = nil
    end

    getgenv().FishmanState.Model.MoveToFishingSpot = function(targetPos)
        targetPos = targetPos or Vector3.new(104, 9, -56)
        
        if isMovingToSpot then
            getgenv().FishmanState.Model.StopMovingToFishingSpot()
            task.wait(0.05)
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then
            warn("[Fishman] Character or HumanoidRootPart missing.")
            return false
        end

        isMovingToSpot = true

        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            humanoid.Sit = false
        end)

        spotSeatedConn = humanoid.Seated:Connect(function(isSeated, seat)
            if isMovingToSpot and isSeated then
                task.defer(function()
                    if isMovingToSpot and humanoid then
                        humanoid.Sit = false
                        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
                        if seat and seat:FindFirstChild("SeatWeld") then
                            pcall(function() seat.SeatWeld:Destroy() end)
                        end
                    end
                end)
            end
        end)

        -- Disable CanCollide (Noclip) on character body parts to prevent obstacle snagging
        local cachedParts = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(cachedParts, part)
                part.CanCollide = false
            end
        end
        spotDescAddedConn = char.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                table.insert(cachedParts, part)
                part.CanCollide = false
            end
        end)
        spotNoclipConn = RunService.Stepped:Connect(function()
            if not isMovingToSpot or not getgenv().FishmanState._running then return end
            for _, part in ipairs(cachedParts) do
                if part and part.Parent and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)

        -- Suppress running/walking animations
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local name = string.lower(track.Name or (track.Animation and track.Animation.Name) or "")
                if string.find(name, "run") or string.find(name, "walk") or string.find(name, "swim") then
                    track:Stop(0)
                end
            end
            spotAnimConn = animator.AnimationPlayed:Connect(function(track)
                if not isMovingToSpot then return end
                local name = string.lower(track.Name or (track.Animation and track.Animation.Name) or "")
                if string.find(name, "run") or string.find(name, "walk") or string.find(name, "swim") then
                    task.defer(function()
                        if isMovingToSpot then
                            track:Stop(0)
                        end
                    end)
                end
            end)
        end

        spotMoveThread = task.spawn(function()
            if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Notify then
                getgenv().FishmanState.Fluent:Notify({
                    Title = "Move to Fishing Spot",
                    Content = "Moving to (104, 9, -56)...",
                    Duration = 3
                })
            end

            if getgenv().FishmanState.Model.DisableFlight then
                pcall(getgenv().FishmanState.Model.DisableFlight)
            end
            for _, child in ipairs(hrp:GetChildren()) do
                if child.Name == "AutoTravel_Velocity" or child.Name == "AutoTravel_Gyro" or child.Name == "AntiRotation" or child.Name == "AntiGravity" then
                    pcall(function() child:Destroy() end)
                end
            end
            humanoid.PlatformStand = false
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end)

            -- Cancel any existing upward momentum immediately so we drop to ground level right away
            if hrp.AssemblyLinearVelocity.Y > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
            end

            local minFloorY = 8

            -- Destroy any leftover safety platform
            local oldPlat = workspace:FindFirstChild("FishingSafetyPlatform")
            if oldPlat then
                pcall(function() oldPlat:Destroy() end)
            end

            -- If starting below the floor limit (Y=8), immediately raise to Y=8
            if hrp.Position.Y < minFloorY then
                hrp.CFrame = CFrame.new(hrp.Position.X, minFloorY, hrp.Position.Z) * hrp.CFrame.Rotation
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.Velocity = Vector3.zero
            end

            local function computeWaypoints(fromPos)
                local startPos = fromPos
                -- If starting in mid-air, raycast down to find ground for pathfinding
                local rpParams = RaycastParams.new()
                rpParams.FilterDescendantsInstances = {char}
                rpParams.FilterType = Enum.RaycastFilterType.Exclude
                local floorRay = workspace:Raycast(fromPos, Vector3.new(0, -300, 0), rpParams)
                if floorRay then
                    startPos = floorRay.Position + Vector3.new(0, 2, 0)
                end
                if startPos.Y < minFloorY then
                    startPos = Vector3.new(startPos.X, minFloorY, startPos.Z)
                end

                local path = PathfindingService:CreatePath({
                    AgentRadius = 2.0,
                    AgentHeight = 5,
                    AgentCanJump = false,
                    WaypointSpacing = 3.5,
                    Costs = { Water = 50 }
                })

                local pathSuccess = pcall(function()
                    path:ComputeAsync(startPos, targetPos)
                end)

                local pts = {}
                if pathSuccess and path.Status == Enum.PathStatus.Success then
                    pts = path:GetWaypoints()
                else
                    local dist = (fromPos - targetPos).Magnitude
                    local steps = math.max(2, math.floor(dist / 4))
                    for i = 1, steps do
                        local alpha = i / steps
                        local p = fromPos:Lerp(targetPos, alpha)
                        table.insert(pts, { Position = p, Action = Enum.PathWaypointAction.Walk })
                    end
                end
                return pts
            end

            local bv = hrp:FindFirstChild("FishingSpotBV") or Instance.new("BodyVelocity")
            bv.Name = "FishingSpotBV"
            bv.MaxForce = Vector3.new(9e5, 9e5, 9e5)
            bv.Velocity = Vector3.zero
            bv.Parent = hrp

            local bg = hrp:FindFirstChild("FishingSpotBG") or Instance.new("BodyGyro")
            bg.Name = "FishingSpotBG"
            bg.MaxTorque = Vector3.new(0, 9e5, 0) -- Only yaw: keeps character upright and turns naturally
            bg.P = 2e4
            bg.D = 500
            bg.CFrame = hrp.CFrame
            bg.Parent = hrp

            local hipOffset = 3.0
            if humanoid and humanoid.HipHeight and humanoid.HipHeight > 0 then
                hipOffset = humanoid.HipHeight + (hrp.Size.Y / 2)
            end

            local moveSpeed = 60
            local reachedTarget = false

            local waypoints = computeWaypoints(hrp.Position)
            local currentWpIndex = 1

            local rpParams = RaycastParams.new()
            rpParams.FilterDescendantsInstances = {char}
            rpParams.FilterType = Enum.RaycastFilterType.Exclude

            while isMovingToSpot and getgenv().FishmanState._running and hrp.Parent and currentWpIndex <= #waypoints do
                local wp = waypoints[currentWpIndex]
                local wpPos = wp.Position
                local isLast = (currentWpIndex == #waypoints)
                local wpThreshold = isLast and 2.0 or 3.5

                local stuckTimer = 0
                local lastPos = hrp.Position

                while isMovingToSpot and getgenv().FishmanState._running and hrp.Parent do
                    if humanoid.Health <= 0 then break end

                    -- Prevent getting seated on chairs/benches while traveling
                    if humanoid.Sit or humanoid:GetState() == Enum.HumanoidStateType.Seated then
                        humanoid.Sit = false
                        pcall(function()
                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                        end)
                        for _, child in ipairs(char:GetDescendants()) do
                            if child:IsA("Weld") and (child.Name == "SeatWeld" or string.find(child.Name:lower(), "seat")) then
                                pcall(function() child:Destroy() end)
                            end
                        end
                    end

                    local curPos = hrp.Position

                    -- Minimum floor limit: character can never go down below Y = 8
                    if curPos.Y < minFloorY then
                        hrp.CFrame = CFrame.new(curPos.X, minFloorY, curPos.Z) * hrp.CFrame.Rotation
                        curPos = hrp.Position
                        if hrp.AssemblyLinearVelocity.Y < 0 then
                            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
                        end
                    end

                    local distToFinal = (Vector3.new(curPos.X, 0, curPos.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
                    if distToFinal <= 3.0 then
                        reachedTarget = true
                        break
                    end

                    local horizDiff = Vector3.new(wpPos.X - curPos.X, 0, wpPos.Z - curPos.Z)
                    local horizDist = horizDiff.Magnitude

                    if horizDist <= wpThreshold then
                        currentWpIndex = currentWpIndex + 1
                        break
                    end

                    local dt = RunService.Heartbeat:Wait()
                    local moveDir = (horizDist > 0.1) and horizDiff.Unit or (Vector3.new(targetPos.X - curPos.X, 0, targetPos.Z - curPos.Z).Unit)

                    if (curPos - lastPos).Magnitude < 0.25 then
                        stuckTimer = stuckTimer + dt
                        -- Natural jump attempt when approaching small fences or curbs
                        if stuckTimer > 0.12 and stuckTimer < 0.25 then
                            pcall(function()
                                humanoid.Jump = true
                            end)
                        end
                        if stuckTimer > 0.35 then
                            -- Teleport 2 studs forward past obstacle, preserving altitude but at least minFloorY 8
                            local teleY = math.max(curPos.Y, minFloorY) + 0.5
                            hrp.CFrame = CFrame.new(curPos.X + (moveDir.X * 2.0), teleY, curPos.Z + (moveDir.Z * 2.0)) * hrp.CFrame.Rotation
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.Velocity = Vector3.zero

                            -- Re-pathfind from the new position 2 studs away
                            waypoints = computeWaypoints(hrp.Position)
                            currentWpIndex = 1
                            break
                        end
                    else
                        stuckTimer = 0
                        lastPos = curPos
                    end

                    -- Find true ground surface below player or use waypoint ground height
                    local groundY = wpPos.Y
                    local groundHit = workspace:Raycast(curPos + Vector3.new(0, 3, 0), Vector3.new(0, -20, 0), rpParams)
                    if groundHit and groundHit.Position and math.abs(groundHit.Position.Y - wpPos.Y) < 5 then
                        groundY = groundHit.Position.Y
                    end

                    -- Target altitude: ground surface + hip standing offset (feet right on the ground), floor limit at least minFloorY
                    local desiredY = math.max(groundY + hipOffset, minFloorY)
                    local yDiff = desiredY - curPos.Y

                    local yVelocity = math.clamp(yDiff * 15, -20, 25)
                    if curPos.Y <= minFloorY and yVelocity < 0 then
                        yVelocity = 0
                    end

                    bv.MaxForce = Vector3.new(9e5, 9e5, 9e5)
                    bv.Velocity = Vector3.new(moveDir.X * moveSpeed, yVelocity, moveDir.Z * moveSpeed)

                    -- Suppress running/walking animation
                    pcall(function()
                        humanoid:Move(Vector3.zero, false)
                    end)

                    if horizDist > 0.5 then
                        bg.CFrame = CFrame.lookAt(curPos, curPos + Vector3.new(moveDir.X, 0, moveDir.Z))
                    end
                end

                if reachedTarget then break end
            end

            getgenv().FishmanState.Model.StopMovingToFishingSpot()

            if reachedTarget or (hrp and (hrp.Position - targetPos).Magnitude <= 5) then
                print("[Fishman] Arrived at Fishing Spot (104, 9, -56)! Stopping completely.")
                if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Notify then
                    getgenv().FishmanState.Fluent:Notify({
                        Title = "Move to Fishing Spot",
                        Content = "Arrived at Fishing Spot (104, 9, -56)! Movement stopped.",
                        Duration = 4
                    })
                end
            end
        end)

        return true
    end

    getgenv().MoveToFishingSpot = getgenv().FishmanState.Model.MoveToFishingSpot

    
    -- ======================================================================
    -- 🔨 CRAFTING SUBSYSTEM
    -- ======================================================================
    local lastGeppoEffectTick = 0
    local lastGeppoRemoteTick = 0
    local function PlayGeppoEffect(character, rootPart)
        local currentTick = tick()
        local cf = rootPart.CFrame * CFrame.new(0, -3, 0)
        
        if currentTick - lastGeppoEffectTick >= 0.2 then
            lastGeppoEffectTick = currentTick
            pcall(function()
                if _G.PlayEffect then
                    _G.PlayEffect("Geppo", nil, {char = character, cf = cf})
                end
            end)
        end
        
        if currentTick - lastGeppoRemoteTick >= 2 then
            lastGeppoRemoteTick = currentTick
            pcall(function()
                local stats = game.ReplicatedStorage:FindFirstChild("Stats" .. LocalPlayer.Name)
                local fs = stats and stats:FindFirstChild("Stats") and stats.Stats:FindFirstChild("FightingStyle")
                local skillName = "Sky Walk2"
                if fs then
                    if fs.Value == "Rokushiki" then skillName = "Geppo"
                    elseif fs.Value == "BlackLeg" then skillName = "Sky Walk"
                    elseif fs.Value == "Kamishiki" then skillName = "KamishikiGeppo"
                    end
                end
                game.ReplicatedStorage.Events.Skill:InvokeServer(skillName, {char = character, cf = cf})
            end)
        end
    end

    local function CraftFlyToAndWait(targetVector)
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid then return end
        
        getgenv().FishmanState.Model.State.isCraftFlying = true
        local speed = getgenv().FishmanState.Model.State.shipSpeed or 150
        
        print(string.format("[AutoCraft] going to %d %d %d...", math.round(targetVector.X), math.round(targetVector.Y), math.round(targetVector.Z)))
        
        humanoid.PlatformStand = true
        local bg = rootPart:FindFirstChild("AutoTravel_Gyro") or Instance.new("BodyGyro")
        bg.Name = "AutoTravel_Gyro"
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = rootPart.CFrame
        bg.Parent = rootPart
        
        local bv = rootPart:FindFirstChild("AutoTravel_Velocity") or Instance.new("BodyVelocity")
        bv.Name = "AutoTravel_Velocity"
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = rootPart
        
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {character}
        
        local maxDuration = 30
        local startTime = tick()
        
        while getgenv().FishmanState.Model.State.isCraftFlying and (tick() - startTime) < maxDuration do
            if not getgenv().FishmanState.Model.State.autoCraft and not getgenv().FishmanState.Model.State.isRefillingMegBait and not getgenv().FishmanState.Model.State.isManualTraveling and not getgenv().FishmanState.Model.State.isCurrentlyCrafting then
                break
            end
            
            local currentPos = rootPart.Position
            local flatDiff = Vector3.new(targetVector.X - currentPos.X, 0, targetVector.Z - currentPos.Z)
            local flatDist = flatDiff.Magnitude
            local totalDist = (targetVector - currentPos).Magnitude
            
            if totalDist <= 4 or (flatDist <= 3 and math.abs(targetVector.Y - currentPos.Y) <= 5) then
                break
            end
            
            -- Raycast down to keep on ground dynamically
            local groundRay = workspace:Raycast(currentPos + Vector3.new(0, 5, 0), Vector3.new(0, -30, 0), rayParams)
            local groundY = groundRay and (groundRay.Position.Y + 3.5) or targetVector.Y
            
            local targetPos = Vector3.new(targetVector.X, groundY, targetVector.Z)
            local moveDir = (targetPos - currentPos)
            local moveDist = moveDir.Magnitude
            
            if moveDist > 0.5 then
                local unitDir = moveDir.Unit
                bv.Velocity = unitDir * math.min(speed, moveDist * 15 + 10)
                bg.CFrame = CFrame.lookAt(currentPos, currentPos + Vector3.new(unitDir.X, 0, unitDir.Z))
            else
                bv.Velocity = Vector3.zero
            end
            
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
            
            PlayGeppoEffect(character, rootPart)
            task.wait(0.03)
        end
        
        bv.Velocity = Vector3.zero
        rootPart.CFrame = CFrame.new(targetVector) * rootPart.CFrame.Rotation
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        
        print(string.format("[AutoCraft] Arrived at %d %d %d!", math.round(targetVector.X), math.round(targetVector.Y), math.round(targetVector.Z)))
        getgenv().FishmanState.Model.State.isCraftFlying = false
    end

    getgenv().FishmanState.Model.CraftFlyPath = function(pathTable)
        for _, targetPos in ipairs(pathTable) do 
            if not getgenv().FishmanState.Model.State.autoCraft and not getgenv().FishmanState.Model.State.isRefillingMegBait and not getgenv().FishmanState.Model.State.isManualTraveling and not getgenv().FishmanState.Model.State.isCurrentlyCrafting then break end
            CraftFlyToAndWait(targetPos) 
        end
    end
    
    getgenv().FishmanState.Model.ReturnToShip = function()
        local hoverboard = getgenv().FishmanState.Model.FindHoverboard()
        local targetVector = nil
        
        if hoverboard then
            local hbCFrame = hoverboard:IsA("Model") and hoverboard:GetPivot() or hoverboard.CFrame
            targetVector = (hbCFrame * CFrame.new(0, 3, 4)).Position
            getgenv().FishmanState.Model.SaveHoverboardPos(targetVector)
        elseif getgenv().FishmanState.Model.LoadHoverboardPos() then
            targetVector = getgenv().FishmanState.Model.LoadHoverboardPos()
        else
            return false
        end
        
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false end
        
        getgenv().FishmanState.Model.State.isCraftFlying = true
        getgenv().FishmanState.Model.DisableFlight()
        task.wait(0.1)
        getgenv().FishmanState.Model.EnableFlight()
        local speed = getgenv().FishmanState.Model.State.shipSpeed or 60 
        
        local function TweenTo(point, customSpeed)
            local currentSpeed = customSpeed or speed
            if not getgenv().FishmanState.Model.State.isCraftFlying then return end
            local dist = (rootPart.Position - point).Magnitude
            if dist < 1 then return end
            
            local tweenInfo = TweenInfo.new(dist / currentSpeed, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(point) * rootPart.CFrame.Rotation})
            tween:Play()
            
            while tween.PlaybackState == Enum.PlaybackState.Playing do
                if not getgenv().FishmanState.Model.State.isCraftFlying then 
                    tween:Cancel()
                    break 
                end
                PlayGeppoEffect(character, rootPart)
                task.wait(0.1)
            end
        end

        local cur = rootPart.Position
        local upPoint = Vector3.new(cur.X, math.max(cur.Y, targetVector.Y) + 500, cur.Z)
        local overPoint = Vector3.new(targetVector.X, upPoint.Y, targetVector.Z)
        
        TweenTo(upPoint, speed * 0.5) -- 50% slower for going up
        TweenTo(overPoint)
        TweenTo(targetVector)
        
        getgenv().FishmanState.Model.DisableFlight()
        getgenv().FishmanState.Model.State.isCraftFlying = false
        return true
    end
    
    local function SafeInvokeQuest(chatState)
        pcall(function() questEvent:InvokeServer({ [1] = "npcChat", [2] = chatState }) end)
    end
    
    getgenv().FishmanState.Model.ExecuteLegendaryCraft = function()
        getgenv().FishmanState.Model.ForceCraftAll()
    end

    getgenv().FishmanState.Model.GetInventoryData = function()
        if inventoryObj and inventoryObj.Value and inventoryObj.Value ~= "" then
            local ok, data = pcall(function() return HttpService:JSONDecode(inventoryObj.Value) end)
            if ok and type(data) == "table" then return data end
        end
        local pguiObj = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ui") and LocalPlayer.PlayerGui.ui:FindFirstChild("inventoryObj")
        if pguiObj and pguiObj.Value and pguiObj.Value ~= "" then
            local ok, data = pcall(function() return HttpService:JSONDecode(pguiObj.Value) end)
            if ok and type(data) == "table" then return data end
        end
        return nil
    end

    getgenv().FishmanState.Model.ForceCraftAll = function()
        if getgenv().FishmanState.Model.State.isCurrentlyCrafting then 
            print("[AutoCraft] Crafting is already in progress!")
            return 
        end
        
        print("[AutoCraft] Checking inventory for Legendary Fish...")
        local inventoryData = getgenv().FishmanState.Model.GetInventoryData()
        if not inventoryData then
            print("[AutoCraft] ⚠️ Could not retrieve inventory data!")
            if getgenv().FishmanState.Fluent then
                getgenv().FishmanState.Fluent:Notify({ Title = "Craft All", Content = "Could not load inventory data!", Duration = 3 })
            end
            return
        end
        
        local currentLegBait = inventoryData["Legendary Fish Bait"] or inventoryData["Legendary Bait"] or 0
        if currentLegBait >= 300 then
            print(string.format("[AutoCraft] ⚠️ Legendary Bait is already full (%d/300)! Skipping craft.", currentLegBait))
            if getgenv().FishmanState.Fluent then
                getgenv().FishmanState.Fluent:Notify({ Title = "Craft All", Content = "Legendary Bait is already full (300/300)!", Duration = 3 })
            end
            local fishingSpot = getgenv().FishmanState.Model.State.finalTarget or Vector3.new(104, 9, -56)
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - Vector3.new(162, 9, -54)).Magnitude < 45 then
                print("[AutoCraft] At crafting area with full bait - flying back to fishing spot...")
                getgenv().FishmanState.Model.State.isCurrentlyCrafting = true
                getgenv().FishmanState.Model.EnableFlight()
                getgenv().FishmanState.Model.CraftFlyPath({ fishingSpot })
                getgenv().FishmanState.Model.DisableFlight()
                getgenv().FishmanState.Model.State.isCurrentlyCrafting = false
                getgenv().FishmanState.Model.EquipRod()
            end
            return
        end
        
        local hasAnyLegendary = false
        for _, legFish in ipairs(LEGENDARY_FISHES) do
            local fishCount = inventoryData[legFish] or 0
            if fishCount > 0 then
                hasAnyLegendary = true
                print(string.format("[AutoCraft] Found %s: %d", legFish, fishCount))
            end
        end
        
        if not hasAnyLegendary then
            print("[AutoCraft] ❌ No Legendary Fish found in inventory!")
            if getgenv().FishmanState.Fluent then
                getgenv().FishmanState.Fluent:Notify({ Title = "Craft All", Content = "No Legendary Fish to craft!", Duration = 3 })
            end
            return
        end
        
        local craftPos = Vector3.new(162, 9, -54)
        print("[AutoCraft] Going to 162, 9, -54 to craft legendary bait...")
        if getgenv().FishmanState.Fluent then
            getgenv().FishmanState.Fluent:Notify({ Title = "Craft All", Content = "Going to 162, 9, -54 to craft Legendary Bait...", Duration = 4 })
        end
        
        getgenv().FishmanState.Model.State.isCurrentlyCrafting = true
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            getgenv().FishmanState.Model.State.isCurrentlyCrafting = false 
            return 
        end
        local originalPos = hrp.Position
        
        -- Preserve previous states
        local wasFishing = getgenv().FishmanState.Model.State.isFishing
        local wasDeepSea = getgenv().FishmanState.Model.State.isDeepSeaCatcher
        local wasAutoBuy = getgenv().FishmanState.Model.State.autoBuy
        local wasAutoSell = getgenv().FishmanState.Model.State.autoSell
        local wasAutoTravel = getgenv().FishmanState.Model.State.isAutoTraveling
        local wasAutoCraft = getgenv().FishmanState.Model.State.autoCraft
        
        -- Temporarily suspend fishing, selling, and normal auto-travel
        getgenv().FishmanState.Model.State.isFishing = false
        getgenv().FishmanState.Model.State.isDeepSeaCatcher = false
        getgenv().FishmanState.Model.State.autoSell = false
        getgenv().FishmanState.Model.State.isAutoTraveling = false
        getgenv().FishmanState.Model.State.autoCraft = true
        getgenv().FishmanState.Model.State.travelMessage = "Going to 162 9 -54..."
        
        getgenv().FishmanState.Model.DisableFlight()
        getgenv().FishmanState.Model.UnequipRod()
        task.wait(1)
        
        getgenv().FishmanState.Model.EnableFlight()
        getgenv().FishmanState.Model.CraftFlyPath({ craftPos })
        
        print("[AutoCraft] Arrived at 162 9 -54! Talking to Sen and crafting Legendary Bait...")
        task.wait(0.5)
        SafeInvokeQuest(true)
        task.wait(0.5)
        
        local currentInv = getgenv().FishmanState.Model.GetInventoryData() or inventoryData
        for _, legFish in ipairs(LEGENDARY_FISHES) do
            local count = currentInv[legFish] or 0
            if count > 0 then
                print(string.format("[AutoCraft] Crafting %dx %s into Legendary Bait...", count, legFish))
                pcall(function()
                    craftingRemote:InvokeServer({
                        Count = count,
                        ExtraData = { ["Legendary Fish"] = legFish },
                        Method = "Craft",
                        BlueprintItem = "Legendary Fish Bait"
                    })
                end)
                task.wait(0.5)
            end
        end
        
        SafeInvokeQuest(false)
        task.wait(0.3)
        
        local returnTarget = getgenv().FishmanState.Model.State.finalTarget or Vector3.new(104, 9, -56)
        if (originalPos - craftPos).Magnitude > 30 then
            returnTarget = originalPos
        end
        print(string.format("[AutoCraft] Crafting completed! Returning to position (%d %d %d)...", math.round(returnTarget.X), math.round(returnTarget.Y), math.round(returnTarget.Z)))
        getgenv().FishmanState.Model.State.travelMessage = "Returning to fishing spot..."
        getgenv().FishmanState.Model.CraftFlyPath({ returnTarget })
        
        getgenv().FishmanState.Model.State.autoCraft = wasAutoCraft
        getgenv().FishmanState.Model.DisableFlight()
        getgenv().FishmanState.Model.EquipRod()
        
        getgenv().FishmanState.Model.State.isCurrentlyCrafting = false
        getgenv().FishmanState.Model.State.travelMessage = ""
        getgenv().FishmanState.Model.State.autoSell = wasAutoSell
        getgenv().FishmanState.Model.State.isAutoTraveling = wasAutoTravel
        getgenv().FishmanState.Model.State.isDeepSeaCatcher = wasDeepSea
        getgenv().FishmanState.Model.State.isFishing = wasFishing
        
        print(string.format("[AutoCraft] ✅ Successfully crafted legendary bait and returned! (Resumed Fishing: %s)", tostring(wasFishing)))
        if getgenv().FishmanState.Fluent then
            getgenv().FishmanState.Fluent:Notify({ Title = "Craft All", Content = "Finished crafting Legendary Bait and returned!", Duration = 4 })
        end
    end
    
    -- ======================================================================
    -- 🎣 FISHING & INVENTORY MANAGEMENT
    -- ======================================================================
    getgenv().FishmanState.Model.EquipRod = function()
        local character = LocalPlayer.Character
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and table.find(VALID_RODS, tool.Name) then return end
        end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and table.find(VALID_RODS, tool.Name) then
                    humanoid:EquipTool(tool)
                    task.wait(0.2)
                    return
                end
            end
        end
    end

    getgenv().FishmanState.Model.UnequipRod = function()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and table.find(VALID_RODS, tool.Name) then
                humanoid:UnequipTools()
                task.wait(0.2)
                return
            end
        end
    end
    
    getgenv().FishmanState.Model.BuyNearestBait = function()
        if getgenv().FishmanState.Model.State.isBuying then return end
        getgenv().FishmanState.Model.State.isBuying = true
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rootPart  = character:WaitForChild("HumanoidRootPart")
        local nearest, nearestDist = nil, BAIT_SEARCH_RADIUS

        if not cachedBaitItems then
            cachedBaitItems = {}
            for _, item in ipairs(buyableItems:GetChildren()) do
                if string.find(string.lower(item.Name), "bait") then
                    table.insert(cachedBaitItems, item)
                end
            end
            getgenv().FishmanState.addConn(buyableItems.ChildAdded:Connect(function(item)
                if string.find(string.lower(item.Name), "bait") then
                    table.insert(cachedBaitItems, item)
                end
            end))
        end

        for _, item in ipairs(cachedBaitItems) do
            local pos = (item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position) or (item:IsA("BasePart") and item.Position)
            if pos then
                local d = (rootPart.Position - pos).Magnitude
                if d < nearestDist then nearestDist = d; nearest = item end
            end
        end

        if nearest then
            pcall(function()
                if shopEvent:IsA("RemoteFunction") then shopEvent:InvokeServer(nearest, BUY_AMOUNT)
                else shopEvent:FireServer(nearest, BUY_AMOUNT) end
            end)
        end
        task.wait(0.5)
        getgenv().FishmanState.Model.State.isBuying = false
    end

    local hoverboardSaveFile = "FISHMAN23_HoverboardPos_" .. LocalPlayer.Name .. ".json"
    
    getgenv().FishmanState.Model.SaveHoverboardPos = function(pos)
        getgenv().CachedHoverboardTailPos = pos
        if writefile and HttpService then
            local data = { X = pos.X, Y = pos.Y, Z = pos.Z }
            pcall(function()
                writefile(hoverboardSaveFile, HttpService:JSONEncode(data))
            end)
        end
    end
    
    getgenv().FishmanState.Model.LoadHoverboardPos = function()
        if getgenv().CachedHoverboardTailPos then
            return getgenv().CachedHoverboardTailPos
        end
        if isfile and readfile and HttpService and isfile(hoverboardSaveFile) then
            local success, decoded = pcall(function()
                return HttpService:JSONDecode(readfile(hoverboardSaveFile))
            end)
            if success and type(decoded) == "table" and decoded.X and decoded.Y and decoded.Z then
                local pos = Vector3.new(decoded.X, decoded.Y, decoded.Z)
                getgenv().CachedHoverboardTailPos = pos
                return pos
            end
        end
        return nil
    end

    getgenv().FishmanState.Model.FindHoverboard = function()
        if getgenv().CachedHoverboard and getgenv().CachedHoverboard.Parent then
            return getgenv().CachedHoverboard
        end
        local character = LocalPlayer.Character
        local possibleNames = {
            LocalPlayer.Name .. "Ship",
            LocalPlayer.Name .. "Striker",
            LocalPlayer.Name .. "Hoverboard",
            LocalPlayer.Name .. "Coffin",
            LocalPlayer.Name .. "Boat"
        }
        if character then
            local hum = character:FindFirstChild("Humanoid")
            if hum and hum.SeatPart and hum.SeatPart.Name == "VehicleSeat" and hum.SeatPart.Parent then
                local pName = hum.SeatPart.Parent.Name
                if table.find(possibleNames, pName) or pName:find(LocalPlayer.Name) then
                    getgenv().CachedHoverboard = hum.SeatPart
                    return hum.SeatPart
                end
            end
        end
        local shipsFolder = workspace:FindFirstChild("Ships")
        if shipsFolder then
            local myShip = nil
            for _, name in ipairs(possibleNames) do
                myShip = shipsFolder:FindFirstChild(name)
                if myShip then break end
            end
            if myShip then
                local seat = myShip:FindFirstChild("VehicleSeat", true) or myShip:FindFirstChildOfClass("VehicleSeat")
                if seat then
                    getgenv().CachedHoverboard = seat
                    return seat
                else
                    getgenv().CachedHoverboard = myShip
                    return myShip
                end
            end
        end
        return nil
    end

    getgenv().FishmanState.Model.RefillMegBait = function()
        if getgenv().FishmanState.Model.State.isRefillingMegBait then return end
        getgenv().FishmanState.Model.State.isRefillingMegBait = true
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then getgenv().FishmanState.Model.State.isRefillingMegBait = false; return end
        local originalPos = hrp.Position
        
        getgenv().FishmanState.Model.State.isAutoTraveling = false
        getgenv().FishmanState.Model.DisableFlight()
        getgenv().FishmanState.Model.UnequipRod()
        task.wait(1)
        
        getgenv().FishmanState.Model.EnableFlight()
        
        local wasAutoCraft = getgenv().FishmanState.Model.State.autoCraft
        getgenv().FishmanState.Model.State.autoCraft = true 
        
        print("🚀 [MegStackLoc] 0 Common Fish Bait detected! Flying to island (-6760, 27, 9191)...")
        getgenv().FishmanState.Model.CraftFlyPath({ Vector3.new(-6760, 27, 9191) })
        
        print("⏳ [MegStackLoc] Arrived! Waiting 5 seconds for your macro to buy baits...")
        task.wait(5)
        
        print("🚀 [MegStackLoc] Flying back to fishing spot...")
        local hoverboard = getgenv().FishmanState.Model.FindHoverboard()
        if hoverboard then
            local hbCFrame = hoverboard:IsA("Model") and hoverboard:GetPivot() or hoverboard.CFrame
            local tailPos = (hbCFrame * CFrame.new(0, 3, 4)).Position
            getgenv().FishmanState.Model.SaveHoverboardPos(tailPos)
            getgenv().FishmanState.Model.CraftFlyPath({ tailPos })
        elseif getgenv().FishmanState.Model.LoadHoverboardPos() then
            getgenv().FishmanState.Model.CraftFlyPath({ getgenv().FishmanState.Model.LoadHoverboardPos() })
        else
            getgenv().FishmanState.Model.CraftFlyPath({ originalPos })
        end
        
        getgenv().FishmanState.Model.State.autoCraft = wasAutoCraft
        getgenv().FishmanState.Model.DisableFlight()
        getgenv().FishmanState.Model.EquipRod()
        
        print("✅ [MegStackLoc] Returned to fishing spot. Resuming operations.")
        getgenv().FishmanState.Model.State.isRefillingMegBait = false
    end

    getgenv().FishmanState.Model.CheckInventory = function()
        local inventoryData = getgenv().FishmanState.Model.GetInventoryData()
        if not inventoryData then return end
        
        if getgenv().FishmanState.Model.State.isMegStackLoc and not getgenv().FishmanState.Model.State.isRefillingMegBait then
            if (inventoryData["Common Fish Bait"] or 0) <= 0 then
                task.spawn(getgenv().FishmanState.Model.RefillMegBait)
            end
        end

        if getgenv().FishmanState.Model.State.autoBuy and not getgenv().FishmanState.Model.State.isBuying then
            if (inventoryData[BAIT_NAME] or 0) < MIN_BAIT then getgenv().FishmanState.Model.BuyNearestBait() end
        end

        if getgenv().FishmanState.Model.State.autoSell then
            local currentPeli = peliObject and peliObject.Value or 0
            if currentPeli < MAX_PELI then
                for _, fishName in ipairs(fishToSell) do
                    if (inventoryData[fishName] or 0) >= 1 then
                        pcall(function() sellEvent:InvokeServer({ Fish = fishName, All = true, Method = "SellFish" }) end)
                    end
                end
            end
        end
    end
    getgenv().FishmanState.Model.countMegalodons = function()
        local count = 0
        local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Env")}
        for _, folder in ipairs(folders) do
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child.Name == "Megalodon" and child:FindFirstChild("Humanoid") and child.Humanoid.Health > 0 then
                        count = count + 1
                    end
                end
            end
        end
        return count
    end
    
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local actionRemote = ReplicatedStorage:WaitForChild("Fishing", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("Action", 9e9)

-- === FISHING LOGIC ===
local function EquipRod()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:match("Rod") then return true end
    end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:match("Rod") then
            humanoid:EquipTool(tool)
            task.wait() 
            return true
        end
    end
    return false
end

local function GetWaterLevel(targetPos)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    if LocalPlayer.Character then
        rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
    end
    rayParams.IgnoreWater = false
    
    local rayY = (targetPos and targetPos.Y or 10) + 30
    local rayStart = Vector3.new(targetPos.X, rayY, targetPos.Z)
    local hit = workspace:Raycast(rayStart, Vector3.new(0, -150, 0), rayParams)
    if hit then
        if hit.Material == Enum.Material.Water or string.find(string.lower(hit.Instance.Name), "water") or string.find(string.lower(hit.Instance.Name), "sea") or string.find(string.lower(hit.Instance.Name), "ocean") then
            return hit.Position.Y
        end
    end
    
    local ocean = workspace:FindFirstChild("Ocean")
    if ocean then
        for _, part in ipairs(ocean:GetDescendants()) do
            if part:IsA("BasePart") then
                return part.Position.Y + (part.Size.Y / 2)
            end
        end
    end
    
    if hit then return hit.Position.Y end
    return targetPos and targetPos.Y or 0
end

local function DoFishingCycle()
    if getgenv().FishmanState.Model.State.isCurrentlyCrafting or getgenv().FishmanState.Model.State.isCraftFlying then
        return true
    end

    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return true end

    -- Prevent casting on the wooden dock at NPC Sen (162, 9, -54)
    local craftPos = Vector3.new(162, 9, -54)
    local fishingSpot = getgenv().FishmanState.Model.State.finalTarget or Vector3.new(104, 9, -56)
    if (rootPart.Position - craftPos).Magnitude < 45 then
        print("[Fishman] Character is at crafting area! Returning to fishing spot before casting...")
        if getgenv().FishmanState.Model.CraftFlyPath then
            getgenv().FishmanState.Model.State.isCurrentlyCrafting = true
            getgenv().FishmanState.Model.EnableFlight()
            getgenv().FishmanState.Model.CraftFlyPath({ fishingSpot })
            getgenv().FishmanState.Model.DisableFlight()
            getgenv().FishmanState.Model.State.isCurrentlyCrafting = false
            task.wait(0.5)
        end
        return true
    end

    if not EquipRod() then
        warn("No Fishing Rod equipped! Stopping auto-fish.")
        return false 
    end
    local castDistance = 10
    local forwardVec = rootPart and rootPart.CFrame.LookVector or Vector3.new(0, 0, -1)
    local flatForward = Vector3.new(forwardVec.X, 0, forwardVec.Z)
    if flatForward.Magnitude > 0.01 then
        flatForward = flatForward.Unit
    else
        flatForward = Vector3.new(0, 0, -1)
    end
    
    local castOrigin = rootPart and rootPart.Position or Vector3.new(104, 9, -56)
    local targetX = castOrigin.X + (flatForward.X * castDistance)
    local targetZ = castOrigin.Z + (flatForward.Z * castDistance)
    local waterLevelY = GetWaterLevel(Vector3.new(targetX, castOrigin.Y, targetZ))
    
    local throwGoal = Vector3.new(targetX, waterLevelY, targetZ)
    
    local success, throwResponse = pcall(function()
        return actionRemote:InvokeServer({ 
            Bait = "Common Fish Bait", 
            Action = "Throw", 
            Goal = throwGoal 
        })
    end)
    
    if not success or type(throwResponse) ~= "table" or not throwResponse.Accepted then
        pcall(function() actionRemote:InvokeServer({ Action = "Cancel" }) end)
        return true 
    end
    
    local sessionKey = throwResponse.SessionKey
    local actionKey = throwResponse.ActionKey

    local hookName = LocalPlayer.Name .. "'s hook"
    local hook = workspace.Effects:WaitForChild(hookName, 3)
    
    if not hook then return true end
    
    local surfacePosition = Vector3.new(throwGoal.X, waterLevelY, throwGoal.Z)
    
    hook:PivotTo(CFrame.new(surfacePosition))
    hook.AssemblyLinearVelocity = Vector3.zero
    
    local bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(0, 2000000000, 0)
    bp.Position = surfacePosition
    bp.Parent = hook
    
    local landSuccess, landedResponse = pcall(function()
        return actionRemote:InvokeServer({
            Action = "Landed",
            SessionKey = sessionKey,
            ActionKey = actionKey
        })
    end)
    
    if not landSuccess or type(landedResponse) ~= "table" or not landedResponse.Accepted then
        return true
    end
    
    if landedResponse.ActionKey then
        actionKey = landedResponse.ActionKey
    end
    
    local maxWait = 30 
    local waited = 0
    local fishBitten = false
    
    while waited < maxWait do
        if not (getgenv().FishmanState.Model.State.isFishing or getgenv().FishmanState.Model.State.isDeepSeaCatcher) then
            pcall(function() actionRemote:InvokeServer({ Action = "Cancel", SessionKey = sessionKey, ActionKey = actionKey }) end)
            if hook then hook:Destroy() end
            return true
        end
        
        if hook:GetAttribute("Caught") == true or hook:FindFirstChild("ReelLoop") then
            fishBitten = true
            break
        end
        task.wait(0.1)
        waited = waited + 0.1
    end
    
    if fishBitten then
        local isBeast = true
        if getgenv().FishmanState.Model.State.isDeepSeaCatcher and not getgenv().FishmanState.Model.State.isFishing then
            local beastDetected = false
            local bWaited = 0
            local initialSoundTime = nil
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if not getgenv().DSC_SoundCache then
                getgenv().DSC_SoundCache = {}
                local function onNewSound(child)
                    if child:IsA("Sound") and string.find(child.Name, "DeepSea") then
                        table.insert(getgenv().DSC_SoundCache, child)
                    end
                end
                getgenv().FishmanState.addConn(workspace.DescendantAdded:Connect(onNewSound))
                getgenv().FishmanState.addConn(game:GetService("SoundService").DescendantAdded:Connect(onNewSound))
                if LocalPlayer.Character then getgenv().FishmanState.addConn(LocalPlayer.Character.DescendantAdded:Connect(onNewSound)) end
                getgenv().FishmanState.addConn(LocalPlayer.CharacterAdded:Connect(function(char)
                    getgenv().FishmanState.addConn(char.DescendantAdded:Connect(onNewSound))
                end))
                if rootPart then
                    for _, child in ipairs(rootPart:GetChildren()) do onNewSound(child) end
                end
            end
            
            while getgenv().FishmanState._running and hook.Parent do
                if not (getgenv().FishmanState.Model.State.isFishing or getgenv().FishmanState.Model.State.isDeepSeaCatcher) then
                    pcall(function() actionRemote:InvokeServer({ Action = "Cancel", SessionKey = sessionKey, ActionKey = actionKey }) end)
                    if hook then hook:Destroy() end
                    return true
                end
                local beastSounds = {}
                for i = #getgenv().DSC_SoundCache, 1, -1 do
                    local s = getgenv().DSC_SoundCache[i]
                    if s.Parent then table.insert(beastSounds, s) else table.remove(getgenv().DSC_SoundCache, i) end
                end
                if rootPart then
                    for _, child in ipairs(rootPart:GetChildren()) do
                        if child:IsA("Sound") and child.Playing then
                            if not initialSoundTime and (child.Name == "Small" or child.Name == "Medium" or child.Name == "Large" or child.Name == "Giant") then
                                print("🐟 Initial sound detected:", child.Name, "- Waiting 0.3s for possible Beast sound...")
                                initialSoundTime = bWaited
                            end
                        end
                    end
                end
                for _, s in ipairs(beastSounds) do
                    if s.Playing and s.TimePosition < 3.0 then
                        print("🔥 BEAST SOUND DETECTED! Name:", s.Name)
                        beastDetected = true
                        break
                    end
                end
                
                if beastDetected then break end
                if initialSoundTime and (bWaited - initialSoundTime >= 0.3) then break end
                if bWaited >= 5.0 then break end
                
                task.wait(0.1)
                bWaited += 0.1
            end
            
            if not beastDetected then
                print("❌ No Megalodon detected. Cancelling normal fish.")
                isBeast = false
            else
                print("🔥 REELING IN THE BEAST! 🔥")
            end
        else
            local diffMult = hook:GetAttribute("MoveMultiplier")
            if diffMult == nil then
                task.wait(0.05)
                diffMult = hook:GetAttribute("MoveMultiplier") or 1.0
            end
            print("🐟 Fish caught! MoveMultiplier:", diffMult)
            
            if getgenv().FishmanState.Model.State.strictReel then
                if diffMult <= 1.0 then
                    print("⏩ Skipping fish: Multiplier (" .. tostring(diffMult) .. ") <= 1.0 (Strict Reel active)")
                    isBeast = false
                else
                    print("🔥 Reeling rare/legendary fish! Multiplier:", diffMult)
                end
            end
        end
        
        if isBeast then
            local w = 0
            while w < 5.6 do
                if not (getgenv().FishmanState.Model.State.isFishing or getgenv().FishmanState.Model.State.isDeepSeaCatcher) then
                    pcall(function() actionRemote:InvokeServer({ Action = "Cancel", SessionKey = sessionKey, ActionKey = actionKey }) end)
                    if hook then hook:Destroy() end
                    return true
                end
                task.wait(0.1)
                w += 0.1
            end
            
            local reelSuccess, reelResponse = pcall(function()
                return actionRemote:InvokeServer({
                    Action = "Reel",
                    SessionKey = sessionKey,
                    ActionKey = actionKey 
                })
            end)
            
            if reelSuccess and type(reelResponse) == "table" and reelResponse.ActionKey then
                actionKey = reelResponse.ActionKey
            end
            
            local retSuccess, retResponse = pcall(function()
                return actionRemote:InvokeServer({
                    Action = "HookReturning",
                    SessionKey = sessionKey,
                    ActionKey = actionKey
                })
            end)
            
            if retSuccess and type(retResponse) == "table" and retResponse.ActionKey then
                actionKey = retResponse.ActionKey
            end
            
            -- PHYSICALLY PULL THE HOOK BACK TO YOU (INSTANT)
            local char = LocalPlayer.Character
            if char and char.PrimaryPart and hook and hook.Parent then
                local targetPos = char.PrimaryPart.Position
                
                local existingBp = hook:FindFirstChildOfClass("BodyPosition")
                if existingBp then existingBp:Destroy() end
                hook.Anchored = true
                
                -- Instantly teleport the hook to your character
                hook:PivotTo(CFrame.new(targetPos))
                
                -- Wait just 1/10th of a second for the fish reward script to catch up
                task.wait()
            end
        else
            pcall(function()
                actionRemote:InvokeServer({ Action = "Reel", SessionKey = sessionKey, ActionKey = actionKey })
            end)
            task.wait()
            pcall(function()
                actionRemote:InvokeServer({ Action = "Cancel", SessionKey = sessionKey, ActionKey = actionKey })
            end)
            if hook then hook:Destroy() end
            return true
        end
    end
    
    if hook then hook:Destroy() end
    
    pcall(function()
        actionRemote:InvokeServer({
            Action = "Cancel",
            SessionKey = sessionKey,
            ActionKey = actionKey
        })
    end)
    
    return true
end

-- === MAIN LOOP ===
task.spawn(function()
    print("Auto-Fisher started without UI.")
    while getgenv().FishmanState._running do
        if (getgenv().FishmanState.Model.State.isFishing or getgenv().FishmanState.Model.State.isDeepSeaCatcher) and not getgenv().FishmanState.Model.State.isCurrentlyCrafting and not getgenv().FishmanState.Model.State.isCraftFlying then
            DoFishingCycle()
        end
        task.wait() -- Delay between casts
    end
end)
    
    -- ======================================================================
    -- ⏱️ BACKGROUND LOOPS
    -- ======================================================================
    task.spawn(function()
        while getgenv().FishmanState._running and task.wait(1) do
            if getgenv().FishmanState.isAFKModeActive then
                getgenv().FishmanState.secondsSinceLastInput += 1
                if getgenv().FishmanState.secondsSinceLastInput == 10 then
                    if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options then
                        if getgenv().FishmanState.Fluent.Options.T_Buy then getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(true) end
                        if getgenv().FishmanState.Fluent.Options.T_Sell then getgenv().FishmanState.Fluent.Options.T_Sell:SetValue(true) end
                        if getgenv().FishmanState.Fluent.Options.T_Craft then getgenv().FishmanState.Fluent.Options.T_Craft:SetValue(true) end
                        if getgenv().FishmanState.Fluent.Options.T_Travel then getgenv().FishmanState.Fluent.Options.T_Travel:SetValue(true) end
                        
                        -- Anti-Lag
                        if getgenv().FishmanState.Fluent.Options.T_AntiLag then getgenv().FishmanState.Fluent.Options.T_AntiLag:SetValue(true) else RunService:Set3dRenderingEnabled(false) end
                    else
                        getgenv().FishmanState.Model.State.autoBuy = true
                        getgenv().FishmanState.Model.State.autoSell = true
                        getgenv().FishmanState.Model.State.autoCraft = true
                        getgenv().FishmanState.Model.StartTraveling()
                        RunService:Set3dRenderingEnabled(false)
                    end
                    ActivatePotatoGraphics()
                    getgenv().FishmanState.Model.State.waitingForArrivalToFish = true
                end
            end
        end
    end)

    task.spawn(function()
        while getgenv().FishmanState._running and task.wait(3) do
            if not getgenv().FishmanState.Model.State.autoCraft or getgenv().FishmanState.Model.State.isCurrentlyCrafting then continue end
            local inventoryData = getgenv().FishmanState.Model.GetInventoryData()
            if not inventoryData then continue end
            
            -- Skip auto-craft if Legendary Fish Bait is already full at 300
            local currentLegBait = inventoryData["Legendary Fish Bait"] or inventoryData["Legendary Bait"] or 0
            if currentLegBait >= 300 then continue end
            
            local shouldCraft = false
            for _, legFish in ipairs(LEGENDARY_FISHES) do
                if (inventoryData[legFish] or 0) >= 40 then
                    shouldCraft = true
                    break
                end
            end
            
            if shouldCraft then
                print("[AutoCraft] 40 cap reached on a legendary fish! Auto-crafting all legendary fish...")
                getgenv().FishmanState.Model.ForceCraftAll()
            end
        end
    end)

    task.spawn(function() while getgenv().FishmanState._running and task.wait(2) do if getgenv().FishmanState.Model.State.autoBuy or getgenv().FishmanState.Model.State.isMegStackLoc or getgenv().FishmanState.Model.State.autoSell then getgenv().FishmanState.Model.CheckInventory() end end end)

    -- Auto-track hoverboard position to memory every 3 seconds to prevent StreamingEnabled drop-off
    task.spawn(function()
        while getgenv().FishmanState._running and task.wait(3) do
            local hb = getgenv().FishmanState.Model.FindHoverboard and getgenv().FishmanState.Model.FindHoverboard()
            if hb then
                local hbCFrame = hb:IsA("Model") and hb:GetPivot() or hb.CFrame
                getgenv().CachedHoverboardTailPos = (hbCFrame * CFrame.new(0, 3, 4)).Position
            end
        end
    end)

    -- Auto-return background loop
    task.spawn(function()
        while getgenv().FishmanState._running and task.wait(1) do
            if getgenv().FishmanState.Model.State.autoReturn and not getgenv().FishmanState.Model.State.isCraftFlying and not getgenv().FishmanState.Model.State.isAutoTraveling and not getgenv().FishmanState.Model.State.isRefillingMegBait and not getgenv().FishmanState.Model.State.isManualTraveling and not getgenv().FishmanState.Model.State.isCurrentlyCrafting then
                local character = LocalPlayer.Character
                local hum = character and character:FindFirstChild("Humanoid")
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hum and hum.SeatPart == nil and hrp then
                    local targetVector = nil
                    local hb = getgenv().FishmanState.Model.FindHoverboard and getgenv().FishmanState.Model.FindHoverboard()
                    if hb then
                        local hbCFrame = hb:IsA("Model") and hb:GetPivot() or hb.CFrame
                        targetVector = (hbCFrame * CFrame.new(0, 3, 4)).Position
                    elseif getgenv().FishmanState.Model.LoadHoverboardPos then
                        targetVector = getgenv().FishmanState.Model.LoadHoverboardPos()
                    end
                    
                    if targetVector and (hrp.Position - targetVector).Magnitude > 20 then
                        print("🚀 [Auto Return] Distance > 20 studs! Flying back to the hoverboard now...")
                        -- Trigger return!
                        local success = getgenv().FishmanState.Model.ReturnToShip()
                        
                        if success then 
                            print("✅ [Auto Return] Safely landed on the hoverboard platform!")
                            task.wait(1) 
                        end
                    end
                end
            end
        end
    end)

    getgenv().FishmanState.addConn(RunService.Heartbeat:Connect(function(dt)
        if getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isAutoTraveling then getgenv().FishmanState.Model.HandleMovement(dt) end
    end))
    
    local noclipCache = {}
    local lastCharacter = nil
    local descAddedConn = nil

    getgenv().FishmanState.addConn(RunService.Stepped:Connect(function()
        if not getgenv().FishmanState._running then return end
        if getgenv().FishmanState.Model.State.isAutoTraveling and getgenv().FishmanState.Model.State.travelStage == 1 then 
            local character = LocalPlayer.Character
            if character then
                if character ~= lastCharacter then
                    lastCharacter = character
                    table.clear(noclipCache)
                    if descAddedConn then
                        descAddedConn:Disconnect()
                        local idx = table.find(getgenv().FishmanState._connections, descAddedConn)
                        if idx then table.remove(getgenv().FishmanState._connections, idx) end
                    end
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then table.insert(noclipCache, part) end
                    end
                    descAddedConn = character.DescendantAdded:Connect(function(part)
                        if part:IsA("BasePart") then table.insert(noclipCache, part) end
                    end)
                    getgenv().FishmanState.addConn(descAddedConn)
                end
                for _, part in ipairs(noclipCache) do if part.CanCollide then part.CanCollide = false end end
            end
        end
    end))
    
    if inventoryObj then
        getgenv().FishmanState.addConn(inventoryObj:GetPropertyChangedSignal("Value"):Connect(function() getgenv().FishmanState.Model.CheckInventory() end))
    end
end

getgenv().FishmanState.ShutdownEverything = function()
    getgenv().FishmanState._running = false
    getgenv().FishmanState.disconnectAll()
    if not isLobby then
        getgenv().FishmanState.Model.DisableFlight()
    end
    if getgenv().DSC_SoundCache then getgenv().DSC_SoundCache = nil end
    if getgenv().StopAutofarm then
        pcall(getgenv().StopAutofarm)
    end
    getgenv().ToggleCyborgAutofarm = nil
    env.FishmanScriptServer = nil
    print("[Fishman] Successfully shut down.")
end
env.Fishman_StopPrevious = getgenv().FishmanState.ShutdownEverything

getgenv().FishmanState.targetFruits = {
    "Dragon", "Venom", "Mochi", "Soul", "Pika", "Buddha", "Magu", "Goro", "Goru", "Gura",
    "Hie", "Kage", "Mera", "Tori", "Pteranodon", "Smoke", "Yami", "Suna", "Yuki", "Ope", "Zushi", "Ito", "Paw"
}

getgenv().FishmanState.checkFruits = function(fruitList)
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not character or not backpack then return end
    
    local inventoryCounts = {}
    local foundAny = false
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local toolName = string.lower(tool.Name)
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    local isSpecial = false
                    if tool:GetAttribute("Category") == "Special" then
                        isSpecial = true
                    end
                    local attrs = tool:FindFirstChild("Attributes")
                    if attrs and attrs:FindFirstChild("Category") and attrs.Category.Value == "Special" then
                        isSpecial = true
                    end
                    
                    if isSpecial then
                        inventoryCounts[tool.Name] = (inventoryCounts[tool.Name] or 0) + 1
                        foundAny = true
                    end
                    break
                end
            end
        end
    end
    
    if foundAny then
        local lines = {}
        for name, count in pairs(inventoryCounts) do
            table.insert(lines, count .. "x " .. name)
        end
        local message = table.concat(lines, ", ")
        if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Fruits Found", Content = message, Duration = 5 }) end
    else
        if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Fruit Check", Content = "No target fruits found.", Duration = 3 }) end
    end
end

getgenv().FishmanState.isFruitAlreadyStored = function(fruitName)
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return false end
    local invGui = pGui:FindFirstChild("Inventory")
    if not invGui then return false end
    local main = invGui:FindFirstChild("Main")
    if not main then return false end
    local inv = main:FindFirstChild("Inventory")
    if not inv then return false end
    local list = inv:FindFirstChild("List")
    if not list then return false end

    for _, child in ipairs(list:GetChildren()) do
        if string.find(string.lower(child.Name), string.lower(fruitName)) then
            return true
        end
    end
    return false
end

getgenv().FishmanState.storeFruits = function(fruitList)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not character or not humanoid or not backpack then return end
    
    -- Check if we even have any target fruits before pausing
    local hasFruits = false
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and not tool:GetAttribute("StoreFailed") then
            local toolName = string.lower(tool.Name)
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    if getgenv().FishmanState.isFruitAlreadyStored(fruitName) then
                        break -- Already stored in PlayerGui.Inventory.Main.Inventory.List!
                    end
                    local isSpecial = false
                    if tool:GetAttribute("Category") == "Special" then
                        isSpecial = true
                    end
                    local attrs = tool:FindFirstChild("Attributes")
                    if attrs and attrs:FindFirstChild("Category") and attrs.Category.Value == "Special" then
                        isSpecial = true
                    end
                    
                    if isSpecial then
                        hasFruits = true
                    end
                    break
                end
            end
        end
    end
    
    if not hasFruits then return end -- No need to pause if no unstored fruits

    -- PAUSE FISHING/KILLING
    local tempSavedState = {}
    if getgenv().FishmanState.Model and getgenv().FishmanState.Model.State then
        tempSavedState = {
            isFishing = getgenv().FishmanState.Model.State.isFishing,
            autoBuy = getgenv().FishmanState.Model.State.autoBuy,
            autoSell = getgenv().FishmanState.Model.State.autoSell,
            isAutoTraveling = getgenv().FishmanState.Model.State.isAutoTraveling,
            autoCraft = getgenv().FishmanState.Model.State.autoCraft
        }
        
        -- Force stop them
        getgenv().FishmanState.Model.State.isFishing = false
        -- getgenv().FishmanState.Model.State.autoBuy = false
        getgenv().FishmanState.Model.State.autoSell = false
        getgenv().FishmanState.Model.State.isAutoTraveling = false
        getgenv().FishmanState.Model.State.autoCraft = false
        
        -- Update toggles visually
        if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options then
            if getgenv().FishmanState.Fluent.Options.T_Fish then getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(false) end
            -- if getgenv().FishmanState.Fluent.Options.T_Buy then getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(false) end
            if getgenv().FishmanState.Fluent.Options.T_Sell then getgenv().FishmanState.Fluent.Options.T_Sell:SetValue(false) end
            if getgenv().FishmanState.Fluent.Options.T_Travel then getgenv().FishmanState.Fluent.Options.T_Travel:SetValue(false) end
            if getgenv().FishmanState.Fluent.Options.T_Craft then getgenv().FishmanState.Fluent.Options.T_Craft:SetValue(false) end
        end
        
        -- Wait a moment for any current actions (like reeling) to finish
        task.wait(2)
        
        -- Unequip current tools (rod/sword) so we can equip fruits properly
        humanoid:UnequipTools()
        task.wait(0.5)
    end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if getgenv()._cancelStoreFruits then break end
        if tool:IsA("Tool") and not tool:GetAttribute("StoreFailed") then
            local toolName = string.lower(tool.Name)
            local isTargetFruit = false
            local matchedFruitName = nil
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    if getgenv().FishmanState.isFruitAlreadyStored(fruitName) then
                        if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Already Stored", Content = tool.Name .. " is already in storage! Skipping.", Duration = 3 }) end
                        break
                    end
                    local isSpecial = false
                    if tool:GetAttribute("Category") == "Special" then
                        isSpecial = true
                    end
                    local attrs = tool:FindFirstChild("Attributes")
                    if attrs and attrs:FindFirstChild("Category") and attrs.Category.Value == "Special" then
                        isSpecial = true
                    end
                    
                    if isSpecial then
                        isTargetFruit = true
                        matchedFruitName = fruitName
                    end
                    break
                end
            end
            
            if isTargetFruit and not getgenv().FishmanState.isFruitAlreadyStored(matchedFruitName) then
                humanoid:EquipTool(tool)
                task.wait(0.2)
                
                pcall(function()
                    ReplicatedStorage.Events.FruitStorage:InvokeServer(true)
                end)
                task.wait(0.5)
                
                if tool.Parent == character or tool.Parent == backpack then
                    humanoid:UnequipTools()
                    tool:SetAttribute("StoreFailed", true)
                    if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Storage Full", Content = "Couldn't store: " .. tool.Name .. " (kept in inventory)", Duration = 3 }) end
                else
                    if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Fruit Stored", Content = "Successfully stored: " .. tool.Name, Duration = 3 }) end
                end
                task.wait(0.5)
            end
        end
    end

    -- RESUME FISHING/KILLING
    if getgenv().FishmanState.Model and getgenv().FishmanState.Model.State then
        getgenv().FishmanState.Model.State.isFishing = tempSavedState.isFishing or false
        getgenv().FishmanState.Model.State.autoBuy = tempSavedState.autoBuy or false
        getgenv().FishmanState.Model.State.autoSell = tempSavedState.autoSell or false
        getgenv().FishmanState.Model.State.isAutoTraveling = tempSavedState.isAutoTraveling or false
        getgenv().FishmanState.Model.State.autoCraft = tempSavedState.autoCraft or false
        
        -- Update UI toggles visually to match restored state
        if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options then
            if getgenv().FishmanState.Fluent.Options.T_Fish then getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(getgenv().FishmanState.Model.State.isFishing) end
            if getgenv().FishmanState.Fluent.Options.T_Buy then getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(getgenv().FishmanState.Model.State.autoBuy) end
            if getgenv().FishmanState.Fluent.Options.T_Sell then getgenv().FishmanState.Fluent.Options.T_Sell:SetValue(getgenv().FishmanState.Model.State.autoSell) end
            if getgenv().FishmanState.Fluent.Options.T_Travel then getgenv().FishmanState.Fluent.Options.T_Travel:SetValue(getgenv().FishmanState.Model.State.isAutoTraveling) end
            if getgenv().FishmanState.Fluent.Options.T_Craft then getgenv().FishmanState.Fluent.Options.T_Craft:SetValue(getgenv().FishmanState.Model.State.autoCraft) end
        end

        if getgenv().FishmanState.Model.State.isAutoTraveling and getgenv().FishmanState.Model.StartTraveling then
            getgenv().FishmanState.Model.StartTraveling()
        end
    end
end

getgenv().FishmanState.dropFruits = function(fruitList)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not character or not humanoid or not backpack then return end
    
    -- Check if we even have any target fruits before pausing
    local hasFruits = false
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local toolName = string.lower(tool.Name)
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    local isSpecial = false
                    if tool:GetAttribute("Category") == "Special" then
                        isSpecial = true
                    end
                    local attrs = tool:FindFirstChild("Attributes")
                    if attrs and attrs:FindFirstChild("Category") and attrs.Category.Value == "Special" then
                        isSpecial = true
                    end
                    
                    if isSpecial then
                        hasFruits = true
                    end
                    break
                end
            end
        end
    end
    
    if not hasFruits then return end -- No need to pause if no fruits

    -- PAUSE FISHING/KILLING
    local tempSavedState = {}
    if getgenv().FishmanState.Model and getgenv().FishmanState.Model.State then
        tempSavedState = {
            isFishing = getgenv().FishmanState.Model.State.isFishing,
            autoBuy = getgenv().FishmanState.Model.State.autoBuy,
            autoSell = getgenv().FishmanState.Model.State.autoSell,
            isAutoTraveling = getgenv().FishmanState.Model.State.isAutoTraveling,
            autoCraft = getgenv().FishmanState.Model.State.autoCraft
        }
        
        -- Force stop them
        getgenv().FishmanState.Model.State.isFishing = false
        -- getgenv().FishmanState.Model.State.autoBuy = false
        getgenv().FishmanState.Model.State.autoSell = false
        getgenv().FishmanState.Model.State.isAutoTraveling = false
        getgenv().FishmanState.Model.State.autoCraft = false
        
        -- Update toggles visually
        if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options then
            if getgenv().FishmanState.Fluent.Options.T_Fish then getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(false) end
            -- if getgenv().FishmanState.Fluent.Options.T_Buy then getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(false) end
            if getgenv().FishmanState.Fluent.Options.T_Sell then getgenv().FishmanState.Fluent.Options.T_Sell:SetValue(false) end
            if getgenv().FishmanState.Fluent.Options.T_Travel then getgenv().FishmanState.Fluent.Options.T_Travel:SetValue(false) end
            if getgenv().FishmanState.Fluent.Options.T_Craft then getgenv().FishmanState.Fluent.Options.T_Craft:SetValue(false) end
        end
        
        -- Wait a moment for any current actions (like reeling) to finish
        task.wait(2)
        
        -- Unequip current tools (rod/sword) so we can equip fruits properly
        humanoid:UnequipTools()
        task.wait(0.5)
    end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if getgenv()._cancelDropFruits then break end
        if tool:IsA("Tool") then
            local toolName = string.lower(tool.Name)
            local isTargetFruit = false
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    local isSpecial = false
                    if tool:GetAttribute("Category") == "Special" then
                        isSpecial = true
                    end
                    local attrs = tool:FindFirstChild("Attributes")
                    if attrs and attrs:FindFirstChild("Category") and attrs.Category.Value == "Special" then
                        isSpecial = true
                    end
                    
                    if isSpecial then
                        isTargetFruit = true
                    end
                    break
                end
            end
            
            if isTargetFruit then
                humanoid:EquipTool(tool)
                task.wait(0.2)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
                if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Dropping Fruit", Content = "Dropped: " .. tool.Name, Duration = 3 }) end
                task.wait(0.5)
            end
        end
    end

    -- RESUME FISHING/KILLING
    if getgenv().FishmanState.Model and getgenv().FishmanState.Model.State then
        getgenv().FishmanState.Model.State.isFishing = tempSavedState.isFishing or false
        getgenv().FishmanState.Model.State.autoBuy = tempSavedState.autoBuy or false
        getgenv().FishmanState.Model.State.autoSell = tempSavedState.autoSell or false
        getgenv().FishmanState.Model.State.isAutoTraveling = tempSavedState.isAutoTraveling or false
        getgenv().FishmanState.Model.State.autoCraft = tempSavedState.autoCraft or false
        
        -- Update UI toggles visually to match restored state
        if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options then
            if getgenv().FishmanState.Fluent.Options.T_Fish then getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(getgenv().FishmanState.Model.State.isFishing) end
            if getgenv().FishmanState.Fluent.Options.T_Buy then getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(getgenv().FishmanState.Model.State.autoBuy) end
            if getgenv().FishmanState.Fluent.Options.T_Sell then getgenv().FishmanState.Fluent.Options.T_Sell:SetValue(getgenv().FishmanState.Model.State.autoSell) end
            if getgenv().FishmanState.Fluent.Options.T_Travel then getgenv().FishmanState.Fluent.Options.T_Travel:SetValue(getgenv().FishmanState.Model.State.isAutoTraveling) end
            if getgenv().FishmanState.Fluent.Options.T_Craft then getgenv().FishmanState.Fluent.Options.T_Craft:SetValue(getgenv().FishmanState.Model.State.autoCraft) end
        end

        if getgenv().FishmanState.Model.State.isAutoTraveling and getgenv().FishmanState.Model.StartTraveling then
            getgenv().FishmanState.Model.StartTraveling()
        end
    end
end

