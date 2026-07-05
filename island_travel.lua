-- ======================================================================
-- ✈️ AUTO ISLAND TRAVEL SCRIPT (BYPASS METHOD)
-- ======================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ⚙️ CONFIGURATION
-- ==========================================
local targetIslandName = "Sphinx Island" -- Exact name from workspace.Islands
local travelSpeed = 90 -- Studs per second

if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
local character = LocalPlayer.Character
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local targetIsland = workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild(targetIslandName)

if not targetIsland then
    warn("[Travel] Could not find island: " .. targetIslandName)
    return
end

-- Get the center position of the island
local targetPosition
if targetIsland:IsA("Model") then
    targetPosition = targetIsland:GetPivot().Position
else
    targetPosition = targetIsland.Position
end

-- Generate safe waypoints (Travel Y first to avoid mountains)
local travelHeight = math.max(rootPart.Position.Y, targetPosition.Y) + 500
local waypoint1 = Vector3.new(rootPart.Position.X, travelHeight, rootPart.Position.Z)
local waypoint2 = Vector3.new(targetPosition.X, travelHeight, targetPosition.Z)
local finalTarget = Vector3.new(targetPosition.X, targetPosition.Y + 20, targetPosition.Z)

print("[Travel] Initiating bypass flight to " .. targetIslandName)

-- 1. Preparation (Enable Flight Physics)
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

-- 2. Movement Logic (Heartbeat + Lerp)
local travelStage = 1
local travelConn
travelConn = RunService.Heartbeat:Connect(function(deltaTime)
    if not character or not character.Parent or humanoid.Health <= 0 then
        if travelConn then travelConn:Disconnect() end
        return
    end

    local cur = rootPart.Position
    local tgt
    if travelStage == 1 then tgt = waypoint1
    elseif travelStage == 2 then tgt = waypoint2
    else tgt = finalTarget end

    local goingUp = (tgt.Y > cur.Y)
    local nextPoint

    if goingUp and math.abs(cur.Y - tgt.Y) > 1 then nextPoint = Vector3.new(cur.X, tgt.Y, cur.Z)
    elseif math.abs(cur.X - tgt.X) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, cur.Z)
    elseif math.abs(cur.Z - tgt.Z) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, tgt.Z)
    elseif not goingUp and math.abs(cur.Y - tgt.Y) > 1 then nextPoint = Vector3.new(tgt.X, tgt.Y, tgt.Z)
    else
        -- Stage Transition
        if travelStage == 1 then
            travelStage = 2
            return
        elseif travelStage == 2 then
            travelStage = 3
            return
        end
        
        -- Arrived
        travelConn:Disconnect()
        humanoid.PlatformStand = false
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
        print("[Travel] Arrived safely at " .. targetIslandName .. "!")
        return
    end

    local newX, newZ = cur.X, cur.Z
    local horizNext = Vector3.new(nextPoint.X, cur.Y, nextPoint.Z)
    local horizDist = (Vector3.new(cur.X, 0, cur.Z) - Vector3.new(nextPoint.X, 0, nextPoint.Z)).Magnitude
    
    if horizDist > 0 then
        local alpha = math.clamp((travelSpeed * deltaTime) / horizDist, 0, 1)
        local hLerp = cur:Lerp(horizNext, alpha)
        newX, newZ = hLerp.X, hLerp.Z
    end

    local newY = cur.Y
    local vertDist = math.abs(nextPoint.Y - cur.Y)
    if vertDist > 0 then
        local dir = (nextPoint.Y > cur.Y) and 1 or -1
        local moveY = travelSpeed * deltaTime
        if moveY > vertDist then moveY = vertDist end
        newY = cur.Y + (moveY * dir)
    end

    -- Apply Physics Bypass
    rootPart.CFrame = CFrame.new(newX, newY, newZ)
    bv.Velocity = Vector3.new(0, 0, 0)
    bg.CFrame = CFrame.new(rootPart.Position, Vector3.new(tgt.X, rootPart.Position.Y, tgt.Z))
end)
