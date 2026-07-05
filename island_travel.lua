-- ======================================================================
-- ✈️ AUTO ISLAND TRAVEL SCRIPT (TWEEN BASED)
-- ======================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ⚙️ CONFIGURATION
-- ==========================================
local targetIslandName = "Destination Island"
-- Change these coordinates to the exact location you want to travel to!
local targetPosition = CFrame.new(101.53, 50, -55.77) 
local travelSpeed = 90 -- Speed in Studs per second (Keep below 150 to avoid Anti-Cheat)

if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
local character = LocalPlayer.Character
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

print("[Travel] Initiating flight to " .. targetIslandName)

-- 1. Preparation (Bypass Physics)
-- We anchor the RootPart to ensure the Tween is 100% smooth and ignores gravity/stuttering.
local originalAnchored = rootPart.Anchored
rootPart.Anchored = true 
humanoid.PlatformStand = true

-- We create a No-Clip loop so you can fly straight through mountains and buildings
local noclipConn
noclipConn = RunService.Stepped:Connect(function()
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

-- 2. Calculate Tween
local distance = (rootPart.Position - targetPosition.Position).Magnitude
local timeToTravel = distance / travelSpeed

local tweenInfo = TweenInfo.new(
    timeToTravel,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.InOut
)

local tween = TweenService:Create(rootPart, tweenInfo, { CFrame = targetPosition })

-- 3. Execute
tween:Play()

tween.Completed:Connect(function()
    print("[Travel] Arrived at " .. targetIslandName .. "!")
    rootPart.Anchored = originalAnchored
    humanoid.PlatformStand = false
    if noclipConn then noclipConn:Disconnect() end
end)
