-- ======================================================================
-- 🛑 GLOBAL SETUP & DUPLICATE PREVENTION
-- ======================================================================
local env = getgenv and getgenv() or shared
if env.FishmanScriptServer == game.JobId then 
    print("[Fishman] Script is already running in this server!")
    return 
end
env.FishmanScriptServer = game.JobId

if env.Fishman_StopPrevious then
    pcall(env.Fishman_StopPrevious)
end

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
GlobalMem.FishmanDestination = GlobalMem.FishmanDestination or "fishHub" 
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
local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/joinersystem.lua"
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

    workspace.DescendantAdded:Connect(function(child)
        task.spawn(function()
            if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            elseif child:IsA("BasePart") then
                child.CastShadow = false
            end
        end)
    end)
    
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
    local MIN_BAIT            = 10
    local BUY_AMOUNT          = 290
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
    local function StartCraftFlight()
        if craftHeartbeatConn then craftHeartbeatConn:Disconnect() end
        craftHeartbeatConn = RunService.Heartbeat:Connect(function(dt)
            if not Model.State.isCraftFlying or not craftFlyTarget then return end
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end
            
            local cur = rootPart.Position
            local tgt = craftFlyTarget
            local nextPoint
            local goingUp = (tgt.Y > cur.Y)
            
            if goingUp and math.abs(cur.Y - tgt.Y) > 1 then nextPoint = Vector3.new(cur.X, tgt.Y, cur.Z)
            elseif math.abs(cur.X - tgt.X) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, cur.Z)
            elseif math.abs(cur.Z - tgt.Z) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, tgt.Z)
            elseif not goingUp and math.abs(cur.Y - tgt.Y) > 1 then nextPoint = Vector3.new(tgt.X, tgt.Y, tgt.Z)
            else Model.State.isCraftFlying = false; return end
            
            local dist = (cur - nextPoint).Magnitude
            if dist > 0 then
                rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(nextPoint) * rootPart.CFrame.Rotation, math.clamp((30 * dt) / dist, 0, 1))
            end
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    local function StopCraftFlight()
        if craftHeartbeatConn then craftHeartbeatConn:Disconnect(); craftHeartbeatConn = nil end
        Model.State.isCraftFlying = false
    end
    
    local function CraftFlyToAndWait(targetVector)
        craftFlyTarget = targetVector
        Model.State.isCraftFlying = true
        local waited = 0 
        while Model.State.isCraftFlying and waited < 20 do
            if not Model.State.autoCraft then break end
            task.wait(0.1); waited += 0.1
        end
        Model.State.isCraftFlying = false
    end

    local function CraftFlyPath(pathTable)
        StartCraftFlight()
        for _, targetPos in ipairs(pathTable) do CraftFlyToAndWait(targetPos) end
        StopCraftFlight()
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
        CraftFlyPath({ Vector3.new(162.85, originalPos.Y, -55.34) })
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
        CraftFlyPath({ originalPos })
        Model.DisableFlight()
        
        Model.EquipRod()
        Model.StartTraveling()
        Model.State.autoSell = true
        Model.State.waitingForArrivalToFish = true 
    end

    function Model.ForceCraftAll()
        if Model.State.isCurrentlyCrafting then return end
        
        local inventoryObj = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ui") and LocalPlayer.PlayerGui.ui:FindFirstChild("inventoryObj")
        if not inventoryObj then return end
        
        local ok, inventoryData = pcall(function() return HttpService:JSONDecode(inventoryObj.Value) end)
        if not ok or not inventoryData then return end
        
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
        
        CraftFlyPath({ Vector3.new(162.85, originalPos.Y, -55.34) })
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
        CraftFlyPath({ originalPos })
        
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

    function Model.CheckInventory()
        local ok, inventoryData = pcall(function() return HttpService:JSONDecode(inventoryObj.Value) end)
        if not ok or not inventoryData then return end

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
    
    function Model.DoFishingCycle()
        local currentPeli = peliObject and peliObject.Value or 0
        local hookName = LocalPlayer.Name .. "'s hook"
        if workspace.Effects:FindFirstChild(hookName) then task.wait(); return end
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
                if not Model.State.isFishing then return end
                if hook:GetAttribute("Caught") == true then
                    local diffMult = hook:GetAttribute("MoveMultiplier") or 1.0
                    currentPeli = peliObject and peliObject.Value or 0
                    local skipFish = (currentPeli >= MAX_PELI) and (diffMult < 1.2) or (diffMult < 0.9)

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
                        if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(true) end
                        
                        -- Anti-Lag
                        if Fluent.Options.T_AntiLag then Fluent.Options.T_AntiLag:SetValue(true) else RunService:Set3dRenderingEnabled(false) end
                    else
                        Model.State.autoBuy = true
                        Model.State.autoSell = true
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
            local ok, inventoryData = pcall(function() return HttpService:JSONDecode(inventoryObj.Value) end)
            if not ok or not inventoryData then continue end
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

    task.spawn(function() while _running and task.wait(2) do if Model.State.autoBuy then Model.CheckInventory() end end end)
    task.spawn(function() while _running and task.wait() do if Model.State.isFishing then Model.DoFishingCycle() end end end)

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


-- ======================================================================
-- 🎨 FLUENT UI INTEGRATION
-- ======================================================================
Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🐟 Fishman Hub",
    SubTitle = "Unified Auto-Fisher",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 350),
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightShift
})

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
        Default = (table.find({"fishHub", "tradeHub", "Second Sea", "Lobby"}, GlobalMem.FishmanDestination) or 1),
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
-- 🎣 FISHING TAB UI
-- ======================================================================
    Tabs.Fishing:AddToggle("T_Fish", { Title = "Auto Fish", Default = false, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "Cannot fish in Lobby!", Duration = 3 }); Fluent.Options.T_Fish:SetValue(false) end return end
        Model.State.isFishing = Value 
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
    Tabs.Fishing:AddToggle("T_AFK", { Title = "AFK Mode (Auto-start after 10s)", Default = not isLobby, Callback = function(Value) 
        if isLobby then if Value then Fluent:Notify({ Title = "Error", Content = "AFK Mode requires Fishing server!", Duration = 3 }); Fluent.Options.T_AFK:SetValue(false) end return end
        isAFKModeActive = Value; secondsSinceLastInput = 0 
    end })

    -- Status Monitor
    local StatusPara = Tabs.Fishing:AddParagraph({ Title = "Status", Content = "Idle" })
    local statusParts = {}
    task.spawn(function()
        while _running and task.wait(1) do
            table.clear(statusParts)
            if Model.State.isFishing then table.insert(statusParts, "Fishing") end
            if Model.State.autoBuy then table.insert(statusParts, "Buying") end
            if Model.State.autoSell then table.insert(statusParts, "Selling") end
            if Model.State.autoCraft then table.insert(statusParts, Model.State.isCurrentlyCrafting and "Crafting" or "Craft ON") end
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
    
    if GlobalMem.FishmanPSCode == "qj1ttW4JG1" and not isLobby then
        Fluent:Notify({ Title = "Detection", Content = "Target Server qj1ttW4JG1 Detected.", Duration = 5 })
    end

-- ======================================================================
-- 🤖 AUTOFARM TAB UI
-- ======================================================================
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

Tabs.Settings:AddButton({
    Title = "🥔 Potato Graphics",
    Description = "Reduces all game graphics to the absolute minimum for maximum FPS.",
    Callback = function()
        ActivatePotatoGraphics()
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
                    isCurrentlyCrafting = Model.State.isCurrentlyCrafting
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
                end

                -- Abort actions
                if Model.DisableFlight then pcall(Model.DisableFlight) end
                if Model.UnequipRod then pcall(Model.UnequipRod) end

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
