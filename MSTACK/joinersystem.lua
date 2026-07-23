-- ======================================================================
-- 🛑 GLOBAL SETUP & DUPLICATE PREVENTION
-- ======================================================================
local env = getgenv and getgenv() or shared
if env.Fishman_StopPrevious then
    pcall(env.Fishman_StopPrevious)
end
if env.Fishman_DestroyUI then
    pcall(env.Fishman_DestroyUI)
end

env.FishmanScriptServer = game.JobId

local _running = true
local _connections = {}
local Tabs
local Fluent

local function addConn(conn)
    table.insert(_connections, conn)
    return conn
end

local function disconnectAll()
    for _, c in ipairs(_connections) do
        if c and c.Connected then c:Disconnect() end
    end
    table.clear(_connections)
end

print("--- [Fishman] Unified Script Starting ---")
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do 
    task.wait(1)
    LocalPlayer = Players.LocalPlayer 
end

local targetPlaceId = 1730877806
local isLobby = (game.PlaceId == targetPlaceId and game.PrivateServerId == "")
local GlobalMem = env

-- ======================================================================
-- ⚙️ CONFIGURATION SYSTEM
-- ======================================================================
local configFileName = "FishmanConfig_" .. tostring(LocalPlayer.UserId) .. ".json"

pcall(function()
    if isfile and readfile and isfile(configFileName) then
        local data = HttpService:JSONDecode(readfile(configFileName))
        if data then
            if GlobalMem.FishmanPSCode == nil then GlobalMem.FishmanPSCode = data.FishmanPSCode end
            if GlobalMem.FishmanDestination == nil then GlobalMem.FishmanDestination = data.FishmanDestination end
            if GlobalMem.FishmanAutoTeleport == nil then GlobalMem.FishmanAutoTeleport = data.FishmanAutoTeleport end
            if GlobalMem.FishmanAutoJoin == nil then GlobalMem.FishmanAutoJoin = data.FishmanAutoJoin end
            if GlobalMem.FishmanAutoReconnect == nil then GlobalMem.FishmanAutoReconnect = data.FishmanAutoReconnect end
            print("[Fishman] Loaded Config from file.")
        end
    end
end)

GlobalMem.FishmanPSCode = GlobalMem.FishmanPSCode or "qj1ttW4JG1"
GlobalMem.FishmanDestination = GlobalMem.FishmanDestination or "tradeHub" 
GlobalMem.FishmanAutoTeleport = GlobalMem.FishmanAutoTeleport or false 
GlobalMem.FishmanAutoJoin = GlobalMem.FishmanAutoJoin or false
if GlobalMem.FishmanAutoReconnect == nil then GlobalMem.FishmanAutoReconnect = true end

local function SaveConfig()
    pcall(function()
        if writefile then
            local data = {
                FishmanPSCode = GlobalMem.FishmanPSCode,
                FishmanDestination = GlobalMem.FishmanDestination,
                FishmanAutoTeleport = GlobalMem.FishmanAutoTeleport,
                FishmanAutoJoin = GlobalMem.FishmanAutoJoin,
                FishmanAutoReconnect = GlobalMem.FishmanAutoReconnect
            }
            writefile(configFileName, HttpService:JSONEncode(data))
        end
    end)
end

-- ======================================================================
-- 🔄 AUTO RECONNECT ENGINE
-- ======================================================================
addConn(GuiService.ErrorMessageChanged:Connect(function()
    if GlobalMem.FishmanAutoReconnect then
        task.spawn(function()
            while _running and task.wait(5) do
                pcall(function()
                    TeleportService:Teleport(targetPlaceId, LocalPlayer)
                end)
            end
        end)
    end
end))

-- ======================================================================
-- 🚀 TELEPORT MEMORY INJECTION
-- ======================================================================
local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/joinersystem.lua"
local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

local function UpdateTeleportMemory(willAutoTeleport)
    GlobalMem.FishmanAutoTeleport = willAutoTeleport
    SaveConfig()
    
    if not qot then return end
    
    local command = [[
        pcall(function()
            getgenv().FishmanPSCode = "]] .. GlobalMem.FishmanPSCode .. [["
            getgenv().FishmanDestination = "]] .. GlobalMem.FishmanDestination .. [["
            getgenv().FishmanAutoTeleport = ]] .. tostring(willAutoTeleport) .. [[
            
            task.spawn(function()
                task.wait(15)
                if getgenv().FishmanScriptServer ~= game.JobId then
                    loadstring(game:HttpGet("]] .. myScriptURL .. [["))()
                end
            end)
        end)
    ]]
    pcall(function() qot(command) end)
end

local function GetCurrentPSCode()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local settingsGui = playerGui:FindFirstChild("Settings")
        if settingsGui then
            local main = settingsGui:FindFirstChild("Main")
            if main then
                local codeLabel = main:FindFirstChild("Code")
                if codeLabel and codeLabel:IsA("TextLabel") or codeLabel:IsA("TextBox") then
                    return codeLabel.Text
                end
            end
        end
    end
    return ""
end

local function ActivatePotatoGraphics()
    if _G.PotatoGraphicsActive then return end
    _G.PotatoGraphicsActive = true
    
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.FogStart = 9e9

    settings().Rendering.QualityLevel = 1

    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CastShadow = false
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            pcall(function() v.BackSurface = "SmoothNoOutlines" end)
            pcall(function() v.BottomSurface = "SmoothNoOutlines" end)
            pcall(function() v.FrontSurface = "SmoothNoOutlines" end)
            pcall(function() v.LeftSurface = "SmoothNoOutlines" end)
            pcall(function() v.RightSurface = "SmoothNoOutlines" end)
            pcall(function() v.TopSurface = "SmoothNoOutlines" end)
        elseif v:IsA("Decal") then
            v.Transparency = 1
            v.Texture = ""
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        end
    end

    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("PostEffect") then
            v.Enabled = false
        end
    end

    addConn(workspace.DescendantAdded:Connect(function(child)
        task.spawn(function()
            if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            elseif child:IsA("BasePart") then
                child.CastShadow = false
            end
        end)
    end))
    
    if Fluent then Fluent:Notify({ Title = "Anti-Lag", Content = "Potato Graphics Active!", Duration = 3 }) end
    print("Anti-Lag: Active")
end

-- ======================================================================
-- 🎣 FISHING ENGINE CORE (Only initialized if NOT in lobby)
-- ======================================================================
local Model = { State = {} }
local shopEvent, buyableItems, sellEvent, questEvent, craftingRemote, Remote
local statsFolder, inventoryObj, peliObject
local cachedBaitItems = nil
local loadedAnimations = {}
local isAFKModeActive = false
local secondsSinceLastInput = 0
local craftHeartbeatConn = nil
local craftFlyTarget = nil

    local EVASION_DIRECTIONS = {
        Vector3.new(1, 0, 0),   -- 1. Slide Right
        Vector3.new(0, 1, 0)    -- 2. Climb Up (Only if cornered/trapped)
    }

    Model.State = {
        isFishing             = false,
        autoBuy               = false,
        autoSell              = false,
        isBuying              = false,
        isAutoTraveling       = false,
        travelStage           = 1,
        waypoint1             = Vector3.new(406.69, 48.32, -32.21),
        waypoint2             = Vector3.new(174.10, 10.32, -48.09),
        finalTarget           = Vector3.new(101.53, 9.31, -55.77),
        travelMessage         = "",
        autoCraft             = false,
        isCurrentlyCrafting   = false,
        waitingForArrivalToFish = false,
        isCraftFlying         = false,
        activeNavigation      = nil,
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
    function Model.EnableFlight()
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

    function Model.DisableFlight()
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if rootPart then
            local bg = rootPart:FindFirstChild("AutoTravel_Gyro")
            if bg then bg:Destroy() end
            local bv = rootPart:FindFirstChild("AutoTravel_Velocity")
            if bv then bv:Destroy() end
        end
        if humanoid then humanoid.PlatformStand = false end
    end
    
    function Model.NavigateTo(object, targetPosition, speed, arrivalDistance)
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

        noclipConnection = RunService.Stepped:Connect(function()
            if not navigator._isNavigating or navigator._isPaused then return end
            if object then
                for _, part in ipairs(object:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)

        connection = RunService.Heartbeat:Connect(function(deltaTime)
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
    
    function Model.HandleMovement(deltaTime)
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local cur = rootPart.Position
        
        local tgt
        if Model.State.travelStage == 1 then tgt = Model.State.waypoint1
        elseif Model.State.travelStage == 2 then tgt = Model.State.waypoint2
        else tgt = Model.State.finalTarget end
        
        local tgtY = tgt.Y
        local nextPoint
        local goingUp = (tgtY > cur.Y)

        if goingUp and math.abs(cur.Y - tgtY) > 1 then nextPoint = Vector3.new(cur.X, tgtY, cur.Z)
        elseif math.abs(cur.X - tgt.X) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, cur.Z)
        elseif math.abs(cur.Z - tgt.Z) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, tgt.Z)
        elseif not goingUp and math.abs(cur.Y - tgtY) > 1 then nextPoint = Vector3.new(tgt.X, tgtY, tgt.Z)
        else
            if Model.State.travelStage == 1 then
                Model.State.travelStage = 2
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.PlatformStand = false end
                return
            elseif Model.State.travelStage == 2 then
                Model.State.travelStage = 3
                return
            end
            
            Model.State.isAutoTraveling = false
            Model.DisableFlight()
            Model.State.travelMessage = "Arrived at Bait"
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
        if Model.State.travelStage > 1 and not goingUp then
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {LocalPlayer.Character}
            params.FilterType = Enum.RaycastFilterType.Exclude

            local floorY = tgtY
            local rayStart = Vector3.new(newX, cur.Y + 10, newZ)
            local remainingDist = 500
            
            while remainingDist > 0 do
                local res = workspace:Raycast(rayStart, Vector3.new(0, -remainingDist, 0), params)
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
    
    function Model.StartTraveling()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local pos = hrp.Position
        local d1 = (pos - Model.State.waypoint1).Magnitude
        local d2 = (pos - Model.State.waypoint2).Magnitude
        local d3 = (pos - Model.State.finalTarget).Magnitude

        if d3 < d2 and d3 < d1 then Model.State.travelStage = 3
        elseif d2 < d1 then Model.State.travelStage = 2
        else Model.State.travelStage = 1 end

        Model.State.travelMessage = "Traveling..."
        Model.State.isAutoTraveling = true
        Model.EnableFlight()
    end
    
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
        if not rootPart then return end
        
        Model.State.isCraftFlying = true
        local speed = Model.State.shipSpeed or 175 
        
        local function TweenTo(point)
            if not Model.State.isCraftFlying then return end
            local dist = (rootPart.Position - point).Magnitude
            if dist < 1 then return end
            
            local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(point) * rootPart.CFrame.Rotation})
            tween:Play()
            
            while tween.PlaybackState == Enum.PlaybackState.Playing do
                if not Model.State.autoCraft and not Model.State.isRefillingMegBait then 
                    tween:Cancel()
                    Model.State.isCraftFlying = false
                    break 
                end
                PlayGeppoEffect(character, rootPart)
                task.wait(0.1)
            end
        end
        
        local cur = rootPart.Position
        local upPoint = Vector3.new(cur.X, math.max(cur.Y, targetVector.Y) + 500, cur.Z)
        local overPoint = Vector3.new(targetVector.X, upPoint.Y, targetVector.Z)
        
        TweenTo(upPoint)
        TweenTo(overPoint)
        TweenTo(targetVector)
        
        Model.State.isCraftFlying = false
    end

    function Model.CraftFlyPath(pathTable)
        for _, targetPos in ipairs(pathTable) do 
            if not Model.State.autoCraft and not Model.State.isRefillingMegBait then break end
            CraftFlyToAndWait(targetPos) 
        end
    end
    
    function Model.ReturnToShip()
        local hoverboard = Model.FindHoverboard()
        local targetVector = nil
        
        if hoverboard then
            local hbCFrame = hoverboard:IsA("Model") and hoverboard:GetPivot() or hoverboard.CFrame
            targetVector = (hbCFrame * CFrame.new(0, 3, 4)).Position
            Model.SaveHoverboardPos(targetVector)
        elseif Model.LoadHoverboardPos() then
            targetVector = Model.LoadHoverboardPos()
        else
            return false
        end
        
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false end
        
        Model.State.isCraftFlying = true
        Model.DisableFlight()
        task.wait(0.1)
        Model.EnableFlight()
        local speed = Model.State.shipSpeed or 300 
        
        local function TweenTo(point)
            if not Model.State.isCraftFlying then return end
            local dist = (rootPart.Position - point).Magnitude
            if dist < 1 then return end
            
            local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(point) * rootPart.CFrame.Rotation})
            tween:Play()
            
            while tween.PlaybackState == Enum.PlaybackState.Playing do
                if not Model.State.isCraftFlying then 
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
        
        TweenTo(upPoint)
        TweenTo(overPoint)
        TweenTo(targetVector)
        
        Model.DisableFlight()
        Model.State.isCraftFlying = false
        return true
    end
    
    local function SafeInvokeQuest(chatState)
        pcall(function() questEvent:InvokeServer({ [1] = "npcChat", [2] = chatState }) end)
    end
    
    function Model.ExecuteLegendaryCraft(craftQueue)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local originalPos = hrp.Position
        
        Model.State.isFishing = false
        Model.State.autoBuy = false
        Model.State.autoSell = false
        Model.State.isAutoTraveling = false
        Model.State.travelMessage = "Crafting..."
        
        Model.DisableFlight()
        Model.UnequipRod()
        task.wait(3)
        if not Model.State.autoCraft then return end

        Model.EnableFlight()
        Model.CraftFlyPath({ Vector3.new(162.85, originalPos.Y, -55.34) })
        if not Model.State.autoCraft then Model.DisableFlight(); return end
        
        task.wait(0.5)
        SafeInvokeQuest(true)
        task.wait(0.5)
        
        for _, craftItem in ipairs(craftQueue) do
            if not Model.State.autoCraft then break end
            for i = 1, craftItem.Batches do
                if not Model.State.autoCraft then break end
                pcall(function()
                    craftingRemote:InvokeServer({ Count = 40, ExtraData = { ["Legendary Fish"] = craftItem.Name }, Method = "Craft", BlueprintItem = "Legendary Fish Bait" })
                end)
                task.wait(0.5)
            end
        end
        SafeInvokeQuest(false)
        task.wait(0.3)
        
        if not Model.State.autoCraft then Model.DisableFlight(); return end
        Model.CraftFlyPath({ originalPos })
        Model.DisableFlight()
        
        Model.EquipRod()
        Model.StartTraveling()
        Model.State.autoSell = true
        Model.State.waitingForArrivalToFish = true 
    end

    function Model.GetInventoryData()
        if inventoryObj then
            local ok, data = pcall(function() return HttpService:JSONDecode(inventoryObj.Value) end)
            if ok and type(data) == "table" then return data end
        end
        return nil
    end

    function Model.ForceCraftAll()
        if Model.State.isCurrentlyCrafting then return end
        
        local inventoryData = Model.GetInventoryData()
        if not inventoryData then return end
        
        local craftQueue = {}
        for _, legFish in ipairs(LEGENDARY_FISHES) do
            local fishCount = inventoryData[legFish] or 0
            if fishCount > 0 then
                table.insert(craftQueue, { Name = legFish, Count = fishCount })
            end
        end
        
        if #craftQueue == 0 then
            Fluent:Notify({ Title = "Craft All", Content = "No Legendary Fish to craft!", Duration = 3 })
            return
        end
        
        Model.State.isCurrentlyCrafting = true
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then Model.State.isCurrentlyCrafting = false; return end
        local originalPos = hrp.Position
        
        Model.State.travelMessage = "Force Crafting..."
        
        Model.DisableFlight()
        Model.UnequipRod()
        task.wait(1)
        
        Model.EnableFlight()
        
        -- Temporarily hook `craftFlyTarget` check bypass for ForceCraftAll since we don't rely on `autoCraft` variable
        local wasAutoCraft = Model.State.autoCraft
        Model.State.autoCraft = true 
        
        Model.CraftFlyPath({ Vector3.new(162.85, originalPos.Y, -55.34) })
        task.wait(0.5)
        SafeInvokeQuest(true)
        task.wait(0.5)
        
        for _, craftItem in ipairs(craftQueue) do
            local remaining = craftItem.Count
            while remaining > 0 do
                local batch = math.min(remaining, 40)
                pcall(function()
                    craftingRemote:InvokeServer({ Count = batch, ExtraData = { ["Legendary Fish"] = craftItem.Name }, Method = "Craft", BlueprintItem = "Legendary Fish Bait" })
                end)
                remaining = remaining - batch
                task.wait(0.5)
            end
        end
        
        SafeInvokeQuest(false)
        task.wait(0.3)
        Model.CraftFlyPath({ originalPos })
        
        Model.State.autoCraft = wasAutoCraft
        
        Model.DisableFlight()
        Model.EquipRod()
        Model.State.isCurrentlyCrafting = false
        Model.State.travelMessage = ""
        Fluent:Notify({ Title = "Craft All", Content = "Finished crafting all legendary fishes!", Duration = 3 })
    end
    
    -- ======================================================================
    -- 🎣 FISHING & INVENTORY MANAGEMENT
    -- ======================================================================
    function Model.EquipRod()
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

    function Model.UnequipRod()
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
    
    function Model.BuyNearestBait()
        if Model.State.isBuying then return end
        Model.State.isBuying = true
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
            addConn(buyableItems.ChildAdded:Connect(function(item)
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
        Model.State.isBuying = false
    end

    local hoverboardSaveFile = "FISHMAN23_HoverboardPos_" .. LocalPlayer.Name .. ".json"
    
    function Model.SaveHoverboardPos(pos)
        getgenv().CachedHoverboardTailPos = pos
        if writefile and HttpService then
            local data = { X = pos.X, Y = pos.Y, Z = pos.Z }
            pcall(function()
                writefile(hoverboardSaveFile, HttpService:JSONEncode(data))
            end)
        end
    end
    
    function Model.LoadHoverboardPos()
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

    function Model.FindHoverboard()
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

    function Model.RefillMegBait()
        if Model.State.isRefillingMegBait then return end
        Model.State.isRefillingMegBait = true
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then Model.State.isRefillingMegBait = false; return end
        local originalPos = hrp.Position
        
        Model.State.isAutoTraveling = false
        Model.DisableFlight()
        Model.UnequipRod()
        task.wait(1)
        
        Model.EnableFlight()
        
        local wasAutoCraft = Model.State.autoCraft
        Model.State.autoCraft = true 
        
        print("🚀 [MegStackLoc] 0 Common Fish Bait detected! Flying to island (-6760, 27, 9191)...")
        Model.CraftFlyPath({ Vector3.new(-6760, 27, 9191) })
        
        print("⏳ [MegStackLoc] Arrived! Waiting 5 seconds for your macro to buy baits...")
        task.wait(5)
        
        print("🚀 [MegStackLoc] Flying back to fishing spot...")
        local hoverboard = Model.FindHoverboard()
        if hoverboard then
            local hbCFrame = hoverboard:IsA("Model") and hoverboard:GetPivot() or hoverboard.CFrame
            local tailPos = (hbCFrame * CFrame.new(0, 3, 4)).Position
            Model.SaveHoverboardPos(tailPos)
            Model.CraftFlyPath({ tailPos })
        elseif Model.LoadHoverboardPos() then
            Model.CraftFlyPath({ Model.LoadHoverboardPos() })
        else
            Model.CraftFlyPath({ originalPos })
        end
        
        Model.State.autoCraft = wasAutoCraft
        Model.DisableFlight()
        Model.EquipRod()
        
        print("✅ [MegStackLoc] Returned to fishing spot. Resuming operations.")
        Model.State.isRefillingMegBait = false
    end

    function Model.CheckInventory()
        local inventoryData = Model.GetInventoryData()
        if not inventoryData then return end
        
        if Model.State.isMegStackLoc and not Model.State.isRefillingMegBait then
            if (inventoryData["Common Fish Bait"] or 0) <= 0 then
                task.spawn(Model.RefillMegBait)
            end
        end

        if Model.State.autoBuy and not Model.State.isBuying then
            if (inventoryData[BAIT_NAME] or 0) < MIN_BAIT then Model.BuyNearestBait() end
        end

        if Model.State.autoSell then
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
    function Model.countMegalodons()
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
    
    function Model.DoFishingCycle()
        local currentPeli = peliObject and peliObject.Value or 0
        local hookName = LocalPlayer.Name .. "'s hook"
        if workspace.Effects:FindFirstChild(hookName) then 
            pcall(function() Remote:InvokeServer({ Action = "Cancel" }) end)
            task.wait(0.5) 
            return 
        end
        local character = LocalPlayer.Character
        if not character then return end

        Model.EquipRod()
        task.wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local throwTrack = playAnimation(THROW_ANIMATION_ID)
        if throwTrack then task.delay(0.8, function() throwTrack:Stop(0.15) end) end

        local throwGoal = rootPart.Position + (rootPart.CFrame.LookVector * 40) + Vector3.new(0, 2, 0)
        pcall(function() Remote:InvokeServer({ Bait = BAIT_NAME, Action = "Throw", Goal = throwGoal }) end)

        local hook = workspace.Effects:WaitForChild(hookName, 3)
        if hook then
            local maxWait, waited = 15, 0
            while waited < maxWait do
                if not (Model.State.isFishing or Model.State.isDeepSeaCatcher) then return end
                if hook:GetAttribute("Caught") == true or hook:FindFirstChild("ReelLoop") then
                    if Model.State.isDeepSeaCatcher then
                        local beastDetected = false
                        local bWaited = 0
                        local initialSoundTime = nil
                        
                        -- Global Passive Listener (Zero Stutter)
                        -- Only runs ONCE per game session!
                        if not getgenv().DSC_SoundCache then
                            getgenv().DSC_SoundCache = {}
                            
                            local function onNewSound(child)
                                if child:IsA("Sound") and string.find(child.Name, "DeepSea") then
                                    table.insert(getgenv().DSC_SoundCache, child)
                                end
                            end
                            
                            -- Listen for when the game clones the sound from ReplicatedStorage!
                            workspace.DescendantAdded:Connect(onNewSound)
                            game:GetService("SoundService").DescendantAdded:Connect(onNewSound)
                            
                            if LocalPlayer.Character then
                                LocalPlayer.Character.DescendantAdded:Connect(onNewSound)
                            end
                            LocalPlayer.CharacterAdded:Connect(function(char)
                                char.DescendantAdded:Connect(onNewSound)
                            end)
                            
                            -- Grab any that might already exist right now (just once, instantly)
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root then
                                for _, child in ipairs(root:GetChildren()) do
                                    onNewSound(child)
                                end
                            end
                        end
                        
                        while _running and hook.Parent do
                            -- Quickly copy valid sounds from our zero-lag cache
                            local beastSounds = {}
                            for i = #getgenv().DSC_SoundCache, 1, -1 do
                                local s = getgenv().DSC_SoundCache[i]
                                if s.Parent then
                                    table.insert(beastSounds, s)
                                else
                                    table.remove(getgenv().DSC_SoundCache, i) -- Clean up deleted sounds
                                end
                            end
                            -- 1. Check for initial sound in character
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
                            
                            -- 2. Check ALL beast sounds globally
                            for _, s in ipairs(beastSounds) do
                                -- A fresh bite sound will have just started (TimePosition < 3.0)
                                -- Lingering roars from previous catches will be > 7.0s because the reel animation takes 6s!
                                if s.Playing and s.TimePosition < 3.0 then
                                    local parentName = s.Parent and s.Parent.Name or "nil"
                                    print("🔥 BEAST SOUND DETECTED! Name:", s.Name, "Time:", string.format("%.1f", s.TimePosition), "Parent:", parentName)
                                    beastDetected = true
                                    break
                                end
                            end
                            
                            if beastDetected then break end
                            
                            if initialSoundTime and (bWaited - initialSoundTime >= 0.3) then
                                print("⏱️ 0.3s passed with no Beast sound. Safe to cancel.")
                                break
                            end
                            if bWaited >= 5.0 then
                                break -- Hard safety timeout
                            end
                            
                            task.wait(0.1)
                            bWaited += 0.1
                        end
                        
                        if beastDetected then
                            print("🔥 REELING IN THE BEAST! 🔥")
                            local reelTrack = playAnimation(REEL_ANIMATION_ID)
                            task.wait(6)
                            pcall(function() Remote:InvokeServer({ Action = "Reel" }) end)
                            if reelTrack then reelTrack:Stop(0.2) end
                        else
                            print("❌ No Megalodon detected. Cancelling normal fish to save bait.")
                            pcall(function() Remote:InvokeServer({ Action = "Reel" }) end)
                            task.wait()
                            pcall(function() Remote:InvokeServer({ Action = "Cancel" }) end)
                        end
                        break
                    else
                        local diffMult = hook:GetAttribute("MoveMultiplier") or 1.0
                        print("Fish caught! MoveMultiplier:", diffMult)
                        currentPeli = peliObject and peliObject.Value or 0
                        local skipFish
                        if Model.State.strictReel then
                            skipFish = (diffMult <= 1.0)
                        else
                            skipFish = (currentPeli >= MAX_PELI) and (diffMult < 1.2) or (diffMult < 0.9)
                        end

                        if skipFish then
                            pcall(function() Remote:InvokeServer({ Action = "Reel" }) end)
                            task.wait()
                            pcall(function() Remote:InvokeServer({ Action = "Cancel" }) end)
                        else
                            local reelTrack = playAnimation(REEL_ANIMATION_ID)
                            task.wait(6)
                            pcall(function() Remote:InvokeServer({ Action = "Reel" }) end)
                            if reelTrack then reelTrack:Stop(0.2) end
                        end
                        break
                    end
                end
                task.wait(0.1); waited += 0.1
            end
        end
        pcall(function() Remote:InvokeServer({ Action = "Cancel" }) end)
        task.wait()
    end
    
    -- ======================================================================
    -- ⏱️ BACKGROUND LOOPS
    -- ======================================================================
    task.spawn(function()
        while _running and task.wait(1) do
            if isAFKModeActive then
                secondsSinceLastInput += 1
                if secondsSinceLastInput == 10 then
                    if Fluent and Fluent.Options then
                        if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(true) end
                        if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(true) end
                        if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(true) end
                        if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(true) end
                        
                        -- Anti-Lag
                        if Fluent.Options.T_AntiLag then Fluent.Options.T_AntiLag:SetValue(true) else RunService:Set3dRenderingEnabled(false) end
                    else
                        Model.State.autoBuy = true
                        Model.State.autoSell = true
                        Model.State.autoCraft = true
                        Model.StartTraveling()
                        RunService:Set3dRenderingEnabled(false)
                    end
                    ActivatePotatoGraphics()
                    Model.State.waitingForArrivalToFish = true
                end
            end
        end
    end)

    task.spawn(function()
        while _running and task.wait(3) do
            if not Model.State.autoCraft or Model.State.isCurrentlyCrafting then continue end
            local inventoryData = Model.GetInventoryData()
            if not inventoryData then continue end
            local craftQueue = {}
            local totalBatches = 0
            for _, legFish in ipairs(LEGENDARY_FISHES) do
                local fishCount = inventoryData[legFish] or 0
                if fishCount >= 40 then
                    local timesToCraft = math.floor(fishCount / 40)
                    table.insert(craftQueue, { Name = legFish, Batches = timesToCraft })
                    totalBatches += timesToCraft
                end
            end
            if totalBatches > 0 then
                Model.State.isCurrentlyCrafting = true
                Model.ExecuteLegendaryCraft(craftQueue)
                Model.State.isCurrentlyCrafting = false
            end
        end
    end)

    task.spawn(function() while _running and task.wait(2) do if Model.State.autoBuy or Model.State.isMegStackLoc or Model.State.autoSell then Model.CheckInventory() end end end)
    task.spawn(function() while _running and task.wait() do if Model.State.isFishing or Model.State.isDeepSeaCatcher then Model.DoFishingCycle() end end end)

    -- Auto-track hoverboard position to memory every 3 seconds to prevent StreamingEnabled drop-off
    task.spawn(function()
        while _running and task.wait(3) do
            local hb = Model.FindHoverboard and Model.FindHoverboard()
            if hb then
                local hbCFrame = hb:IsA("Model") and hb:GetPivot() or hb.CFrame
                getgenv().CachedHoverboardTailPos = (hbCFrame * CFrame.new(0, 3, 4)).Position
            end
        end
    end)

    -- Auto-return background loop
    task.spawn(function()
        while _running and task.wait(1) do
            if Model.State.autoReturn and not Model.State.isCraftFlying and not Model.State.isAutoTraveling and not Model.State.isRefillingMegBait and not Model.State.isCurrentlyCrafting then
                local character = LocalPlayer.Character
                local hum = character and character:FindFirstChild("Humanoid")
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hum and hum.SeatPart == nil and hrp then
                    local targetVector = nil
                    local hb = Model.FindHoverboard and Model.FindHoverboard()
                    if hb then
                        local hbCFrame = hb:IsA("Model") and hb:GetPivot() or hb.CFrame
                        targetVector = (hbCFrame * CFrame.new(0, 3, 4)).Position
                    elseif Model.LoadHoverboardPos then
                        targetVector = Model.LoadHoverboardPos()
                    end
                    
                    if targetVector and (hrp.Position - targetVector).Magnitude > 20 then
                        print("🚀 [Auto Return] Distance > 20 studs! Flying back to the hoverboard now...")
                        -- Temporarily turn off Meg Stack if it was on
                        local wasMegStackOn = Model.State.megStack
                        if wasMegStackOn and Fluent and Fluent.Options and Fluent.Options.T_MegStack then
                            Fluent.Options.T_MegStack:SetValue(false)
                        end
                        
                        -- Trigger return!
                        local success = Model.ReturnToShip()
                        
                        if success then 
                            print("✅ [Auto Return] Safely landed on the hoverboard platform!")
                            -- Turn Meg Stack back on since we are safe on the hoverboard
                            if wasMegStackOn and Fluent and Fluent.Options and Fluent.Options.T_MegStack then
                                Fluent.Options.T_MegStack:SetValue(true)
                            end
                            task.wait(1) 
                        end
                    end
                end
            end
        end
    end)

    addConn(RunService.Heartbeat:Connect(function(dt)
        if _running and Model.State.isAutoTraveling then Model.HandleMovement(dt) end
    end))
    
    local noclipCache = {}
    local lastCharacter = nil
    local descAddedConn = nil

    addConn(RunService.Stepped:Connect(function()
        if not _running then return end
        if Model.State.isAutoTraveling and Model.State.travelStage == 1 then 
            local character = LocalPlayer.Character
            if character then
                if character ~= lastCharacter then
                    lastCharacter = character
                    table.clear(noclipCache)
                    if descAddedConn then descAddedConn:Disconnect() end
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then table.insert(noclipCache, part) end
                    end
                    descAddedConn = character.DescendantAdded:Connect(function(part)
                        if part:IsA("BasePart") then table.insert(noclipCache, part) end
                    end)
                    addConn(descAddedConn)
                end
                for _, part in ipairs(noclipCache) do if part.CanCollide then part.CanCollide = false end end
            end
        end
    end))
    
    if inventoryObj then
        addConn(inventoryObj:GetPropertyChangedSignal("Value"):Connect(function() Model.CheckInventory() end))
    end
end

local function ShutdownEverything()
    _running = false
    disconnectAll()
    if not isLobby then
        Model.DisableFlight()
    end
    env.FishmanScriptServer = nil
    print("[Fishman] Successfully shut down.")
end
env.Fishman_StopPrevious = ShutdownEverything

local targetFruits = {
    "Dragon", "Venom", "Mochi", "Soul", "Pika", "Buddha", "Magu", "Goro", "Goru", "Gura",
    "Hie", "Kage", "Mera", "Tori", "Pteranodon", "Smoke", "Yami", "Suna", "Yuki", "Ope", "Zushi", "Ito", "Paw"
}

local function checkFruits(fruitList)
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
        if Fluent then Fluent:Notify({ Title = "Fruits Found", Content = message, Duration = 5 }) end
    else
        if Fluent then Fluent:Notify({ Title = "Fruit Check", Content = "No target fruits found.", Duration = 3 }) end
    end
end

local function storeFruits(fruitList)
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
    if Model and Model.State then
        tempSavedState = {
            isFishing = Model.State.isFishing,
            autoBuy = Model.State.autoBuy,
            autoSell = Model.State.autoSell,
            isAutoTraveling = Model.State.isAutoTraveling,
            autoCraft = Model.State.autoCraft,
            deepSea = (Fluent and Fluent.Options and Fluent.Options.T_DeepSea) and Fluent.Options.T_DeepSea.Value or false,
            megStack = (Fluent and Fluent.Options and Fluent.Options.T_MegStack) and Fluent.Options.T_MegStack.Value or false,
            megStackLoc = (Fluent and Fluent.Options and Fluent.Options.T_MegStackLoc) and Fluent.Options.T_MegStackLoc.Value or false
        }
        
        -- Force stop them
        Model.State.isFishing = false
        Model.State.autoBuy = false
        Model.State.autoSell = false
        Model.State.isAutoTraveling = false
        Model.State.autoCraft = false
        
        -- Update toggles visually
        if Fluent and Fluent.Options then
            if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(false) end
            if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(false) end
            if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(false) end
            if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(false) end
            if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(false) end
            if Fluent.Options.T_DeepSea then Fluent.Options.T_DeepSea:SetValue(false) end
            if Fluent.Options.T_MegStack then Fluent.Options.T_MegStack:SetValue(false) end
            if Fluent.Options.T_MegStackLoc then Fluent.Options.T_MegStackLoc:SetValue(false) end
        end
        
        -- Wait a moment for any current actions (like reeling) to finish
        task.wait(2)
        
        -- Unequip current tools (rod/sword) so we can equip fruits properly
        humanoid:UnequipTools()
        task.wait(0.5)
    end
    
    for _, tool in pairs(backpack:GetChildren()) do
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
                
                ReplicatedStorage.Events.FruitStorage:InvokeServer(true)
                task.wait(0.5)
                
                if tool.Parent == character or tool.Parent == backpack then
                    humanoid:UnequipTools()
                    if Fluent then Fluent:Notify({ Title = "Storage Full", Content = "Couldn't store: " .. tool.Name .. " (kept in inventory)", Duration = 3 }) end
                else
                    if Fluent then Fluent:Notify({ Title = "Fruit Stored", Content = "Successfully stored: " .. tool.Name, Duration = 3 }) end
                end
                task.wait(0.5)
            end
        end
    end

    -- RESUME FISHING/KILLING
    if Model and Model.State then
        Model.State.isFishing = tempSavedState.isFishing or false
        Model.State.autoBuy = tempSavedState.autoBuy or false
        Model.State.autoSell = tempSavedState.autoSell or false
        Model.State.isAutoTraveling = tempSavedState.isAutoTraveling or false
        Model.State.autoCraft = tempSavedState.autoCraft or false
        
        -- Update UI toggles visually to match restored state
        if Fluent and Fluent.Options then
            if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(Model.State.isFishing) end
            if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(Model.State.autoBuy) end
            if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(Model.State.autoSell) end
            if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(Model.State.isAutoTraveling) end
            if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(Model.State.autoCraft) end
            if Fluent.Options.T_DeepSea then Fluent.Options.T_DeepSea:SetValue(tempSavedState.deepSea) end
            if Fluent.Options.T_MegStack then Fluent.Options.T_MegStack:SetValue(tempSavedState.megStack) end
            if Fluent.Options.T_MegStackLoc then Fluent.Options.T_MegStackLoc:SetValue(tempSavedState.megStackLoc) end
        end

        if Model.State.isAutoTraveling and Model.StartTraveling then
            Model.StartTraveling()
        end
    end
end

local function dropFruits(fruitList)
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
    if Model and Model.State then
        tempSavedState = {
            isFishing = Model.State.isFishing,
            autoBuy = Model.State.autoBuy,
            autoSell = Model.State.autoSell,
            isAutoTraveling = Model.State.isAutoTraveling,
            autoCraft = Model.State.autoCraft,
            deepSea = (Fluent and Fluent.Options and Fluent.Options.T_DeepSea) and Fluent.Options.T_DeepSea.Value or false,
            megStack = (Fluent and Fluent.Options and Fluent.Options.T_MegStack) and Fluent.Options.T_MegStack.Value or false,
            megStackLoc = (Fluent and Fluent.Options and Fluent.Options.T_MegStackLoc) and Fluent.Options.T_MegStackLoc.Value or false
        }
        
        -- Force stop them
        Model.State.isFishing = false
        Model.State.autoBuy = false
        Model.State.autoSell = false
        Model.State.isAutoTraveling = false
        Model.State.autoCraft = false
        
        -- Update toggles visually
        if Fluent and Fluent.Options then
            if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(false) end
            if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(false) end
            if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(false) end
            if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(false) end
            if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(false) end
            if Fluent.Options.T_DeepSea then Fluent.Options.T_DeepSea:SetValue(false) end
            if Fluent.Options.T_MegStack then Fluent.Options.T_MegStack:SetValue(false) end
            if Fluent.Options.T_MegStackLoc then Fluent.Options.T_MegStackLoc:SetValue(false) end
        end
        
        -- Wait a moment for any current actions (like reeling) to finish
        task.wait(2)
        
        -- Unequip current tools (rod/sword) so we can equip fruits properly
        humanoid:UnequipTools()
        task.wait(0.5)
    end
    
    for _, tool in pairs(backpack:GetChildren()) do
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
                if Fluent then Fluent:Notify({ Title = "Dropping Fruit", Content = "Dropped: " .. tool.Name, Duration = 3 }) end
                task.wait(0.5)
            end
        end
    end

    -- RESUME FISHING/KILLING
    if Model and Model.State then
        Model.State.isFishing = tempSavedState.isFishing or false
        Model.State.autoBuy = tempSavedState.autoBuy or false
        Model.State.autoSell = tempSavedState.autoSell or false
        Model.State.isAutoTraveling = tempSavedState.isAutoTraveling or false
        Model.State.autoCraft = tempSavedState.autoCraft or false
        
        -- Update UI toggles visually to match restored state
        if Fluent and Fluent.Options then
            if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(Model.State.isFishing) end
            if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(Model.State.autoBuy) end
            if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(Model.State.autoSell) end
            if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(Model.State.isAutoTraveling) end
            if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(Model.State.autoCraft) end
            if Fluent.Options.T_DeepSea then Fluent.Options.T_DeepSea:SetValue(tempSavedState.deepSea) end
            if Fluent.Options.T_MegStack then Fluent.Options.T_MegStack:SetValue(tempSavedState.megStack) end
            if Fluent.Options.T_MegStackLoc then Fluent.Options.T_MegStackLoc:SetValue(tempSavedState.megStackLoc) end
        end

        if Model.State.isAutoTraveling and Model.StartTraveling then
            Model.StartTraveling()
        end
    end
end


-- ======================================================================
-- 🎨 FLUENT UI INTEGRATION
-- ======================================================================
Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🐟 Fishman Hub",
    SubTitle = "Unified Auto-Fisher v1.0.1",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 350),
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightShift
})

env.Fishman_DestroyUI = function()
    pcall(function()
        if Window and Window.Destroy then Window:Destroy() end
    end)
end

-- Make the entire UI draggable by clicking anywhere
task.spawn(function()
    pcall(function()
        task.wait(1)
        local coreGui = game:GetService("CoreGui")
        local mainFrame
        
        for _, gui in pairs(coreGui:GetDescendants()) do
            if gui:IsA("Frame") and gui.Size == UDim2.fromOffset(500, 350) then
                mainFrame = gui
                break
            end
        end

        if mainFrame then
            local dragging, dragInput, dragStart, startPos

            local function update(input)
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end

            mainFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = mainFrame.Position

                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end)

            mainFrame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    dragInput = input
                end
            end)

            addConn(UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    update(input)
                end
            end))
        end
    end)
end)

-- Prevent game from detecting UI actions or internal UI errors (Anti-Cheat bypass)
pcall(function()
    if getconnections then
        for _, conn in pairs(getconnections(game:GetService("UserInputService").WindowFocusReleased)) do
            conn:Disable()
        end
        for _, conn in pairs(getconnections(game:GetService("LogService").MessageOut)) do
            conn:Disable()
        end
        for _, conn in pairs(getconnections(game:GetService("ScriptContext").Error)) do
            conn:Disable()
        end
    end
    game:GetService("ContextActionService"):UnbindAction("FluentMinimize")
end)

Tabs = {
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "plane" }),
    Navigation = Window:AddTab({ Title = "Navigation", Icon = "map" }),
    Fishing = Window:AddTab({ Title = "Fishing", Icon = "anchor" }),
    Autofarm = Window:AddTab({ Title = "Autofarm", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- ======================================================================
-- 🗺️ TELEPORT TAB UI
-- ======================================================================
    Tabs.Teleport:AddInput("Input", {
        Title = "Private Server Code",
        Default = GlobalMem.FishmanPSCode,
        Placeholder = "Enter PS Code",
        Numeric = false,
        Finished = false,
        Callback = function(Value)
            GlobalMem.FishmanPSCode = Value
            SaveConfig()
        end
    })

    Tabs.Teleport:AddDropdown("Dropdown", {
        Title = "Destination",
        Values = {"fishHub", "tradeHub", "Second Sea", "Lobby"},
        Multi = false,
        Default = (table.find({"fishHub", "tradeHub", "Second Sea", "Lobby"}, GlobalMem.FishmanDestination) or 2),
        Callback = function(Value)
            GlobalMem.FishmanDestination = Value
            SaveConfig()
        end
    })

    Tabs.Teleport:AddButton({
        Title = "🚀 Teleport Now!",
        Description = "Teleports you to the selected destination.",
        Callback = function()
            GlobalMem.FishmanAutoTeleport = true
            SaveConfig()
            
            if isLobby then
                if GlobalMem.FishmanPSCode ~= "" then
                    task.spawn(function()
                        local events = ReplicatedStorage:WaitForChild("Events", 9e9)
                        local reserved = events:WaitForChild("reserved", 9e9)
                        pcall(function() reserved:InvokeServer(GlobalMem.FishmanPSCode) end)
                    end)
                    task.wait(5) 
                end
                
                local confirmArgs = { [1] = GlobalMem.FishmanDestination }
                pcall(function()
                    if GlobalMem.FishmanDestination == "Lobby" then
                        TeleportService:Teleport(targetPlaceId, LocalPlayer)
                    else
                        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 20)
                        local chooseType = playerGui:WaitForChild("chooseType", 20)
                        local frame = chooseType:WaitForChild("Frame", 20)
                        local remoteEvent = frame:WaitForChild("RemoteEvent", 20)
                        remoteEvent:FireServer(unpack(confirmArgs))
                    end
                end)
            else
                TeleportService:Teleport(targetPlaceId, LocalPlayer)
            end
        end
    })

    Tabs.Teleport:AddButton({
        Title = "🏠 Return to Base of Operations",
        Description = "Instantly teleports you to tradeHub in qj1ttW4JG1.",
        Callback = function()
            GlobalMem.FishmanPSCode = "qj1ttW4JG1"
            GlobalMem.FishmanDestination = "tradeHub"
            GlobalMem.FishmanAutoTeleport = true
            SaveConfig()
            
            -- Update UI visually
            if Fluent.Options.Input then Fluent.Options.Input:SetValue("qj1ttW4JG1") end
            if Fluent.Options.Dropdown then Fluent.Options.Dropdown:SetValue("tradeHub") end

            Fluent:Notify({ Title = "Routing to Base", Content = "Initiating emergency warp...", Duration = 3 })
            
            if isLobby then
                task.spawn(function()
                    local events = ReplicatedStorage:WaitForChild("Events", 9e9)
                    local reserved = events:WaitForChild("reserved", 9e9)
                    pcall(function() reserved:InvokeServer("qj1ttW4JG1") end)
                    
                    task.wait(5)
                    
                    local confirmArgs = { [1] = "tradeHub" }
                    pcall(function()
                        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 20)
                        local chooseType = playerGui:WaitForChild("chooseType", 20)
                        local frame = chooseType:WaitForChild("Frame", 20)
                        local remoteEvent = frame:WaitForChild("RemoteEvent", 20)
                        remoteEvent:FireServer(unpack(confirmArgs))
                    end)
                end)
            else
                TeleportService:Teleport(targetPlaceId, LocalPlayer)
            end
        end
    })

    -- Check if we should automatically route
    if isLobby then
        local destCode = GlobalMem.FishmanPSCode
        local destPlace = GlobalMem.FishmanDestination
        
        if GlobalMem.FishmanAutoTeleport then
            Fluent:Notify({ Title = "Auto-Teleporting", Content = "Routing to chosen destination in 3s...", Duration = 3 })
            GlobalMem.FishmanAutoTeleport = false
            SaveConfig()
        else
            Fluent:Notify({ Title = "Base of Operations", Content = "Routing to Trade Hub in 3s...", Duration = 3 })
            destCode = "qj1ttW4JG1"
            destPlace = "tradeHub"
        end
        
        task.spawn(function()
            task.wait(3)
            
            if destCode ~= "" then
                task.spawn(function()
                    local events = ReplicatedStorage:WaitForChild("Events", 9e9)
                    local reserved = events:WaitForChild("reserved", 9e9)
                    pcall(function() reserved:InvokeServer(destCode) end)
                end)
                task.wait(5) 
            end
            
            local confirmArgs = { [1] = destPlace }
            pcall(function()
                local playerGui = LocalPlayer:WaitForChild("PlayerGui", 20)
                local chooseType = playerGui:WaitForChild("chooseType", 20)
                local frame = chooseType:WaitForChild("Frame", 20)
                local remoteEvent = frame:WaitForChild("RemoteEvent", 20)
                remoteEvent:FireServer(unpack(confirmArgs))
            end)
        end)
    end

-- ======================================================================
-- 🚀 HOVERBOARD UI
-- ======================================================================

Tabs.Teleport:AddInput("I_HoverHeight", {
    Title = "Flight Altitude",
    Default = "400",
    Placeholder = "Enter Altitude...",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local height = tonumber(Value) or 400
        getgenv().HoverboardTargetHeight = height
        if getgenv().HoverboardController and getgenv().HoverboardController.SetHeightValue then
            getgenv().HoverboardController.SetHeightValue(height)
        end
    end
})

local function EnsureHoverboardLoaded()
    if not getgenv().HoverboardController then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/hoverboardfloat.lua?t="..tostring(tick())))()
        end)
        task.wait(1)
        if getgenv().HoverboardController and getgenv().HoverboardTargetHeight then
            getgenv().HoverboardController.SetHeightValue(getgenv().HoverboardTargetHeight)
        end
    end
end

Tabs.Teleport:AddButton({
    Title = "🚀 Set Flight Height",
    Description = "Lifts your hoverboard to the target altitude.",
    Callback = function()
        print("[Hub] 'Set Flight Height' clicked!")
        EnsureHoverboardLoaded()
        if getgenv().HoverboardController and getgenv().HoverboardController.SetHeight then
            print("[Hub] Calling HoverboardController.SetHeight()...")
            getgenv().HoverboardController.SetHeight()
        else
            print("[Hub] ERROR: HoverboardController.SetHeight not found!")
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "🛳️ Auto Spawn Ship",
    Description = "Flies to spawn, spawns hoverboard, and sets flight height.",
    Callback = function()
        print("[Hub] 'Auto Spawn Ship' clicked!")
        EnsureHoverboardLoaded()
        if getgenv().HoverboardController and getgenv().HoverboardController.AutoSpawn then
            print("[Hub] Calling HoverboardController.AutoSpawn()...")
            getgenv().HoverboardController.AutoSpawn()
        else
            print("[Hub] ERROR: HoverboardController.AutoSpawn not found!")
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "⬇️ Reset to Normal",
    Description = "Restores normal hoverboard physics.",
    Callback = function()
        print("[Hub] 'Reset to Normal' clicked!")
        EnsureHoverboardLoaded()
        if getgenv().HoverboardController and getgenv().HoverboardController.Reset then
            print("[Hub] Calling HoverboardController.Reset()...")
            getgenv().HoverboardController.Reset()
        else
            print("[Hub] ERROR: HoverboardController.Reset not found!")
        end
    end
})

-- ======================================================================
-- 🗺️ NAVIGATION TAB UI
-- ======================================================================

    local islandNames = {}
    local islandPositions = {}
    
    local function refreshIslands()
        table.clear(islandNames)
        table.clear(islandPositions)
        local guider = game.ReplicatedStorage:FindFirstChild("CompassGuider")
        if guider then
            for _, island in ipairs(guider:GetChildren()) do
                table.insert(islandNames, island.Name)
                islandPositions[island.Name] = island.Value
            end
        end
        if #islandNames == 0 then table.insert(islandNames, "None") end
    end
    refreshIslands()

    local selectedIslandPos = nil

    local D_Island = Tabs.Navigation:AddDropdown("D_Island", {
        Title = "Select Island",
        Values = islandNames,
        Multi = false,
        Default = islandNames[1],
        Callback = function(Value)
            selectedIslandPos = islandPositions[Value]
        end
    })
    
    Tabs.Navigation:AddButton({
        Title = "🔄 Refresh Islands",
        Description = "Refreshes the island list if CompassGuider was slow to load.",
        Callback = function()
            refreshIslands()
            D_Island:SetValues(islandNames)
            Fluent:Notify({ Title = "Refreshed", Content = "Island list updated.", Duration = 3 })
        end
    })
    
    local flightStatus = Tabs.Navigation:AddParagraph({ Title = "Flight Status", Content = "Idle" })
    
    Tabs.Navigation:AddButton({
        Title = "🛫 Start Flight",
        Description = "Begins advanced auto-navigation to the selected island.",
        Callback = function()
            local character = LocalPlayer.Character
            if not character or not character.PrimaryPart then return end
            
            if Model.State.activeNavigation and Model.State.activeNavigation._isNavigating then
                Fluent:Notify({ Title = "Already Flying", Content = "Cancel or Pause current flight first.", Duration = 3 })
                return
            end
            
            if not selectedIslandPos then
                Fluent:Notify({ Title = "No Island", Content = "Please select a valid island first.", Duration = 3 })
                return
            end
            
            Model.State.activeNavigation = Model.NavigateTo(character, selectedIslandPos, 90, 20)
            
            task.spawn(function()
                while Model.State.activeNavigation and Model.State.activeNavigation._isNavigating do
                    local nav = Model.State.activeNavigation
                    if nav._isPaused then
                        flightStatus:SetDesc("Paused (" .. tostring(nav.Distance) .. " studs)")
                    elseif nav._roboTarget then
                        flightStatus:SetDesc("Lock: Robo! (" .. tostring(nav.Distance) .. " studs)")
                    else
                        flightStatus:SetDesc("Flying... (" .. tostring(nav.Distance) .. " studs)")
                    end
                    task.wait(0.1)
                end
                flightStatus:SetDesc("Idle")
            end)
        end
    })

    Tabs.Navigation:AddButton({
        Title = "⏸️ Pause / Resume Flight",
        Description = "Toggles the current flight state.",
        Callback = function()
            if Model.State.activeNavigation and Model.State.activeNavigation._isNavigating then
                local isPaused = Model.State.activeNavigation:TogglePause()
                if isPaused then
                    Fluent:Notify({ Title = "Paused", Content = "Flight paused.", Duration = 3 })
                else
                    Fluent:Notify({ Title = "Resumed", Content = "Flight resumed.", Duration = 3 })
                end
            end
        end
    })

    Tabs.Navigation:AddButton({
        Title = "🛑 Cancel Flight",
        Description = "Immediately stops the current flight.",
        Callback = function()
            if Model.State.activeNavigation and Model.State.activeNavigation._isNavigating then
                Model.State.activeNavigation:Cancel()
                Model.State.activeNavigation = nil
                flightStatus:SetDesc("Idle")
                Fluent:Notify({ Title = "Cancelled", Content = "Flight cancelled.", Duration = 3 })
            end
        end
    })

    Tabs.Navigation:AddToggle("T_IslandESP", { Title = "Islands ESP", Default = false, Callback = function(Value) 
        Model.State.isIslandESP = Value
        if Value then
            task.spawn(function()
                while _running and Model.State.isIslandESP do
                    local islandsFolder = workspace:FindFirstChild("Islands")
                    if islandsFolder then
                        for _, island in ipairs(islandsFolder:GetChildren()) do
                            if island:IsA("Model") or island:IsA("BasePart") then
                                local rootPart = island:IsA("Model") and (island.PrimaryPart or island:FindFirstChildWhichIsA("BasePart")) or island
                                if rootPart then
                                    local espName = "IslandESP_" .. island.Name
                                    if not rootPart:FindFirstChild(espName) then
                                        local bgui = Instance.new("BillboardGui")
                                        bgui.Name = espName
                                        bgui.AlwaysOnTop = true
                                        bgui.Size = UDim2.new(0, 100, 0, 50)
                                        bgui.StudsOffset = Vector3.new(0, 50, 0)
                                        
                                        local txt = Instance.new("TextLabel")
                                        txt.Size = UDim2.new(1, 0, 1, 0)
                                        txt.BackgroundTransparency = 1
                                        txt.Text = island.Name
                                        txt.TextColor3 = Color3.fromRGB(0, 255, 255)
                                        txt.TextStrokeTransparency = 0
                                        txt.TextScaled = true
                                        txt.Parent = bgui
                                        
                                        bgui.Parent = rootPart
                                        
                                        if not island:FindFirstChild("IslandESP_HL") then
                                            local hl = Instance.new("Highlight")
                                            hl.Name = "IslandESP_HL"
                                            hl.FillColor = Color3.fromRGB(0, 255, 255)
                                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                            hl.FillTransparency = 0.5
                                            hl.Parent = island
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(2)
                end
                
                local islandsFolder = workspace:FindFirstChild("Islands")
                if islandsFolder then
                    for _, island in ipairs(islandsFolder:GetChildren()) do
                        local rootPart = island:IsA("Model") and (island.PrimaryPart or island:FindFirstChildWhichIsA("BasePart")) or island
                        if rootPart then
                            local bgui = rootPart:FindFirstChild("IslandESP_" .. island.Name)
                            if bgui then bgui:Destroy() end
                        end
                        local hl = island:FindFirstChild("IslandESP_HL")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        else
            local islandsFolder = workspace:FindFirstChild("Islands")
            if islandsFolder then
                for _, island in ipairs(islandsFolder:GetChildren()) do
                    local rootPart = island:IsA("Model") and (island.PrimaryPart or island:FindFirstChildWhichIsA("BasePart")) or island
                    if rootPart then
                        local bgui = rootPart:FindFirstChild("IslandESP_" .. island.Name)
                        if bgui then bgui:Destroy() end
                    end
                    local hl = island:FindFirstChild("IslandESP_HL")
                    if hl then hl:Destroy() end
                end
            end
        end
    end })

    Tabs.Navigation:AddToggle("T_FruitESP", { Title = "Fruit ESP", Default = false, Callback = function(Value) 
        Model.State.isFruitESP = Value
        local targetFruits = {
            "Dragon", "Venom", "Mochi", "Soul", "Pika", "Buddha", "Magu", "Goro", "Goru",
            "Hie", "Kage", "Mera", "Tori", "Pteranodon", "Smoke", "Yami", "Suna", "Yuki", "Ope", "Zushi", "Ito", "Paw"
        }
        
        local function isTarget(objName)
            local lowerName = string.lower(objName)
            for _, fName in ipairs(targetFruits) do
                if string.find(lowerName, string.lower(fName)) then
                    return true
                end
            end
            return false
        end

        if Value then
            task.spawn(function()
                while _running and Model.State.isFruitESP do
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if (obj:IsA("Tool") or obj:IsA("Model")) and isTarget(obj.Name) then
                            local rootPart = (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or (obj:IsA("Tool") and obj:FindFirstChild("Handle"))
                            if rootPart then
                                local espName = "FruitESP_" .. obj.Name
                                if not rootPart:FindFirstChild(espName) then
                                    local bgui = Instance.new("BillboardGui")
                                    bgui.Name = espName
                                    bgui.AlwaysOnTop = true
                                    bgui.Size = UDim2.new(0, 100, 0, 50)
                                    bgui.StudsOffset = Vector3.new(0, 5, 0)
                                    
                                    local txt = Instance.new("TextLabel")
                                    txt.Size = UDim2.new(1, 0, 1, 0)
                                    txt.BackgroundTransparency = 1
                                    txt.Text = obj.Name
                                    txt.TextColor3 = Color3.fromRGB(255, 0, 255)
                                    txt.TextStrokeTransparency = 0
                                    txt.TextScaled = true
                                    txt.Parent = bgui
                                    
                                    bgui.Parent = rootPart
                                    
                                    if not obj:FindFirstChild("FruitESP_HL") then
                                        local hl = Instance.new("Highlight")
                                        hl.Name = "FruitESP_HL"
                                        hl.FillColor = Color3.fromRGB(255, 0, 255)
                                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                        hl.FillTransparency = 0.5
                                        hl.Parent = obj
                                    end
                                end
                            end
                        end
                    end
                    task.wait(2)
                end
                
                for _, obj in ipairs(workspace:GetChildren()) do
                    if (obj:IsA("Tool") or obj:IsA("Model")) and isTarget(obj.Name) then
                        local rootPart = (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or (obj:IsA("Tool") and obj:FindFirstChild("Handle"))
                        if rootPart then
                            local bgui = rootPart:FindFirstChild("FruitESP_" .. obj.Name)
                            if bgui then bgui:Destroy() end
                        end
                        local hl = obj:FindFirstChild("FruitESP_HL")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        else
            for _, obj in ipairs(workspace:GetChildren()) do
                if (obj:IsA("Tool") or obj:IsA("Model")) and isTarget(obj.Name) then
                    local rootPart = (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or (obj:IsA("Tool") and obj:FindFirstChild("Handle"))
                    if rootPart then
                        local bgui = rootPart:FindFirstChild("FruitESP_" .. obj.Name)
                        if bgui then bgui:Destroy() end
                    end
                    local hl = obj:FindFirstChild("FruitESP_HL")
                    if hl then hl:Destroy() end
                end
            end
        end
    end })

-- ======================================================================
-- 🎣 FISHING TAB UI
-- ======================================================================
    Tabs.Fishing:AddToggle("T_Fish", { Title = "Auto Fish", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot fish in Lobby!", Duration = 3 }); Fluent.Options.T_Fish:SetValue(false) end return end
        Model.State.isFishing = Value 
    end })
    Tabs.Fishing:AddToggle("T_DeepSea", { Title = "Deep Sea Catcher (ONLY Beasts)", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot fish in Lobby!", Duration = 3 }); Fluent.Options.T_DeepSea:SetValue(false) end return end
        task.spawn(function()
            if Value then
                print("triggering title: \"Skilled Fisherman\"")
                local args = {
                    "Skilled Fisherman"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args))
            end
        end)
        Model.State.isDeepSeaCatcher = Value 
    end })
    
    Tabs.Fishing:AddToggle("T_MegStack", { Title = "Megalodon Stack (Wait 10, Kill)", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot stack in Lobby!", Duration = 3 }); Fluent.Options.T_MegStack:SetValue(false) end return end
        Model.State.isMegStacking = Value
        if Value then
            if Fluent.Options.T_DeepSea then Fluent.Options.T_DeepSea:SetValue(true) end
            if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(true) end
            if Fluent.Options.T_MegStackLoc then Fluent.Options.T_MegStackLoc:SetValue(true) end
            print("🌊 [MegStack] Meg stack starting now! Enabling deep sea catcher for 10 megalodons.")
            task.spawn(function()
                while Model.State.isMegStacking do
                    local megCount = Model.countMegalodons()
                    if megCount >= 10 then
                        print("🔥 [MegStack] 10 Megalodons reached! Disabling fishing and automatically toggling Cyborg Autofarm ON...")
                        if Fluent.Options.T_DeepSea.Value == true then
                            Fluent.Options.T_DeepSea:SetValue(false)
                        end
                        
                        if Fluent.Options.T_CyborgAuto then
                            Fluent.Options.T_CyborgAuto:SetValue(true)
                        end
                        
                        while Model.countMegalodons() > 0 and Model.State.isMegStacking do
                            task.wait(1)
                        end
                        
                        print("✅ [MegStack] Stack cleared! Toggling Cyborg Autofarm OFF and resuming fishing...")
                        
                        if Fluent.Options.T_CyborgAuto then
                            Fluent.Options.T_CyborgAuto:SetValue(false)
                        end
                        
                        if Model.State.isMegStacking then
                            Fluent.Options.T_DeepSea:SetValue(true)
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            print("🛑 [MegStack] Stacking aborted. Shutting down deep sea catcher.")
            if Fluent.Options.T_DeepSea.Value == true then
                Fluent.Options.T_DeepSea:SetValue(false)
            end
        end
    end })
    
    Tabs.Fishing:AddToggle("T_MegStackLoc", { Title = "Meg Stack Location (Auto Refill)", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot use in Lobby!", Duration = 3 }); Fluent.Options.T_MegStackLoc:SetValue(false) end return end
        Model.State.isMegStackLoc = Value 
    end })
    
    local manualTravelInitialized = false
    Tabs.Fishing:AddToggle("T_ManualMegStackLoc", { Title = "Manual Meg Stack Travel", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot use in Lobby!", Duration = 3 }); Fluent.Options.T_ManualMegStackLoc:SetValue(false) end return end
        
        if Value then
            manualTravelInitialized = true
            task.spawn(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then getgenv().CachedOriginalPos = hrp.Position end
                
                Model.State.isAutoTraveling = false
                Model.DisableFlight()
                if Model.UnequipRod then Model.UnequipRod() end
                task.wait(1)
                
                Model.State.isRefillingMegBait = true -- REQUIRED for flight loop
                Model.EnableFlight()
                Fluent:Notify({ Title = "Manual Travel", Content = "Flying to Meg Stack Island...", Duration = 3 })
                Model.CraftFlyPath({ Vector3.new(-6760, 27, 9191) })
                Model.State.isRefillingMegBait = false
                
                Model.DisableFlight()
                Fluent:Notify({ Title = "Manual Travel", Content = "Arrived at Meg Stack Island!", Duration = 3 })
            end)
        else
            if not manualTravelInitialized then return end
            task.spawn(function()
                Model.State.isRefillingMegBait = true -- REQUIRED for flight loop
                Model.EnableFlight()
                Fluent:Notify({ Title = "Manual Travel", Content = "Flying back...", Duration = 3 })
                
                local hoverboard = Model.FindHoverboard and Model.FindHoverboard()
                if hoverboard then
                    local hbCFrame = hoverboard:IsA("Model") and hoverboard:GetPivot() or hoverboard.CFrame
                    local tailPos = (hbCFrame * CFrame.new(0, 3, 4)).Position
                    Model.CraftFlyPath({ tailPos })
                elseif getgenv().CachedOriginalPos then
                    Model.CraftFlyPath({ getgenv().CachedOriginalPos })
                end
                
                Model.State.isRefillingMegBait = false
                Model.DisableFlight()
                if Model.EquipRod then Model.EquipRod() end
                Fluent:Notify({ Title = "Manual Travel", Content = "Returned successfully!", Duration = 3 })
            end)
        end
    end })
    
    Tabs.Fishing:AddToggle("T_HoverboardESP", { Title = "Ship ESP", Default = false, Callback = function(Value) 
        Model.State.isHoverboardESP = Value 
        if Value then
            task.spawn(function()
                while _running and Model.State.isHoverboardESP do
                    local shipsFolder = workspace:FindFirstChild("Ships")
                    if shipsFolder then
                        local myShip = shipsFolder:FindFirstChild(LocalPlayer.Name .. "Ship")
                        if myShip and myShip:IsA("Model") then
                            if not myShip:FindFirstChild("HoverESP_Highlight") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "HoverESP_Highlight"
                                hl.FillColor = Color3.fromRGB(0, 255, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.5
                                hl.Parent = myShip
                            end
                        end
                    end
                    task.wait(1)
                end
                local shipsFolder = workspace:FindFirstChild("Ships")
                if shipsFolder then
                    local myShip = shipsFolder:FindFirstChild(LocalPlayer.Name .. "Ship")
                    if myShip then
                        local hl = myShip:FindFirstChild("HoverESP_Highlight")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        else
            local shipsFolder = workspace:FindFirstChild("Ships")
            if shipsFolder then
                local myShip = shipsFolder:FindFirstChild(LocalPlayer.Name .. "Ship")
                if myShip then
                    local hl = myShip:FindFirstChild("HoverESP_Highlight")
                    if hl then hl:Destroy() end
                end
            end
        end
    end })
    
    Tabs.Fishing:AddToggle("T_MegESP", { Title = "Megalodon ESP", Default = false, Callback = function(Value) 
        Model.State.isMegESP = Value 
        if Value then
            task.spawn(function()
                while _running and Model.State.isMegESP do
                    local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Env")}
                    for _, folder in ipairs(folders) do
                        if folder then
                            for _, child in ipairs(folder:GetChildren()) do
                                if child.Name == "Megalodon" and child:FindFirstChild("HumanoidRootPart") then
                                    if not child:FindFirstChild("MegESP_Highlight") then
                                        local hl = Instance.new("Highlight")
                                        hl.Name = "MegESP_Highlight"
                                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                        hl.FillTransparency = 0.5
                                        hl.Parent = child
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
                local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Env")}
                for _, folder in ipairs(folders) do
                    if folder then
                        for _, child in ipairs(folder:GetChildren()) do
                            if child.Name == "Megalodon" then
                                local hl = child:FindFirstChild("MegESP_Highlight")
                                if hl then hl:Destroy() end
                            end
                        end
                    end
                end
            end)
        else
            local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Env")}
            for _, folder in ipairs(folders) do
                if folder then
                    for _, child in ipairs(folder:GetChildren()) do
                        if child.Name == "Megalodon" then
                            local hl = child:FindFirstChild("MegESP_Highlight")
                            if hl then hl:Destroy() end
                        end
                    end
                end
            end
        end
    end })
    
    Tabs.Fishing:AddButton({
        Title = "Return to Hoverboard",
        Description = "Uses Geppo + BV to manually fly back to your hoverboard",
        Callback = function()
            if isLobby then Fluent:Notify({ Title = "Error", Content = "Cannot travel in Lobby!", Duration = 3 }); return end
            task.spawn(function()
                local success = Model.ReturnToShip()
                if success then
                    print("🚀 [ReturnToShip] Successfully arrived at hoverboard!")
                else
                    Fluent:Notify({ Title = "Error", Content = "No Hoverboard detected in workspace!", Duration = 3 })
                end
            end)
        end
    })

    Tabs.Fishing:AddToggle("T_AutoReturn", { 
        Title = "Auto Return to Hoverboard", 
        Description = "Automatically flies back to your hoverboard if you fall off.",
        Default = false, 
        Callback = function(Value) 
            Model.State.autoReturn = Value 
        end 
    })

    Tabs.Fishing:AddSlider("S_ShipSpeed", {
        Title = "Return To Ship Speed",
        Description = "Adjusts flight speed (300 is recommended)",
        Default = 90,
        Min = 50,
        Max = 1000,
        Rounding = 0,
        Callback = function(Value)
            Model.State.shipSpeed = Value
        end
    })

    Tabs.Fishing:AddToggle("T_StrictReel", { Title = "Only Reel > 1.0 Multiplier", Default = false, Callback = function(Value) 
        Model.State.strictReel = Value 
    end })
    Tabs.Fishing:AddToggle("T_Buy", { Title = "Auto Buy Bait", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot buy in Lobby!", Duration = 3 }); Fluent.Options.T_Buy:SetValue(false) end return end
        Model.State.autoBuy = Value; if Value then Model.CheckInventory() end 
    end })
    Tabs.Fishing:AddToggle("T_Sell", { Title = "Auto Sell Fish", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot sell in Lobby!", Duration = 3 }); Fluent.Options.T_Sell:SetValue(false) end return end
        Model.State.autoSell = Value; if Value then Model.CheckInventory() end 
    end })
    Tabs.Fishing:AddToggle("T_Travel", { Title = "Travel to Bait", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot travel in Lobby!", Duration = 3 }); Fluent.Options.T_Travel:SetValue(false) end return end
        if Value then Model.StartTraveling() else Model.State.isAutoTraveling = false; if Model.DisableFlight then Model.DisableFlight() end; Model.State.travelMessage = "" end 
    end })
    Tabs.Fishing:AddToggle("T_Craft", { Title = "Auto Craft Legendary Bait", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot craft in Lobby!", Duration = 3 }); Fluent.Options.T_Craft:SetValue(false) end return end
        Model.State.autoCraft = Value 
    end })
    Tabs.Fishing:AddButton({
        Title = "🔨 Craft All Legendary Fish Now",
        Description = "Instantly crafts all legendary fishes in your inventory into bait.",
        Callback = function()
            if isLobby then
                Fluent:Notify({ Title = "Error", Content = "Cannot craft in Lobby!", Duration = 3 })
                return
            end
            task.spawn(Model.ForceCraftAll)
        end
    })
    Tabs.Fishing:AddToggle("T_AFK", { Title = "AFK Mode (Auto-start after 10s)", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "AFK Mode requires Fishing server!", Duration = 3 }); Fluent.Options.T_AFK:SetValue(false) end return end
        isAFKModeActive = Value; secondsSinceLastInput = 0 
    end })

    Tabs.Fishing:AddButton({
        Title = "Check Fruits",
        Description = "Check your inventory for target fruits.",
        Callback = function() checkFruits(targetFruits) end
    })
    
    Tabs.Fishing:AddButton({
        Title = "Store Fruits",
        Description = "Store target fruits (keeps in inventory if full).",
        Callback = function() storeFruits(targetFruits) end
    })
    
    Tabs.Fishing:AddButton({
        Title = "Drop Fruits",
        Description = "Force drop all target fruits.",
        Callback = function() dropFruits(targetFruits) end
    })
    
    local autoStoreEnabled = false
    Tabs.Fishing:AddToggle("T_AutoStoreFruit", { 
        Title = "Auto Store Fruit (10 Minutes)", 
        Default = false, 
        Callback = function(Value)
            autoStoreEnabled = Value
            if autoStoreEnabled then
                task.spawn(function()
                    while autoStoreEnabled do
                        storeFruits(targetFruits)
                        task.wait(600)
                    end
                end)
            end
        end 
    })

    -- Status Monitor
    local StatusPara = Tabs.Fishing:AddParagraph({ Title = "Status", Content = "Idle" })
    local statusParts = {}
    task.spawn(function()
        while _running and task.wait(1) do
            table.clear(statusParts)
            if Model.State.isFishing then table.insert(statusParts, "Fishing") end
            if Model.State.autoBuy then table.insert(statusParts, "Buying") end
            if Model.State.autoSell then table.insert(statusParts, "Selling") end
            if Model.State.autoCraft then table.insert(statusParts,  Model.State.isCurrentlyCrafting and "Crafting" or "Craft ON") end
            if isAFKModeActive then table.insert(statusParts, "[AFK ON]") end

            if Model.State.isAutoTraveling or Model.State.travelMessage ~= "" then
                StatusPara:SetDesc("Status: " .. Model.State.travelMessage)
                if Model.State.travelMessage == "Arrived at Bait" and Model.State.waitingForArrivalToFish then
                    Model.State.waitingForArrivalToFish = false
                    if Fluent and Fluent.Options and Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(true) end -- Automatically turn on fishing toggle in UI
                end
            else
                StatusPara:SetDesc(#statusParts > 0 and ("Active: " .. table.concat(statusParts, " ")) or "Idle")
            end
        end
    end)
    
    if GetCurrentPSCode() == "qj1ttW4JG1" and not isLobby then
        Fluent:Notify({ Title = "Detection", Content = "Target Server qj1ttW4JG1 Detected.", Duration = 5 })
    end

-- ======================================================================
-- 🤖 AUTOFARM TAB UI
-- ======================================================================
Tabs.Autofarm:AddToggle("T_CyborgAuto", { 
    Title = "Toggle Cyborg Autofarm", 
    Default = false, 
    Callback = function(Value)
        task.spawn(function()
            if Value then
                print("triggering title: \"Megalodon Slayer\"")
                local args = {
                    "Megalodon Slayer"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args))
            end
        end)

        if not getgenv().ToggleCyborgAutofarm then
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/protov4_nofactory.lua"))()
            end)
            task.wait(1)
        end
        if getgenv().ToggleCyborgAutofarm then
            getgenv().ToggleCyborgAutofarm(Value)
        end
    end 
})

Tabs.Autofarm:AddButton({                   
    Title = "Load MeleeFactory",
    Description = "Executes the Melee Factory script.",
    Callback = function()
        local scriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/MSTACK/meleefactory.lua?t="..tostring(tick())
        loadstring(game:HttpGet(scriptURL))()
        Fluent:Notify({ Title = "MeleeFactory Loaded", Content = "MeleeFactory script initialized.", Duration = 3 })
    end
})

Tabs.Autofarm:AddButton({                   
    Title = "Auto Reroll Skypian",
    Description = "Executes the auto reroll skypian script.",
    Callback = function()
        local scriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/MSTACK/auto_reroll_skypian.lua?t="..tostring(tick())
        loadstring(game:HttpGet(scriptURL))()
        Fluent:Notify({ Title = "Skypian Reroll Loaded", Content = "Auto reroll script initialized.", Duration = 3 })
    end
})

Tabs.Autofarm:AddButton({                   
    Title = "Load CombinedAutoLoad (Autofarm)",
    Description = "Executes the script and queues it for future teleports.",
    Callback = function()
        local scriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/CombinedAutoLoad.lua"
        
        -- Execute the script. It will automatically queue itself for future teleports.
        loadstring(game:HttpGet(scriptURL))()
        
        Fluent:Notify({ Title = "Autofarm Loaded", Content = "Auto-farm initialized and queued.", Duration = 3 })
    end
})

Tabs.Autofarm:AddButton({
    Title = "Stop & Clear Autofarm Queue",
    Description = "Tries to halt the autofarm and wipes the teleport queue.",
    Callback = function()
        getgenv().FishmanAutoFarmRunning = false
        
        -- Attempt to clear the exploit teleport queue so it stops following you
        local clear_queue = clear_teleport_queue or (syn and syn.clear_teleport_queue) or (fluxus and fluxus.clear_teleport_queue)
        if clear_queue then
            pcall(clear_queue)
        end
        
        -- Attempt to call any generic stop functions from Controller.lua if they exist
        if typeof(getgenv().StopAutofarm) == "function" then pcall(getgenv().StopAutofarm) end
        
        Fluent:Notify({ Title = "Autofarm Halted", Content = "Queue cleared. If loops are still running, please manually rejoin.", Duration = 5 })
    end
})

-- ======================================================================
-- ⚙️ SETTINGS TAB UI
-- ======================================================================
Tabs.Settings:AddToggle("T_AutoReconnect", { 
    Title = "Auto Reconnect on Disconnect", 
    Default = GlobalMem.FishmanAutoReconnect, 
    Callback = function(Value)
        GlobalMem.FishmanAutoReconnect = Value
        SaveConfig()
    end 
})

Tabs.Settings:AddToggle("T_AntiLag", { 
    Title = "Disable 3D Rendering (Anti-Lag)", 
    Default = false, 
    Callback = function(Value)
        RunService:Set3dRenderingEnabled(not Value)
    end 
})

Tabs.Settings:AddSlider("S_FPSCap", {
    Title = "FPS Cap",
    Description = "Limits your FPS to reduce CPU/GPU usage when AFKing.",
    Default = 25,
    Min = 5,
    Max = 240,
    Rounding = 0,
    Callback = function(Value)
        if setfpscap then pcall(setfpscap, Value) end
    end
})

Tabs.Settings:AddButton({
    Title = "🥔 Potato Graphics",
    Description = "Reduces all game graphics to the absolute minimum for maximum FPS.",
    Callback = function()
        ActivatePotatoGraphics()
    end
})

Tabs.Settings:AddButton({
    Title = "🔄 Update / Load Latest Version",
    Description = "Destroys the current UI and executes the latest joinersystem from GitHub.",
    Callback = function()
        Fluent:Notify({ Title = "Updating", Content = "Fetching latest script from GitHub...", Duration = 3 })
        ShutdownEverything()
        if Window and Window.Destroy then
            Window:Destroy()
        end
        task.wait(1)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/MSTACK/joinersystem.lua?t="..tostring(tick())))()
    end
})

Tabs.Settings:AddButton({
    Title = "Destroy UI & Shutdown",
    Description = "Cleans up all loops, unloads the UI, and stops the script safely.",
    Callback = function()
        ShutdownEverything()
        if Window and Window.Destroy then
            Window:Destroy()
        end
    end
})

Window:SelectTab(isLobby and 1 or 2)
Fluent:Notify({ Title = "Fishman Unified", Content = "Script loaded successfully!", Duration = 5 })

local isPaused = false
local savedState = {}

addConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    secondsSinceLastInput = 0
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        isPaused = not isPaused
        if isPaused then
            Fluent:Notify({ Title = "🛑 Emergency Stop", Content = "Script paused! Press F again to resume.", Duration = 5 })
            
            -- Stop Auto Start state (AFK Mode)
            isAFKModeActive = false
            if Fluent.Options and Fluent.Options.T_AFK then
                Fluent.Options.T_AFK:SetValue(false)
            end

            if Model and Model.State then
                -- Save current task states
                savedState = {
                    isFishing = Model.State.isFishing,
                    autoBuy = Model.State.autoBuy,
                    autoSell = Model.State.autoSell,
                    isAutoTraveling = Model.State.isAutoTraveling,
                    autoCraft = Model.State.autoCraft,
                    isCurrentlyCrafting = Model.State.isCurrentlyCrafting,
                    antiLag = (Fluent.Options and Fluent.Options.T_AntiLag) and Fluent.Options.T_AntiLag.Value or false,
                    deepSea = (Fluent and Fluent.Options and Fluent.Options.T_DeepSea) and Fluent.Options.T_DeepSea.Value or false,
                    megStack = (Fluent and Fluent.Options and Fluent.Options.T_MegStack) and Fluent.Options.T_MegStack.Value or false,
                    megStackLoc = (Fluent and Fluent.Options and Fluent.Options.T_MegStackLoc) and Fluent.Options.T_MegStackLoc.Value or false
                }

                -- Force stop everything instantly
                Model.State.isFishing = false
                Model.State.autoBuy = false
                Model.State.autoSell = false
                Model.State.isAutoTraveling = false
                Model.State.autoCraft = false
                Model.State.isCurrentlyCrafting = false
                Model.State.isCraftFlying = false
                Model.State.isBuying = false
                
                -- Update UI toggles to visually show they are off
                if Fluent.Options then
                    if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(false) end
                    if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(false) end
                    if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(false) end
                    if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(false) end
                    if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(false) end
                    if Fluent.Options.T_AntiLag then Fluent.Options.T_AntiLag:SetValue(false) end
                    if Fluent.Options.T_DeepSea then Fluent.Options.T_DeepSea:SetValue(false) end
                    if Fluent.Options.T_MegStack then Fluent.Options.T_MegStack:SetValue(false) end
                    if Fluent.Options.T_MegStackLoc then Fluent.Options.T_MegStackLoc:SetValue(false) end
                end

                -- Abort actions
                if Model.DisableFlight then pcall(Model.DisableFlight) end
                if Model.UnequipRod then pcall(Model.UnequipRod) end
                if Model.State.activeNavigation and Model.State.activeNavigation._isNavigating then
                    Model.State.activeNavigation:Cancel()
                end

                -- Close any dialogue
                pcall(function()
                    local events = ReplicatedStorage:FindFirstChild("Events")
                    local quest = events and events:FindFirstChild("Quest")
                    if quest then quest:InvokeServer({ [1] = "npcChat", [2] = false }) end
                end)
            end
        else
            Fluent:Notify({ Title = "▶️ Resumed", Content = "Script restored to previous tasks.", Duration = 5 })

            if Model and Model.State then
                -- Restore previously active tasks
                Model.State.isFishing = savedState.isFishing or false
                Model.State.autoBuy = savedState.autoBuy or false
                Model.State.autoSell = savedState.autoSell or false
                Model.State.isAutoTraveling = savedState.isAutoTraveling or false
                Model.State.autoCraft = savedState.autoCraft or false
                
                -- Update UI toggles visually to match restored state
                if Fluent.Options then
                    if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(Model.State.isFishing) end
                    if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(Model.State.autoBuy) end
                    if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(Model.State.autoSell) end
                    if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(Model.State.isAutoTraveling) end
                    if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(Model.State.autoCraft) end
                    if Fluent.Options.T_AntiLag and savedState.antiLag then Fluent.Options.T_AntiLag:SetValue(true) end
                    if Fluent.Options.T_DeepSea then Fluent.Options.T_DeepSea:SetValue(savedState.deepSea) end
                    if Fluent.Options.T_MegStack then Fluent.Options.T_MegStack:SetValue(savedState.megStack) end
                    if Fluent.Options.T_MegStackLoc then Fluent.Options.T_MegStackLoc:SetValue(savedState.megStackLoc) end
                end

                -- Resume traveling if needed
                if Model.State.isAutoTraveling and Model.StartTraveling then
                    Model.StartTraveling()
                end
            end
        end
    end
end))
addConn(UserInputService.InputChanged:Connect(function() secondsSinceLastInput = 0 end))
