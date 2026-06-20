-- ======================================================================
-- 🛑 DUPLICATE PREVENTION (GLOBAL KILL SWITCH)
-- ======================================================================
local env = getgenv and getgenv() or shared
if env.AutoFisher_StopPrevious then
    warn("[AutoFisher] Old version detected. Shutting it down...")
    pcall(env.AutoFisher_StopPrevious)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ======================================================================
-- LIFECYCLE GUARD
-- All background task.spawn loops check this flag and exit when closed.
-- ======================================================================
local _running = true

-- ======================================================================
-- 1. VIEW MODULE (The Menu)
-- ======================================================================
local View = {}

local function createToggle(parent, labelText, activeColor, onToggleCallback, startOn)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 220, 0, 52)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    btn.Text = ""
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(50, 50, 65)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(210, 210, 220)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = btn

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 42, 0, 22)
    pill.Position = UDim2.new(1, -54, 0.5, -11)
    pill.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    pill.Parent = btn
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local isOn = false

    local function setToggleState(newState, triggerCallback)
        if isOn == newState then return end
        isOn = newState
        pill.BackgroundColor3 = isOn and activeColor or Color3.fromRGB(60, 60, 75)
        knob.Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 190)
        btnStroke.Color = isOn and activeColor or Color3.fromRGB(50, 50, 65)
        if triggerCallback then onToggleCallback(isOn) end
    end

    btn.MouseButton1Click:Connect(function()
        setToggleState(not isOn, true)
    end)

    if startOn then setToggleState(true, true) end

    return setToggleState
end

function View.Build(callbacks)
    local playerGui = player:WaitForChild("PlayerGui")

    local oldMenu = playerGui:FindFirstChild("FishingMenu")
    if oldMenu then oldMenu:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishingMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 260, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -130, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    titleBar.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Auto Fisher"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -40)
    content.Position = UDim2.new(0, 0, 0, 40)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.Parent = content

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 220, 0, 24)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle"
    statusLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.Parent = content

    local toggleUpdaters = {}
    toggleUpdaters.Fish   = createToggle(content, "Auto Fish\nDynamic Trophy Mode",       Color3.fromRGB(0, 180, 255),   callbacks.OnFishToggle,   false)
    toggleUpdaters.Buy    = createToggle(content, "Auto Buy Bait\nBelow 10 -> Buy 290",    Color3.fromRGB(80, 200, 80),   callbacks.OnBuyToggle,    false)
    toggleUpdaters.Sell   = createToggle(content, "Auto Sell Fish\nSells until Max Peli",  Color3.fromRGB(255, 160, 0),   callbacks.OnSellToggle,   false)
    toggleUpdaters.Travel = createToggle(content, "Travel to Bait\nFinds empty spot",      Color3.fromRGB(150, 80, 200),  callbacks.OnTravelToggle, false)
    toggleUpdaters.AFK    = createToggle(content, "AFK Mode\nAuto-start after 20s",        Color3.fromRGB(255, 60, 100),  callbacks.OnAFKToggle,    true)
    toggleUpdaters.Craft  = createToggle(content, "Auto Craft\nLegendary Bait (needs 40)", Color3.fromRGB(255, 200, 0),   callbacks.OnCraftToggle,  false)

    -- Notification banner
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 240, 0, 48)
    notifFrame.Position = UDim2.new(0.5, -120, 1, 10)
    notifFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    notifFrame.BackgroundTransparency = 0.1
    notifFrame.ZIndex = 10
    notifFrame.Parent = screenGui
    Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 10)
    local notifStroke = Instance.new("UIStroke", notifFrame)
    notifStroke.Color = Color3.fromRGB(255, 255, 180)
    notifStroke.Thickness = 1.5

    local notifLabel = Instance.new("TextLabel")
    notifLabel.Size = UDim2.new(1, -12, 1, 0)
    notifLabel.Position = UDim2.new(0, 6, 0, 0)
    notifLabel.BackgroundTransparency = 1
    notifLabel.Text = "🌟 Legendary Bait Crafted!"
    notifLabel.TextColor3 = Color3.fromRGB(30, 20, 0)
    notifLabel.Font = Enum.Font.GothamBold
    notifLabel.TextSize = 13
    notifLabel.ZIndex = 11
    notifLabel.Parent = notifFrame

    local tweenIn  = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back,  Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -120, 1, -62) })
    local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad,  Enum.EasingDirection.In),  { Position = UDim2.new(0.5, -120, 1, 10)  })

    local notifActive = false
    tweenOut.Completed:Connect(function() notifActive = false end)

    local function ShowCraftNotif(fishName)
        if notifActive then return end
        notifActive = true
        notifLabel.Text = "🌟 Crafted Legendary Bait!\n(" .. fishName .. ")"
        notifFrame.Position = UDim2.new(0.5, -120, 1, 10)
        tweenIn:Play()
        task.delay(2.5, function() tweenOut:Play() end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        callbacks.OnClose()
    end)

    return {
        UpdateStatus          = function(text) statusLabel.Text = text end,
        ForceTogglesOn        = function()
            toggleUpdaters.Buy(true, true)
            toggleUpdaters.Sell(true, true)
            toggleUpdaters.Travel(true, true)
            toggleUpdaters.Craft(true, true)
        end,
        ForceFishOn           = function() toggleUpdaters.Fish(true, true) end,
        SetFishToggleVisual   = function(state) toggleUpdaters.Fish(state, false) end,
        SetBuyToggleVisual    = function(state) toggleUpdaters.Buy(state, false) end,
        SetSellToggleVisual   = function(state) toggleUpdaters.Sell(state, false) end,
        SetTravelToggleVisual = function(state) toggleUpdaters.Travel(state, false) end,
        ShowCraftNotif        = ShowCraftNotif,
    }
end

-- ======================================================================
-- 2. MODEL MODULE (The Brains)
-- ======================================================================
local Model = {}

local shopEvent      = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Shop", 9e9)
local buyableItems   = workspace:WaitForChild("BuyableItems", 9e9)
local sellEvent      = ReplicatedStorage:WaitForChild("FishingShopRemote", 9e9)
local questEvent     = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Quest", 9e9)
local craftingRemote = ReplicatedStorage:WaitForChild("CraftingRemote", 9e9)
local Remote         = ReplicatedStorage:WaitForChild("Fishing", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("Action", 9e9)

local LEGENDARY_FISHES  = { "Anglerfish", "Golden Ribbon Angelfish", "Golden Polka Puffer", "Golden Tigerfin" }

local statsFolder    = ReplicatedStorage:WaitForChild("Stats" .. player.Name, 9e9)
local inventoryObj   = statsFolder:WaitForChild("Inventory", 9e9):WaitForChild("Inventory", 9e9)
local peliObject     = statsFolder:WaitForChild("Stats", 9e9):WaitForChild("Peli", 9e9)

-- ==========================================
-- ⚙️ CONFIGURATION
-- ==========================================
local MAX_PELI            = 1000000
local BAIT_NAME           = "Common Fish Bait"
local MIN_BAIT            = 10
local BUY_AMOUNT          = 290
local BAIT_SEARCH_RADIUS  = 25
local THROW_ANIMATION_ID  = "rbxassetid://140322334422224"
local REEL_ANIMATION_ID   = "rbxassetid://136623058564703"

local fishToSell = {
    "Crimson Snapper", "Exotic Tigerfin", "Fangfish",
    "Zebra Ribbon Angelfish", "Blue-Lip Grouper",
    "Tigerfin", "Crimson Polka Puffer",
    "Common Fish", "Seaweed", "Old Boot", "Tin Can"
}
local VALID_RODS = { "Devil Fruit Rod", "Merchants Banana Rod", "Lovestruck Rod", "Fishing Rod" }

Model.State = {
    isFishing             = false,
    autoBuy               = false,
    autoSell              = false,
    isBuying              = false,
    isAutoTraveling       = false,
    targetPos             = nil,
    travelMessage         = "",
    maxPeliReachedMessage = false,
    autoCraft             = false,
    isCurrentlyCrafting   = false,
    waitingForArrivalToFish = false,
    isCraftFlying         = false,
}

local loadedAnimations = {}

local function clearAnimationCache()
    for _, track in pairs(loadedAnimations) do
        pcall(function() track:Stop(0) end)
    end
    table.clear(loadedAnimations)
end

local function playAnimation(animationId)
    local character = player.Character
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

local _connections = {}

local function addConn(conn)
    _connections[#_connections + 1] = conn
    return conn
end

local function disconnectAll()
    for _, c in ipairs(_connections) do
        if c and c.Connected then c:Disconnect() end
    end
    table.clear(_connections)
end

-- ==========================================
-- ✈️ FLIGHT HELPERS
-- ==========================================
function Model.EnableFlight()
    local character = player.Character
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
    local character = player.Character
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

-- ==========================================
-- 🚶 MOVEMENT (Fixed Spinning)
-- ==========================================
function Model.HandleMovement(deltaTime)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not Model.State.targetPos then return end
    local cur = rootPart.Position
    local tgt = Model.State.targetPos
    local nextPoint

    if math.abs(cur.X - tgt.X) > 1 then
        nextPoint = Vector3.new(tgt.X, cur.Y, cur.Z)
    elseif math.abs(cur.Z - tgt.Z) > 1 then
        nextPoint = Vector3.new(tgt.X, cur.Y, tgt.Z)
    elseif math.abs(cur.Y - tgt.Y) > 1 then
        nextPoint = Vector3.new(tgt.X, tgt.Y, tgt.Z)
    else
        Model.State.isAutoTraveling = false
        Model.DisableFlight()
        Model.State.travelMessage = "Arrived at Bait"
        return
    end

    local dist = (cur - nextPoint).Magnitude
    if dist > 0 then
        -- Added * rootPart.CFrame.Rotation to lock character orientation and stop spinning
        rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(nextPoint) * rootPart.CFrame.Rotation, math.clamp((90 * deltaTime) / dist, 0, 1))
    end
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
end

-- ==========================================
-- 🔨 AUTO CRAFT SYSTEM (Bulk Enabled + Fixed Spinning)
-- ==========================================
local craftFlyTarget = nil
local craftHeartbeatConn = nil

local function StartCraftFlight()
    if craftHeartbeatConn then craftHeartbeatConn:Disconnect() end
    craftHeartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not Model.State.isCraftFlying or not craftFlyTarget then return end
        
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local cur = rootPart.Position
        local tgt = craftFlyTarget
        local nextPoint
        
        local goingUp = (tgt.Y > cur.Y)
        
        if goingUp and math.abs(cur.Y - tgt.Y) > 1 then 
            nextPoint = Vector3.new(cur.X, tgt.Y, cur.Z)
        elseif math.abs(cur.X - tgt.X) > 1 then 
            nextPoint = Vector3.new(tgt.X, cur.Y, cur.Z)
        elseif math.abs(cur.Z - tgt.Z) > 1 then 
            nextPoint = Vector3.new(tgt.X, cur.Y, tgt.Z)
        elseif not goingUp and math.abs(cur.Y - tgt.Y) > 1 then 
            nextPoint = Vector3.new(tgt.X, tgt.Y, tgt.Z)
        else 
            Model.State.isCraftFlying = false 
            return 
        end
        
        local dist = (cur - nextPoint).Magnitude
        if dist > 0 then
            -- Added * rootPart.CFrame.Rotation to lock character orientation and stop spinning
            rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(nextPoint) * rootPart.CFrame.Rotation, math.clamp((30 * dt) / dist, 0, 1))
        end
        
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function StopCraftFlight()
    if craftHeartbeatConn then
        craftHeartbeatConn:Disconnect()
        craftHeartbeatConn = nil
    end
    Model.State.isCraftFlying = false
end

local function CraftFlyToAndWait(targetVector)
    craftFlyTarget = targetVector
    Model.State.isCraftFlying = true
    local timeout, waited = 20, 0 
    while Model.State.isCraftFlying and waited < timeout do
        if not Model.State.autoCraft then break end
        task.wait(0.1)
        waited += 0.1
    end
    Model.State.isCraftFlying = false
end

local function CraftFlyPath(pathTable)
    StartCraftFlight()
    for _, targetPos in ipairs(pathTable) do
        CraftFlyToAndWait(targetPos)
    end
    StopCraftFlight()
end

local function SafeInvokeQuest(chatState)
    pcall(function()
        questEvent:InvokeServer({ [1] = "npcChat", [2] = chatState })
    end)
end

local uiHandle = nil

function Model.ExecuteLegendaryCraft(craftQueue, onSuccess)
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then warn("[AutoCraft] ⚠️ No HumanoidRootPart.") return end

    local originalPos = hrp.Position

    Model.State.isFishing       = false
    Model.State.autoBuy         = false
    Model.State.autoSell        = false
    Model.State.isAutoTraveling = false
    Model.State.targetPos       = nil
    Model.State.travelMessage   = "Crafting..."

    if uiHandle then
        uiHandle.SetFishToggleVisual(false)
        uiHandle.SetBuyToggleVisual(false)
        uiHandle.SetSellToggleVisual(false)
        uiHandle.SetTravelToggleVisual(false)
    end

    Model.DisableFlight()
    warn("[AutoCraft] 🎣 Unequipping rod before trip...")
    Model.UnequipRod()

    warn("[AutoCraft] ⏳ Waiting 3s before flying to Sen...")
    task.wait(3)
    if not Model.State.autoCraft then return end

    Model.EnableFlight()
    warn("[AutoCraft] 🚀 Flying directly to Sen...")
    CraftFlyPath({ 
        Vector3.new(162.85125732421875, originalPos.Y, -55.347503662109375)
    })

    if not Model.State.autoCraft then 
        Model.DisableFlight() 
        return 
    end

    warn("[AutoCraft] 🛬 Arrived at Sen. Processing bulk crafts...")
    task.wait(0.5)

    SafeInvokeQuest(true)
    task.wait(0.5)

    for _, craftItem in ipairs(craftQueue) do
        if not Model.State.autoCraft then break end
        warn("[AutoCraft] Crafting " .. craftItem.Batches .. " batch(es) of " .. craftItem.Name)
        
        for i = 1, craftItem.Batches do
            if not Model.State.autoCraft then break end
            
            pcall(function()
                craftingRemote:InvokeServer({
                    Count         = 40,
                    ExtraData     = { ["Legendary Fish"] = craftItem.Name },
                    Method        = "Craft",
                    BlueprintItem = "Legendary Fish Bait",
                })
            end)
            task.wait(0.5)
        end
    end

    SafeInvokeQuest(false)
    warn("[AutoCraft] ✅ All crafting done! Returning...")
    task.wait(0.3)

    if not Model.State.autoCraft then 
        Model.DisableFlight() 
        return 
    end

    -- Flies smoothly back to where you started
    CraftFlyPath({ 
        originalPos 
    })
    Model.DisableFlight()

    if onSuccess then 
        for _, craftItem in ipairs(craftQueue) do
            onSuccess(craftItem.Name, craftItem.Batches)
        end
    end

    warn("[AutoCraft] 🎣 Re-equipping rod...")
    Model.EquipRod()

    warn("[AutoCraft] 🔄 Restarting cycle: Travel -> Fish...")
    local pos = Model.GetFreeBaitPosition()
    if pos then
        Model.State.targetPos               = pos
        Model.State.isAutoTraveling         = true
        Model.State.autoBuy                 = true
        Model.State.autoSell                = true
        Model.State.travelMessage           = "Traveling..."
        Model.State.waitingForArrivalToFish = true 
        Model.EnableFlight()
        if uiHandle then
            uiHandle.SetTravelToggleVisual(true)
            uiHandle.SetBuyToggleVisual(true)
            uiHandle.SetSellToggleVisual(true)
        end
    else
        Model.State.autoBuy    = true
        Model.State.autoSell   = true
        Model.State.isFishing  = true
        Model.State.travelMessage = ""
        if uiHandle then
            uiHandle.SetFishToggleVisual(true)
            uiHandle.SetBuyToggleVisual(true)
            uiHandle.SetSellToggleVisual(true)
        end
    end
end

function Model.GetFreeBaitPosition()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    -- Dynamically gets your current height so you fly straight across
    local currentY = hrp and hrp.Position.Y or 9.315620422363281
    
    -- Hardcoded destination that completely skips player detection
    return Vector3.new(101.5317611694336, currentY, -55.778465270996094)
end

function Model.EquipRod()
    local character = player.Character
    local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and table.find(VALID_RODS, tool.Name) then return end
    end
    local backpack = player:FindFirstChild("Backpack")
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
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
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
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart  = character:WaitForChild("HumanoidRootPart")
    local nearest, nearestDist = nil, BAIT_SEARCH_RADIUS

    for _, item in ipairs(buyableItems:GetChildren()) do
        if string.find(string.lower(item.Name), "bait") then
            local pos = (item:IsA("Model") and item.PrimaryPart.Position) or item.Position
            if pos then
                local d = (rootPart.Position - pos).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = item
                end
            end
        end
    end

    if nearest then
        pcall(function()
            if shopEvent:IsA("RemoteFunction") then
                shopEvent:InvokeServer(nearest, BUY_AMOUNT)
            else
                shopEvent:FireServer(nearest, BUY_AMOUNT)
            end
        end)
    end
    task.wait(0.5)
    Model.State.isBuying = false
end

function Model.CheckInventory()
    local ok, inventoryData = pcall(function()
        return HttpService:JSONDecode(inventoryObj.Value)
    end)
    if not ok or not inventoryData then return end

    if Model.State.autoBuy and not Model.State.isBuying then
        local count = inventoryData[BAIT_NAME] or 0
        if count < MIN_BAIT then Model.BuyNearestBait() end
    end

    if Model.State.autoSell then
        local currentPeli = peliObject and peliObject.Value or 0
        if currentPeli < MAX_PELI then
            for _, fishName in ipairs(fishToSell) do
                if (inventoryData[fishName] or 0) >= 1 then
                    pcall(function()
                        sellEvent:InvokeServer({ Fish = fishName, All = true, Method = "SellFish" })
                    end)
                end
            end
        end
    end
end

-- ======================================================================
-- 🎣 FISHING CYCLE
-- ======================================================================
function Model.DoFishingCycle()
    local currentPeli = peliObject and peliObject.Value or 0
    Model.State.maxPeliReachedMessage = (currentPeli >= MAX_PELI)

    local hookName = player.Name .. "'s hook"
    if workspace.Effects:FindFirstChild(hookName) then
        task.wait()
        return
    end

    local character = player.Character
    if not character then return end

    Model.EquipRod()
    task.wait()

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local throwTrack = playAnimation(THROW_ANIMATION_ID)
    if throwTrack then task.delay(0.8, function() throwTrack:Stop(0.15) end) end

    local throwGoal = rootPart.Position + (rootPart.CFrame.LookVector * 40) + Vector3.new(0, 2, 0)
    pcall(function()
        Remote:InvokeServer({ Bait = BAIT_NAME, Action = "Throw", Goal = throwGoal })
    end)

    local hook = workspace.Effects:WaitForChild(hookName, 3)
    if hook then
        local maxWait = 15
        local waited  = 0
        while waited < maxWait do
            if not Model.State.isFishing then return end
            if hook:GetAttribute("Caught") == true then
                local diffMult = hook:GetAttribute("MoveMultiplier") or 1.0
                currentPeli = peliObject and peliObject.Value or 0
                local skipFish = (currentPeli >= MAX_PELI)
                    and (diffMult < 1.2)
                    or  (diffMult < 0.9)

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
            task.wait(0.1)
            waited += 0.1
        end
    end

    pcall(function() Remote:InvokeServer({ Action = "Cancel" }) end)
    task.wait()
end

function Model.ListenToInventoryChanges(callback)
    if Model._inventoryConnection then
        Model._inventoryConnection:Disconnect()
    end
    Model._inventoryConnection = inventoryObj:GetPropertyChangedSignal("Value"):Connect(callback)
    addConn(Model._inventoryConnection)
end

-- ======================================================================
-- 3. CONTROLLER MODULE (Loops & Logic)
-- ======================================================================
local isAFKModeActive     = false
local secondsSinceLastInput = 0

addConn(UserInputService.InputBegan:Connect(function()  secondsSinceLastInput = 0 end))
addConn(UserInputService.InputChanged:Connect(function() secondsSinceLastInput = 0 end))

-- ======================================================================
-- 🛑 THE MASTER SHUTDOWN FUNCTION
-- ======================================================================
local function ShutdownEverything()
    _running = false
    Model.State.isFishing           = false
    Model.State.autoBuy             = false
    Model.State.autoSell            = false
    Model.State.isAutoTraveling     = false
    Model.State.autoCraft           = false
    Model.State.isCurrentlyCrafting = false
    Model.State.isCraftFlying       = false
    isAFKModeActive                 = false
    
    disconnectAll()
    StopCraftFlight()
    Model.DisableFlight()
    clearAnimationCache()

    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local oldMenu = playerGui:FindFirstChild("FishingMenu")
        if oldMenu then oldMenu:Destroy() end
    end
end

env.AutoFisher_StopPrevious = ShutdownEverything


uiHandle = View.Build({
    OnFishToggle = function(isOn)
        Model.State.isFishing = isOn
        if isOn then
            Model.State.maxPeliReachedMessage = (peliObject and peliObject.Value or 0) >= MAX_PELI
        end
    end,
    OnBuyToggle = function(isOn)
        Model.State.autoBuy = isOn
        if isOn then Model.CheckInventory() end
    end,
    OnSellToggle = function(isOn)
        Model.State.autoSell = isOn
        if isOn then Model.CheckInventory() end
    end,
    OnTravelToggle = function(isOn)
        Model.State.isAutoTraveling = isOn
        if isOn then
            local pos = Model.GetFreeBaitPosition()
            if pos then
                Model.State.targetPos     = pos
                Model.State.travelMessage = "Traveling..."
                Model.EnableFlight()
            else
                Model.State.isAutoTraveling = false
                Model.State.travelMessage   = "All Baits Full"
            end
        else
            Model.DisableFlight()
            Model.State.targetPos     = nil
            Model.State.travelMessage = ""
        end
    end,
    OnAFKToggle = function(isOn)
        isAFKModeActive       = isOn
        secondsSinceLastInput = 0
    end,
    OnCraftToggle = function(isOn)
        Model.State.autoCraft = isOn
    end,
    OnClose = function()
        ShutdownEverything()
    end,
})

task.spawn(function()
    while _running and task.wait(1) do
        if isAFKModeActive then
            secondsSinceLastInput += 1
            if secondsSinceLastInput == 10 then
                uiHandle.ForceTogglesOn()
                Model.State.waitingForArrivalToFish = true
            end
        end
    end
end)

task.spawn(function()
    while _running and task.wait(3) do
        if not Model.State.autoCraft or Model.State.isCurrentlyCrafting then continue end
        local ok, inventoryData = pcall(function()
            return HttpService:JSONDecode(inventoryObj.Value)
        end)
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

task.spawn(function()
    while _running and task.wait(2) do
        if Model.State.autoBuy then Model.CheckInventory() end
    end
end)

task.spawn(function()
    while _running and task.wait() do
        if Model.State.isFishing then Model.DoFishingCycle() end
    end
end)

local statusParts = table.create(6)
task.spawn(function()
    while _running and task.wait(1) do
        table.clear(statusParts)
        if Model.State.isFishing       then table.insert(statusParts, "Fishing") end
        if Model.State.autoBuy         then table.insert(statusParts, "Buying")  end
        if Model.State.autoSell        then table.insert(statusParts, "Selling") end
        if Model.State.autoCraft       then
            table.insert(statusParts, Model.State.isCurrentlyCrafting and "Crafting..." or "Craft ON")
        end
        if isAFKModeActive             then table.insert(statusParts, "[AFK ON]") end

        if Model.State.isAutoTraveling or Model.State.travelMessage ~= "" then
            uiHandle.UpdateStatus("Status: " .. Model.State.travelMessage)
            if Model.State.travelMessage == "Arrived at Bait" or Model.State.travelMessage == "All Baits Full" then
                if Model.State.travelMessage == "Arrived at Bait" and Model.State.waitingForArrivalToFish then
                    Model.State.waitingForArrivalToFish = false
                    uiHandle.ForceFishOn()
                end
                task.delay(3, function() Model.State.travelMessage = "" end)
            end
        else
            uiHandle.UpdateStatus(#statusParts > 0 and ("Active: " .. table.concat(statusParts, " ")) or "Status: Idle")
        end
    end
end)

addConn(RunService.Heartbeat:Connect(function(dt)
    if not _running then return end
    if Model.State.isAutoTraveling then
        Model.HandleMovement(dt)
    end
end))

-- ======================================================================
-- 👻 TRUE NOCLIP (Tied to Physics Engine)
-- ======================================================================
addConn(RunService.Stepped:Connect(function()
    if not _running then return end
    if Model.State.isAutoTraveling then 
        local character = player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end))

Model.ListenToInventoryChanges(function() Model.CheckInventory() end)
Model.CheckInventory()