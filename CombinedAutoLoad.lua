-- ============================================================================
-- COMBINED AUTO LOAD & CONTROLLER (UNIFIED 1-BUTTON TRAVEL + AUTOFARM)
-- ============================================================================
-- Flow:
-- 1. Click button:
--    - If already at Fishman Island -> Immediately starts Autofarm
--    - If elsewhere -> Flies sequentially (X -> Z -> Y), saves spawn, then starts Autofarm
-- 2. Click button again -> Instantly stops travel/autofarm and resets physics
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Fetch Model module
local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Model.lua"))()

-- Target Coordinates (Fishman Island)
local targetX = 7976.704
local targetY = -2152.832
local targetZ = -17074.277
local finalTarget = Vector3.new(targetX, targetY, targetZ)
local travelSpeed = 90

-- State Management
local isRunning = true
local isActionActive = false
local isTraveling = false

local steppedConnection
local heartbeatConnection
local travelHeartbeatConnection

-- ============================================================================
-- 1. FLIGHT CONTROLS & PHYSICS
-- ============================================================================
local function enableFlight(character)
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

local function disableFlight(character)
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if rootPart then
        local bg = rootPart:FindFirstChild("AutoTravel_Gyro")
        if bg then bg:Destroy() end
        
        local bv = rootPart:FindFirstChild("AutoTravel_Velocity")
        if bv then bv:Destroy() end
    end
    
    if humanoid then
        humanoid.PlatformStand = false
    end
end

-- ============================================================================
-- 2. SPAWN SAVER (NPC INTERACTION)
-- ============================================================================
local function saveSpawnPoint()
    task.spawn(function()
        pcall(function()
            -- Primary: load github npcsave
            loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/npcsave.lua"))()
        end)
    end)
end

-- ============================================================================
-- 3. LOCATION CHECK
-- ============================================================================
local function isAtFishmanIsland()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    local directDistance = (root.Position - finalTarget).Magnitude
    local horizontalDistance = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(targetX, 0, targetZ)).Magnitude
    
    -- Within 250 studs or underwater cave at Fishman Island
    if directDistance <= 250 or (root.Position.Y < -1500 and horizontalDistance <= 400) then
        return true
    end
    return false
end

-- ============================================================================
-- 4. CLEANUP ROUTINE
-- ============================================================================
if typeof(getgenv().StopAutofarm) == "function" then
    pcall(getgenv().StopAutofarm)
end

local function cleanupEverything()
    isRunning = false
    isActionActive = false
    isTraveling = false
    
    Model.State.isAutoFarming = false
    Model.State.isQuesting = false
    Model.State.isRecovering = false
    Model.ResetPhysics()
    
    if LocalPlayer.Character then
        disableFlight(LocalPlayer.Character)
    end
    
    if steppedConnection then steppedConnection:Disconnect(); steppedConnection = nil end
    if heartbeatConnection then heartbeatConnection:Disconnect(); heartbeatConnection = nil end
    if travelHeartbeatConnection then travelHeartbeatConnection:Disconnect(); travelHeartbeatConnection = nil end
    
    -- Clear teleport queue if present
    local clear_queue = clear_teleport_queue or (syn and syn.clear_teleport_queue) or (fluxus and fluxus.clear_teleport_queue) or (queue_on_teleport and function() queue_on_teleport("") end)
    if clear_queue then pcall(clear_queue) end
    
    -- Destroy any previous UI
    local existingGui = CoreGui:FindFirstChild("CombinedAutoFarmGui") or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("CombinedAutoFarmGui"))
    if existingGui then existingGui:Destroy() end
    
    print("[CombinedAutoLoad] Cleaned up and stopped.")
end

getgenv().StopAutofarm = cleanupEverything

-- ============================================================================
-- 5. UNIFIED UI (1 BUTTON + CLOSE BUTTON)
-- ============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CombinedAutoFarmGui"
screenGui.ResetOnSpawn = false

local ok = pcall(function() screenGui.Parent = CoreGui end)
if not ok then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 50)
mainFrame.Position = UDim2.new(0.5, -120, 0.1, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -46, 1, 0)
toggleBtn.Position = UDim2.new(0, 0, 0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
toggleBtn.Text = "AUTO FARM: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Parent = mainFrame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

-- Version Label
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(1, 0, 0, 18)
versionLabel.Position = UDim2.new(0, 0, 0, -20)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "AUTOFARM + TRAVEL V1.0"
versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextSize = 11
versionLabel.Parent = mainFrame
local stroke = Instance.new("UIStroke", versionLabel)
stroke.Color = Color3.fromRGB(0, 0, 0)
stroke.Thickness = 1.2

-- Close Button (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 1, 0)
closeBtn.Position = UDim2.new(1, -40, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Draggable Logic
local dragging, dragInput, dragStart, startPos
local function setupDraggable(element)
    element.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
end

setupDraggable(toggleBtn)
setupDraggable(versionLabel)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ============================================================================
-- 6. COMBAT & TRAVEL LOGIC
-- ============================================================================
local function startCombatFarming()
    isTraveling = false
    Model.State.isAutoFarming = true
    
    toggleBtn.Text = "AUTO FARM: ON"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
    
    task.spawn(function()
        while isActionActive and Model.State.isAutoFarming and isRunning do
            Model.DoCombatCombo()
        end
    end)
end

local function startTravelSequence()
    isTraveling = true
    Model.State.isAutoFarming = false
    
    toggleBtn.Text = "TRAVELING TO ISLAND..."
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
    
    enableFlight(LocalPlayer.Character)
    
    if travelHeartbeatConnection then travelHeartbeatConnection:Disconnect() end
    
    travelHeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not isActionActive or not isTraveling then
            if travelHeartbeatConnection then
                travelHeartbeatConnection:Disconnect()
                travelHeartbeatConnection = nil
            end
            return
        end
        
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local currentPos = rootPart.Position
        local nextPoint
        
        -- Sequential movement: X -> Z -> Y
        if math.abs(currentPos.X - targetX) > 1 then
            nextPoint = Vector3.new(targetX, currentPos.Y, currentPos.Z)
        elseif math.abs(currentPos.Z - targetZ) > 1 then
            nextPoint = Vector3.new(targetX, currentPos.Y, targetZ)
        elseif math.abs(currentPos.Y - targetY) > 1 then
            nextPoint = Vector3.new(targetX, targetY, targetZ)
        else
            -- Arrived at target!
            isTraveling = false
            if travelHeartbeatConnection then
                travelHeartbeatConnection:Disconnect()
                travelHeartbeatConnection = nil
            end
            
            disableFlight(character)
            saveSpawnPoint()
            
            -- Seamlessly transition into combat
            task.wait(0.5)
            if isActionActive and isRunning then
                startCombatFarming()
            end
            return
        end
        
        local distance = (currentPos - nextPoint).Magnitude
        if distance > 0 then
            local alpha = math.clamp((travelSpeed * deltaTime) / distance, 0, 1)
            rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(nextPoint), alpha)
        end
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
    end)
end

local function stopAll()
    isActionActive = false
    isTraveling = false
    Model.State.isAutoFarming = false
    
    if travelHeartbeatConnection then
        travelHeartbeatConnection:Disconnect()
        travelHeartbeatConnection = nil
    end
    
    if LocalPlayer.Character then
        disableFlight(LocalPlayer.Character)
    end
    Model.ResetPhysics()
    
    toggleBtn.Text = "AUTO FARM: OFF"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
end

-- Toggle Click Event
toggleBtn.MouseButton1Click:Connect(function()
    if isActionActive then
        stopAll()
    else
        isActionActive = true
        if isAtFishmanIsland() then
            startCombatFarming()
        else
            startTravelSequence()
        end
    end
end)

-- Close Button Click Event
closeBtn.MouseButton1Click:Connect(function()
    stopAll()
    cleanupEverything()
    screenGui:Destroy()
end)

-- ============================================================================
-- 7. ROBLOX ENGINE HOOKS & BACKGROUND LOOPS
-- ============================================================================
-- Noclip & Collision Management
steppedConnection = RunService.Stepped:Connect(function()
    if isActionActive and LocalPlayer.Character then
        if isTraveling then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        elseif Model.State.isAutoFarming then
            Model.ApplyNoclip()
        end
    end
end)

-- Combat Tracking Loop
heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
    if isActionActive and Model.State.isAutoFarming and isRunning then
        Model.UpdateTracking(deltaTime)
    end
end)

-- Background Quest Loop (Dynamic check)
task.spawn(function()
    while isRunning do
        task.wait(5)
        -- Only check if we aren't already currently grabbing a quest
        if isActionActive and Model.State.isAutoFarming and not Model.State.isQuesting and isRunning then
            local hasQuest = false
            pcall(function()
                local args = { [1] = "getNPCQuestLocations" }
                local questData = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Quest", 9e9):InvokeServer(unpack(args))
                
                -- If it returns an active quest table (not empty)
                if type(questData) == "table" and next(questData) ~= nil then
                    hasQuest = true
                elseif questData ~= nil and questData ~= "" and questData ~= false and type(questData) ~= "table" then
                    -- If it returns a string/value, ensure it's not empty
                    hasQuest = true
                end
            end)
            
            -- If the quest stops running (returns empty/nil), head back to Becky
            if not hasQuest then
                Model.GrabQuest()
            end
        end
    end
end)

-- Background Auto-Stats Loop (every 1 second)
task.spawn(function()
    while isRunning do
        task.wait(1)
        if isActionActive and Model.State.isAutoFarming and isRunning then
            Model.UpgradeStats()
        end
    end
end)

print("[CombinedAutoLoad] Loaded successfully. Ready.")
