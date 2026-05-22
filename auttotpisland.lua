local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- THE SPECIFIC SET POINT
local targetX = 7976.704
local targetY = -2152.832
local targetZ = -17074.277
local travelSpeed = 35 

local character = LocalPlayer.Character
if not character then return end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if not rootPart then return end

-- Enable Physics
local humanoid = character:FindFirstChild("Humanoid")
humanoid.PlatformStand = true 
local bg = Instance.new("BodyGyro", rootPart)
bg.P = 9e4
bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
bg.CFrame = rootPart.CFrame
local bv = Instance.new("BodyVelocity", rootPart)
bv.Velocity = Vector3.new(0, 0, 0)
bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)

-- Movement Loop
local connection
connection = RunService.Heartbeat:Connect(function(deltaTime)
    local currentPos = rootPart.Position
    local target = Vector3.new(targetX, targetY, targetZ)
    
    local dist = (currentPos - target).Magnitude
    if dist < 5 then
        -- Arrived: Clean up
        humanoid.PlatformStand = false
        bg:Destroy()
        bv:Destroy()
        connection:Disconnect()
        return
    end
    
    local alpha = math.clamp((travelSpeed * deltaTime) / dist, 0, 1)
    rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(target), alpha)
end)