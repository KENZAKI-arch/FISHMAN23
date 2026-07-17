local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- THE SPECIFIC SET POINT TO RETURN TO
local targetX = 7976.704
local targetY = -2152.832
local targetZ = -17074.277

local targetLandingPos = Vector3.new(targetX, targetY, targetZ)
local flySpeed = 90 -- Lower to 35 if anti-cheat kicks you. Uses 'flySpeed' terminology from Model.lua

local character = LocalPlayer.Character
if not character then return end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if not rootPart then return end

-- =========================================== --
-- 1. PHYSICS SETUP (Exact from Model.lua)     --
-- =========================================== --
-- Removes BodyGyro/PlatformStand, uses only AntiGravity BodyVelocity
local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
bv.Name = "AntiGravity"
bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
bv.Velocity = Vector3.new(0, 0, 0)
bv.Parent = rootPart

local noclipLoop
local flightLoop

noclipLoop = RunService.Stepped:Connect(function()
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

flightLoop = RunService.Heartbeat:Connect(function(deltaTime)
    if not rootPart or not rootPart.Parent then return end

    -- ========================================== --
    -- THE GLOBAL KILL SWITCH
    -- ========================================== --
    if _G.CancelAutoTravel == true then
        if bv then bv:Destroy() end
        if noclipLoop then noclipLoop:Disconnect() end
        if flightLoop then flightLoop:Disconnect() end
        return
    end

    local currentPos = rootPart.Position
    local nextPoint
    
    -- Step-by-step pathing logic to avoid walls
    if math.abs(currentPos.X - targetX) > 1 then
        nextPoint = Vector3.new(targetX, currentPos.Y, currentPos.Z)
    elseif math.abs(currentPos.Z - targetZ) > 1 then
        nextPoint = Vector3.new(targetX, currentPos.Y, targetZ)
    elseif math.abs(currentPos.Y - targetY) > 1 then
        nextPoint = Vector3.new(targetX, targetY, targetZ)
    else
        -- ========================================== --
        -- SAFELY ARRIVED AT THE TARGET
        -- ========================================== --
        if bv then bv:Destroy() end
        if noclipLoop then noclipLoop:Disconnect() end
        if flightLoop then flightLoop:Disconnect() end
        
        -- Automatically run the separate NPC Save script
        task.spawn(function()
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/npcsave.lua"))()
            end)
        end)
        
        return
    end

    -- Exact CFrame:Lerp math from Model.lua UpdateTracking
    local finalCFrame = CFrame.lookAt(nextPoint, targetLandingPos) 
    local distance = (currentPos - nextPoint).Magnitude
    
    if distance > 0.5 then
        local lerpAlpha = math.clamp((flySpeed * deltaTime) / distance, 0, 1)
        rootPart.CFrame = rootPart.CFrame:Lerp(finalCFrame, lerpAlpha)
    else
        rootPart.CFrame = finalCFrame
    end
    
    rootPart.Velocity = Vector3.new(0, 0, 0)
    rootPart.RotVelocity = Vector3.new(0, 0, 0)
end)
