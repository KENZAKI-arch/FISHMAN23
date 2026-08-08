local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- =========================================== --
-- 1. FLY PHYSICS CONTROLS                     --
-- =========================================== --
-- Turns ON the Infinite Yield physics (Freezes legs, stops gravity)
local function enableFlight(character)
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if rootPart and humanoid then
        humanoid.PlatformStand = true -- Stops legs from trying to walk
        
        -- Add BodyGyro (Steering Wheel)
        local bg = rootPart:FindFirstChild("AutoTravel_Gyro") or Instance.new("BodyGyro")
        bg.Name = "AutoTravel_Gyro"
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = rootPart.CFrame
        bg.Parent = rootPart
        
        -- Add BodyVelocity (Engine to fight gravity)
        local bv = rootPart:FindFirstChild("AutoTravel_Velocity") or Instance.new("BodyVelocity")
        bv.Name = "AutoTravel_Velocity"
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = rootPart
    end
end

-- Turns OFF the physics and lets you walk normally again
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
        humanoid.PlatformStand = false -- Gives you your legs back
    end
end

-- =========================================== --
-- 2. UI CREATION (Draggable Toggle Button)    --
-- =========================================== --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoTravelGui"
screenGui.ResetOnSpawn = false

local success = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not success then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 160, 0, 50)
toggleBtn.Position = UDim2.new(0.5, -80, 0.1, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
toggleBtn.Text = "AUTO TRAVEL: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleBtn

-- UI Dragging Logic
local dragging, dragInput, dragStart, startPos
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- =========================================== --
-- 3. SEQUENTIAL TRAVEL LOGIC (X -> Z -> Y)    --
-- =========================================== --
local isAutoTraveling = false
local travelSpeed = 90 -- Adjust for faster/slower movement

-- TARGET COORDINATES
local targetX = 7976.704
local targetY = -2152.832
local targetZ = -17074.277
local finalTarget = Vector3.new(targetX, targetY, targetZ)

toggleBtn.MouseButton1Click:Connect(function()
    isAutoTraveling = not isAutoTraveling
    
    if isAutoTraveling then
        toggleBtn.Text = "AUTO TRAVEL: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
        enableFlight(LocalPlayer.Character) -- Turn physics ON
    else
        toggleBtn.Text = "AUTO TRAVEL: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
        disableFlight(LocalPlayer.Character) -- Turn physics OFF
    end
end)

local noclipLoop
local flightLoop

-- NOCLIP: Prevents collisions only while traveling
noclipLoop = RunService.Stepped:Connect(function()
    if isAutoTraveling and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- MAIN LOOP
flightLoop = RunService.Heartbeat:Connect(function(deltaTime)
    if not isAutoTraveling then return end

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local currentPos = rootPart.Position
    local nextPoint
    
    -- Step-by-Step Logic: X first, then Z, then Y
    if math.abs(currentPos.X - targetX) > 1 then
        -- Stage 1: Move X only (Keep current Y and Z)
        nextPoint = Vector3.new(targetX, currentPos.Y, currentPos.Z)
        
    elseif math.abs(currentPos.Z - targetZ) > 1 then
        -- Stage 2: Move Z only (X is finished, keep current Y)
        nextPoint = Vector3.new(targetX, currentPos.Y, targetZ)
        
    elseif math.abs(currentPos.Y - targetY) > 1 then
        -- Stage 3: Move Y only (X and Z are finished)
        nextPoint = Vector3.new(targetX, targetY, targetZ)
        
    else
        -- SAFELY ARRIVED AT THE TARGET
        -- ========================================== --
        isAutoTraveling = false
        toggleBtn.Text = "ARRIVED"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
        
        disableFlight(character)
        
        if noclipLoop then noclipLoop:Disconnect() end
        if flightLoop then flightLoop:Disconnect() end
        
        -- Automatically run the separate NPC Save script
        task.spawn(function()
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/npcsave.lua"))()
            end)
        end)
        
        -- Trigger AutoFarm
        print("[Logic] Arrived at Fishman Island. Loading Controller...")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Controller.lua"))()
        
        return
    end

    -- Movement execution
    local distance = (currentPos - nextPoint).Magnitude
    if distance > 0 then
        local alpha = math.clamp((travelSpeed * deltaTime) / distance, 0, 1)
        rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(nextPoint), alpha)
    end
    
    -- Keep velocity at zero to avoid fighting the Lerp
    rootPart.Velocity = Vector3.new(0, 0, 0)
    rootPart.RotVelocity = Vector3.new(0, 0, 0)
end)
