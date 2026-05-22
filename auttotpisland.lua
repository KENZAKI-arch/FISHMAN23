local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- =========================================== --
-- 1. FLY PHYSICS CONTROLS                     --
-- =========================================== --
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
-- 3. SAFE ZONE & RETURN LOGIC                 --
-- =========================================== --
local travelIntent = false 
local isAutoTraveling = false 
local travelSpeed = 90 
local BORDER_BUFFER = 30 -- Wiggle room outside the island before dragging you back

-- THE SPECIFIC SET POINT TO RETURN TO
local targetX = 7976.704
local targetY = -2152.832
local targetZ = -17074.277

toggleBtn.MouseButton1Click:Connect(function()
    travelIntent = not travelIntent
    
    if travelIntent then
        isAutoTraveling = true
        toggleBtn.Text = "AUTO TRAVEL: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
        enableFlight(LocalPlayer.Character) 
    else
        isAutoTraveling = false
        toggleBtn.Text = "AUTO TRAVEL: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
        disableFlight(LocalPlayer.Character) 
    end
end)

RunService.Stepped:Connect(function()
    if isAutoTraveling and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if not travelIntent then return end 

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local currentPos = rootPart.Position

    -- *** PHASE 1: CHECKING THE SAFE ZONE ***
    if not isAutoTraveling then
        local islandsFolder = Workspace:FindFirstChild("Islands")
        local fishmanIsland = islandsFolder and islandsFolder:FindFirstChild("Fishman Island")
        
        if not fishmanIsland then return end -- Wait for the map to load

        -- Wrap an invisible box around the physical island model
        local islandCFrame, islandSize = fishmanIsland:GetBoundingBox()
        local relativePos = islandCFrame:PointToObjectSpace(currentPos)
        local halfSize = (islandSize / 2) + Vector3.new(BORDER_BUFFER, BORDER_BUFFER, BORDER_BUFFER)
        
        -- Did they step outside the invisible box?
        local isOutsideBox = math.abs(relativePos.X) > halfSize.X or 
                             math.abs(relativePos.Y) > halfSize.Y or 
                             math.abs(relativePos.Z) > halfSize.Z

        if isOutsideBox then
            isAutoTraveling = true
            toggleBtn.Text = "RETURNING TO SET POINT"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
            enableFlight(character)
        end
        return 
    end

    -- *** PHASE 2: TRAVELING BACK TO THE SET POINT ***
    local nextPoint
    
    -- Sequential Logic: Move X, then Z, then Y towards your specific coordinates
    if math.abs(currentPos.X - targetX) > 1 then
        nextPoint = Vector3.new(targetX, currentPos.Y, currentPos.Z)
    elseif math.abs(currentPos.Z - targetZ) > 1 then
        nextPoint = Vector3.new(targetX, currentPos.Y, targetZ)
    elseif math.abs(currentPos.Y - targetY) > 1 then
        nextPoint = Vector3.new(targetX, targetY, targetZ)
    else
        -- Safely arrived at your hardcoded set point!
        isAutoTraveling = false
        toggleBtn.Text = "AUTO TRAVEL: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
        
        disableFlight(character) 
        return
    end

    -- Movement Execution
    local distance = (currentPos - nextPoint).Magnitude
    if distance > 0 then
        local alpha = math.clamp((travelSpeed * deltaTime) / distance, 0, 1)
        rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(nextPoint), alpha)
    end
    
    rootPart.Velocity = Vector3.new(0, 0, 0)
    rootPart.RotVelocity = Vector3.new(0, 0, 0)
end)