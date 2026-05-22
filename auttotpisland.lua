local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- THE SPECIFIC SET POINT TO RETURN TO
local targetX = 7976.704
local targetY = -2152.832
local targetZ = -17074.277
local travelSpeed = 90 -- If you get anti-cheat kicked, lower this to 35

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
-- 2. AUTO-EXECUTE FLIGHT LOGIC                --
-- =========================================== --
local character = LocalPlayer.Character
if not character then return end

enableFlight(character)

-- We use variables to store the loops so we can destroy them when we arrive
local flightLoop
local noclipLoop

noclipLoop = RunService.Stepped:Connect(function()
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

flightLoop = RunService.Heartbeat:Connect(function(deltaTime)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local currentPos = rootPart.Position
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
        disableFlight(character) 
        
        -- Destroy the loops so they stop running in the background
        if flightLoop then flightLoop:Disconnect() end
        if noclipLoop then noclipLoop:Disconnect() end
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