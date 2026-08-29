-- Version 3.8
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
            if GlobalMem.FishmanPSCodeHistory == nil then GlobalMem.FishmanPSCodeHistory = data.FishmanPSCodeHistory end
            if GlobalMem.FishmanDestination == nil then GlobalMem.FishmanDestination = data.FishmanDestination end
            if GlobalMem.FishmanAutoTeleport == nil then GlobalMem.FishmanAutoTeleport = data.FishmanAutoTeleport end
            if GlobalMem.FishmanAutoJoin == nil then GlobalMem.FishmanAutoJoin = data.FishmanAutoJoin end
            if GlobalMem.FishmanAutoReconnect == nil then GlobalMem.FishmanAutoReconnect = data.FishmanAutoReconnect end
            if GlobalMem.FishmanAutoRouteLobby == nil then GlobalMem.FishmanAutoRouteLobby = data.FishmanAutoRouteLobby end
            print("[Fishman] Loaded Config from file.")
        end
    end
end)

GlobalMem.FishmanPSCode = GlobalMem.FishmanPSCode or "qj1ttW4JG1"
if type(GlobalMem.FishmanPSCodeHistory) ~= "table" or #GlobalMem.FishmanPSCodeHistory == 0 then
    GlobalMem.FishmanPSCodeHistory = {GlobalMem.FishmanPSCode}
end
if not table.find(GlobalMem.FishmanPSCodeHistory, GlobalMem.FishmanPSCode) and GlobalMem.FishmanPSCode ~= "" then
    table.insert(GlobalMem.FishmanPSCodeHistory, 1, GlobalMem.FishmanPSCode)
end
GlobalMem.FishmanDestination = GlobalMem.FishmanDestination or "tradeHub" 
GlobalMem.FishmanAutoTeleport = GlobalMem.FishmanAutoTeleport or false 
GlobalMem.FishmanAutoJoin = GlobalMem.FishmanAutoJoin or false
if GlobalMem.FishmanAutoReconnect == nil then GlobalMem.FishmanAutoReconnect = true end
if GlobalMem.FishmanAutoRouteLobby == nil then GlobalMem.FishmanAutoRouteLobby = true end

local function SaveConfig()
    pcall(function()
        if writefile then
            local data = {
                FishmanPSCode = GlobalMem.FishmanPSCode,
                FishmanPSCodeHistory = GlobalMem.FishmanPSCodeHistory,
                FishmanDestination = GlobalMem.FishmanDestination,
                FishmanAutoTeleport = GlobalMem.FishmanAutoTeleport,
                FishmanAutoJoin = GlobalMem.FishmanAutoJoin,
                FishmanAutoReconnect = GlobalMem.FishmanAutoReconnect,
                FishmanAutoRouteLobby = GlobalMem.FishmanAutoRouteLobby
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
                if codeLabel and (codeLabel:IsA("TextLabel") or codeLabel:IsA("TextBox")) then
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
        autoBuy               = not isLobby,
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
            
            -- Also clean up Hoverboard flyToWithGeppo forces
            local bg2 = rootPart:FindFirstChild("AntiRotation")
            if bg2 then bg2:Destroy() end
            local bv2 = rootPart:FindFirstChild("AntiGravity")
            if bv2 then bv2:Destroy() end
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
        
        local function TweenTo(point, customSpeed)
            local currentSpeed = customSpeed or speed
            if not Model.State.isCraftFlying then return end
            local dist = (rootPart.Position - point).Magnitude
            if dist < 1 then return end
            
            local tweenInfo = TweenInfo.new(dist / currentSpeed, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(point) * rootPart.CFrame.Rotation})
            tween:Play()
            
            while tween.PlaybackState == Enum.PlaybackState.Playing do
                if not Model.State.autoCraft and not Model.State.isRefillingMegBait and not Model.State.isManualTraveling then 
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
        
        TweenTo(upPoint, speed * 0.5) -- 50% slower for going up
        TweenTo(overPoint)
        TweenTo(targetVector)
        
        Model.State.isCraftFlying = false
    end

    function Model.CraftFlyPath(pathTable)
        for _, targetPos in ipairs(pathTable) do 
            if not Model.State.autoCraft and not Model.State.isRefillingMegBait and not Model.State.isManualTraveling then break end
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
        
        local function TweenTo(point, customSpeed)
            local currentSpeed = customSpeed or speed
            if not Model.State.isCraftFlying then return end
            local dist = (rootPart.Position - point).Magnitude
            if dist < 1 then return end
            
            local tweenInfo = TweenInfo.new(dist / currentSpeed, Enum.EasingStyle.Linear)
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
        
        TweenTo(upPoint, speed * 0.5) -- 50% slower for going up
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
        -- Model.State.autoBuy = false
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
    task.spawn(function() while _running and task.wait() do if (Model.State.isFishing or Model.State.isDeepSeaCatcher) and not Model.State.isBuying and not Model.State.isAutoTraveling and not Model.State.isRefillingMegBait and not Model.State.isManualTraveling then Model.DoFishingCycle() end end end)

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
            if Model.State.autoReturn and not Model.State.isCraftFlying and not Model.State.isAutoTraveling and not Model.State.isRefillingMegBait and not Model.State.isManualTraveling and not Model.State.isCurrentlyCrafting then
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
                        -- Trigger return!
                        local success = Model.ReturnToShip()
                        
                        if success then 
                            print("✅ [Auto Return] Safely landed on the hoverboard platform!")
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
    if getgenv().StopAutofarm then
        pcall(getgenv().StopAutofarm)
    end
    getgenv().ToggleCyborgAutofarm = nil
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

local function isFruitAlreadyStored(fruitName)
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
                    if isFruitAlreadyStored(fruitName) then
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
    if Model and Model.State then
        tempSavedState = {
            isFishing = Model.State.isFishing,
            autoBuy = Model.State.autoBuy,
            autoSell = Model.State.autoSell,
            isAutoTraveling = Model.State.isAutoTraveling,
            autoCraft = Model.State.autoCraft
        }
        
        -- Force stop them
        Model.State.isFishing = false
        -- Model.State.autoBuy = false
        Model.State.autoSell = false
        Model.State.isAutoTraveling = false
        Model.State.autoCraft = false
        
        -- Update toggles visually
        if Fluent and Fluent.Options then
            if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(false) end
            -- if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(false) end
            if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(false) end
            if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(false) end
            if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(false) end
        end
        
        -- Wait a moment for any current actions (like reeling) to finish
        task.wait(2)
        
        -- Unequip current tools (rod/sword) so we can equip fruits properly
        humanoid:UnequipTools()
        task.wait(0.5)
    end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if getgenv()._cancelStoreFruits then break end
        if tool:IsA("Tool") then
            local toolName = string.lower(tool.Name)
            local isTargetFruit = false
            local matchedFruitName = nil
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    if isFruitAlreadyStored(fruitName) then
                        if Fluent then Fluent:Notify({ Title = "Already Stored", Content = tool.Name .. " is already in storage! Skipping.", Duration = 3 }) end
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
            
            if isTargetFruit and not isFruitAlreadyStored(matchedFruitName) then
                humanoid:EquipTool(tool)
                task.wait(0.2)
                
                pcall(function()
                    ReplicatedStorage.Events.FruitStorage:InvokeServer(true)
                end)
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
            autoCraft = Model.State.autoCraft
        }
        
        -- Force stop them
        Model.State.isFishing = false
        -- Model.State.autoBuy = false
        Model.State.autoSell = false
        Model.State.isAutoTraveling = false
        Model.State.autoCraft = false
        
        -- Update toggles visually
        if Fluent and Fluent.Options then
            if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(false) end
            -- if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(false) end
            if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(false) end
            if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(false) end
            if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(false) end
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
        end

        if Model.State.isAutoTraveling and Model.StartTraveling then
            Model.StartTraveling()
        end
    end
end


-- ======================================================================
-- 🎨 CUSTOM LIGHTWEIGHT UI INTEGRATION
-- ======================================================================
getgenv().Fluent = {
    Options = {
        T_MegStackLoc = { Value = false },
        T_ManualMegStackLoc = { Value = false },
        T_AutoSpawnShip = { Value = false },
        T_AutoReconnect = { Value = GlobalMem.FishmanAutoReconnect or false },
        T_AntiLag = { Value = false },
        S_FPSCap = { Value = 35 },
        T_AutoReturn = { Value = false },
        T_MegStack = { Value = false },
        T_DeepSea = { Value = false },
        T_AFK = { Value = false },
        T_Fish = { Value = false },
        T_Buy = { Value = false },
        T_AutoStoreFruit = { Value = false },
        T_CyborgAuto = { Value = false }
    },
    Notify = function(self, args)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = args.Title or "Notification",
                Text = args.Content or "",
                Duration = args.Duration or 5
            })
        end)
    end
}

for k, v in pairs(getgenv().Fluent.Options) do
    v.SetValue = function(self, val)
        self.Value = val
        if getgenv().CustomUIToggles and getgenv().CustomUIToggles[k] then
            local data = getgenv().CustomUIToggles[k]
            local btn = data.Button
            if val then
                btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                btn.Text = data.CustomName .. " [ON]"
            else
                btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                btn.Text = data.CustomName .. " [OFF]"
            end
        end
    end
end

local CoreGui = game:GetService("CoreGui")
local uiName = "FishmanCustomUI"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = uiName
sg.ResetOnSpawn = false
sg.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 432)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "🐟 Fishman Meg Stack"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.LayoutOrder = 1
title.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = mainFrame

getgenv().CustomUIToggles = {}

local function createToggle(id, name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 230, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    btn.Text = name .. " [OFF]"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.LayoutOrder = order
    -- btn.CustomName = name
    btn.Parent = mainFrame
    
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 6)
    c2.Parent = btn
    
    getgenv().CustomUIToggles[id] = { Button = btn, CustomName = name }
    
    btn.MouseButton1Click:Connect(function()
        local opt = getgenv().Fluent.Options[id]
        opt:SetValue(not opt.Value)
        if callback then
            task.spawn(callback, opt.Value)
        end
    end)
    
    getgenv().Fluent.Options[id]:SetValue(getgenv().Fluent.Options[id].Value)
    return btn
end

local function createButton(name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 230, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.LayoutOrder = order
    btn.Parent = mainFrame
    
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 6)
    c2.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        if callback then
            task.spawn(callback)
        end
    end)
    return btn
end

createToggle("T_Fish", "🎣 Auto Fish", 2, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot fish in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_Fish:SetValue(false) end return end
    Model.State.isFishing = val 
end)

createToggle("T_DeepSea", "🐙 Deep Sea Catcher (Beasts)", 3, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot fish in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_DeepSea:SetValue(false) end return end
    task.spawn(function()
        if val then
            print("triggering title: \"Skilled Fisherman\"")
            local args = { "Skilled Fisherman" }
            pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args)) end)
        end
    end)
    Model.State.isDeepSeaCatcher = val 
end)

createToggle("T_MegStack", "🦈 Megalodon Stack", 4, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot stack in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_MegStack:SetValue(false) end return end
    Model.State.isMegStacking = val
    if val then
        if getgenv().Fluent.Options.T_DeepSea then getgenv().Fluent.Options.T_DeepSea:SetValue(true) end
        if getgenv().Fluent.Options.T_Fish then getgenv().Fluent.Options.T_Fish:SetValue(true) end
        if getgenv().Fluent.Options.T_Buy then getgenv().Fluent.Options.T_Buy:SetValue(true) end
        if getgenv().Fluent.Options.T_MegStackLoc then getgenv().Fluent.Options.T_MegStackLoc:SetValue(true) end
        if getgenv().Fluent.Options.T_AutoStoreFruit then getgenv().Fluent.Options.T_AutoStoreFruit:SetValue(true) end
        if getgenv().Fluent.Options.T_AutoReturn then getgenv().Fluent.Options.T_AutoReturn:SetValue(true) end
        print("🌊 [MegStack] Meg stack starting now! Enabling deep sea catcher for 10 megalodons.")
        task.spawn(function()
            while Model.State.isMegStacking do
                local megCount = Model.countMegalodons and Model.countMegalodons() or 0
                if megCount >= 10 and not Model.State.isBuying and not Model.State.isAutoTraveling and not Model.State.isRefillingMegBait and not Model.State.isManualTraveling then
                    print("🔥 [MegStack] 10 Megalodons reached! Disabling fishing and automatically toggling Cyborg Autofarm ON...")
                    if getgenv().Fluent.Options.T_DeepSea.Value == true then getgenv().Fluent.Options.T_DeepSea:SetValue(false) end
                    if getgenv().Fluent.Options.T_CyborgAuto then getgenv().Fluent.Options.T_CyborgAuto:SetValue(true) end
                    
                    local waitTime = 0
                    local lastCount = Model.countMegalodons and Model.countMegalodons() or 0
                    while Model.countMegalodons and Model.countMegalodons() > 0 and Model.State.isMegStacking and waitTime < 180 do
                        task.wait(1)
                        waitTime = waitTime + 1
                        local curCount = Model.countMegalodons()
                        if curCount < lastCount then
                            waitTime = 0
                            lastCount = curCount
                        end
                    end
                    
                    print("✅ [MegStack] Stack cleared! Toggling Cyborg Autofarm OFF and resuming fishing...")
                    if getgenv().Fluent.Options.T_CyborgAuto then getgenv().Fluent.Options.T_CyborgAuto:SetValue(false) end
                    if Model.State.isMegStacking then getgenv().Fluent.Options.T_DeepSea:SetValue(true) end
                end
                task.wait(1)
            end
        end)
    else
        print("🛑 [MegStack] Stacking aborted. Shutting down deep sea catcher.")
        if getgenv().Fluent.Options.T_DeepSea and getgenv().Fluent.Options.T_DeepSea.Value == true then getgenv().Fluent.Options.T_DeepSea:SetValue(false) end
        if getgenv().Fluent.Options.T_Fish and getgenv().Fluent.Options.T_Fish.Value == true then getgenv().Fluent.Options.T_Fish:SetValue(false) end
        if getgenv().Fluent.Options.T_AutoStoreFruit and getgenv().Fluent.Options.T_AutoStoreFruit.Value == true then getgenv().Fluent.Options.T_AutoStoreFruit:SetValue(false) end
        if getgenv().Fluent.Options.T_AutoReturn and getgenv().Fluent.Options.T_AutoReturn.Value == true then getgenv().Fluent.Options.T_AutoReturn:SetValue(false) end
    end
end)

createToggle("T_CyborgAuto", "⚔️ Cyborg Autofarm", 5, function(val)
    if isLobby then 
        if val then 
            getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot farm in Lobby!", Duration = 3 }) 
            if getgenv().Fluent.Options.T_CyborgAuto then getgenv().Fluent.Options.T_CyborgAuto:SetValue(false) end 
        end 
        return 
    end

    if val then
        if getgenv().Fluent and getgenv().Fluent.Options and getgenv().Fluent.Options.T_AutoStoreFruit then
            getgenv()._wasAutoStoreFruitOn = getgenv().Fluent.Options.T_AutoStoreFruit.Value
            if getgenv()._wasAutoStoreFruitOn then
                getgenv().Fluent.Options.T_AutoStoreFruit:SetValue(false)
                getgenv().Fluent:Notify({ Title = "System", Content = "Auto Store Fruit paused during Cyborg Autofarm", Duration = 3 })
            end
        end
    else
        if getgenv()._wasAutoStoreFruitOn and getgenv().Fluent and getgenv().Fluent.Options and getgenv().Fluent.Options.T_AutoStoreFruit then
            getgenv().Fluent.Options.T_AutoStoreFruit:SetValue(true)
            getgenv()._wasAutoStoreFruitOn = false
            getgenv().Fluent:Notify({ Title = "System", Content = "Auto Store Fruit resumed", Duration = 3 })
        end
    end

    task.spawn(function()
        if val then
            print("triggering title: \"Megalodon Slayer\"")
            local args = { "Megalodon Slayer" }
            pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args)) end)
        end
    end)

    if val and not getgenv().ToggleCyborgAutofarm then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/protov4_nofactory.lua"))()
        end)
        task.wait(1)
    end
    if getgenv().ToggleCyborgAutofarm then
        getgenv().ToggleCyborgAutofarm(val)
    end
end)

createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 6, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot use in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_MegStackLoc:SetValue(false) end return end
    Model.State.isMegStackLoc = val
end)

createToggle("T_ManualMegStackLoc", "🎣 Manual Meg Stack", 7, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot use in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_ManualMegStackLoc:SetValue(false) end return end
    
    if val then
        if getgenv().Fluent and getgenv().Fluent.Options and getgenv().Fluent.Options.T_AutoReturn and getgenv().Fluent.Options.T_AutoReturn.Value then
            getgenv().Fluent.Options.T_AutoReturn:SetValue(false)
            getgenv().Fluent:Notify({ Title = "System", Content = "Auto Return Hoverboard turned OFF for Manual Travel", Duration = 3 })
        end

        manualTravelInitialized = true
        task.spawn(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then getgenv().CachedOriginalPos = hrp.Position end
            
            Model.State.isAutoTraveling = false
            if Model.DisableFlight then Model.DisableFlight() end
            if Model.UnequipRod then Model.UnequipRod() end
            task.wait(1)
            
            if not getgenv().Fluent.Options.T_ManualMegStackLoc.Value then return end
            
            Model.State.isManualTraveling = true
            if Model.EnableFlight then Model.EnableFlight() end
            getgenv().Fluent:Notify({ Title = "Manual Travel", Content = "Flying to Meg Stack Island...", Duration = 3 })
            if Model.CraftFlyPath then Model.CraftFlyPath({ Vector3.new(-6760, 27, 9191) }) end
            
            if Model.State.isManualTraveling then
                Model.State.isManualTraveling = false
                if Model.DisableFlight then Model.DisableFlight() end
                getgenv().Fluent:Notify({ Title = "Manual Travel", Content = "Arrived at Meg Stack Island!", Duration = 3 })
            end
        end)
    else
        Model.State.isManualTraveling = false
    end
end)

createToggle("T_AutoSpawnShip", "🛳️ Auto Spawn Ship", 8, function(val)
    if val then
        if EnsureHoverboardLoaded then EnsureHoverboardLoaded() end
        if getgenv().HoverboardController and getgenv().HoverboardController.AutoSpawn then
            getgenv().HoverboardController.AutoSpawn(function()
                if getgenv().Fluent and getgenv().Fluent.Options and getgenv().Fluent.Options.T_MegStack then
                    getgenv().Fluent.Options.T_MegStack:SetValue(true)
                end
            end)
        end
    else
        if getgenv().HoverboardController then
            getgenv().HoverboardController.CancelAutoSpawn = true
        end
        if Model and Model.DisableFlight then pcall(Model.DisableFlight) end
        if getgenv().HoverboardController and getgenv().HoverboardController.Reset then
            getgenv().HoverboardController.Reset()
        end
    end
end)

createToggle("T_AntiLag", "⚙️ Disable 3D (Anti-Lag)", 9, function(val)
    RunService:Set3dRenderingEnabled(not val)
end)

createButton("🥔 Potato Graphics", 10, function()
    if ActivatePotatoGraphics then ActivatePotatoGraphics() end
end)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -35, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
minBtn.Text = "X"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = mainFrame

local minc = Instance.new("UICorner")
minc.CornerRadius = UDim.new(0, 15)
minc.Parent = minBtn

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 250, 0, 40)
        for _, child in pairs(mainFrame:GetChildren()) do
            if child:IsA("TextButton") and child ~= minBtn then
                child.Visible = false
            end
        end
        minBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        minBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 250, 0, 432)
        for _, child in pairs(mainFrame:GetChildren()) do
            if child:IsA("TextButton") and child ~= minBtn then
                child.Visible = true
            end
        end
        minBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        minBtn.Text = "X"
    end
end)

getgenv().Fishman_DestroyUI = function()
    if sg then sg:Destroy() end
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
end

getgenv().Fluent:Notify({ Title = "Fishman Custom UI", Content = "Loaded Lightweight UI!", Duration = 5 })
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
                -- Model.State.autoBuy = false
                Model.State.autoSell = false
                Model.State.isAutoTraveling = false
                Model.State.autoCraft = false
                Model.State.isCurrentlyCrafting = false
                Model.State.isCraftFlying = false
                Model.State.isBuying = false
                
                -- Update UI toggles to visually show they are off
                if Fluent.Options then
                    if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(false) end
                    -- if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(false) end
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

if OrionLib then OrionLib:Init() end
