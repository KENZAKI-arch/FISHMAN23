-- ==============================================================================
-- Movement System Test & Replication Script
-- Demonstrates the core algorithms observed in the Wyvern movement engine:
--   1. Camera-Relative Velocity WalkSpeed (Flat X/Z with preserved Y gravity)
--   2. High-Altitude Arc Waypoint Calculation (Ascent -> Cruise -> Descent)
--   3. CFrame Interpolation with Anchored Ground Support Platform
--   4. Multi-Height Forward Raycast Obstacle Probing
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Wait for character
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- ==============================================================================
-- 1. CONFIGURATION & TUNING
-- ==============================================================================
local Config = {
    WalkSpeedValue       = 55,
    TeleportSpeed        = 120,
    CruiseAltitudeOffset = 500,     -- Height added above start/target for arc flight
    ArcMinDistance       = 150,     -- Minimum distance to trigger arc flight
    ArrivalDistance      = 5,       -- Studs threshold to reach waypoint
    ForwardProbeHeights  = { 1, 4, 8, 12 }, -- Multi-tier raycast heights
    ProbeDistance        = 15,
}

-- State variables
local walkSpeedActive = false
local walkHeartbeatConn = nil
local activeTeleportId = 0
local activePlatform = nil
local activeTeleportConn = nil

local keysDown = {
    [Enum.KeyCode.W] = false,
    [Enum.KeyCode.A] = false,
    [Enum.KeyCode.S] = false,
    [Enum.KeyCode.D] = false,
}

-- Track WASD keys
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and keysDown[input.KeyCode] ~= nil then
        keysDown[input.KeyCode] = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if keysDown[input.KeyCode] ~= nil then
        keysDown[input.KeyCode] = false
    end
end)

-- ==============================================================================
-- 2. CAMERA-RELATIVE VELOCITY WALKSPEED
-- ==============================================================================
local function startCustomWalk()
    if walkHeartbeatConn then walkHeartbeatConn:Disconnect() end
    
    walkHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not walkSpeedActive then return end
        if not rootPart or not humanoid or humanoid.Health <= 0 then return end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local moveDir = Vector3.zero
        local camCF = camera.CFrame

        if keysDown[Enum.KeyCode.W] then moveDir = moveDir + camCF.LookVector end
        if keysDown[Enum.KeyCode.S] then moveDir = moveDir - camCF.LookVector end
        if keysDown[Enum.KeyCode.A] then moveDir = moveDir - camCF.RightVector end
        if keysDown[Enum.KeyCode.D] then moveDir = moveDir + camCF.RightVector end

        -- Flatten direction to X/Z plane
        local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z)
        local curVel = rootPart.AssemblyLinearVelocity

        if flatDir.Magnitude > 0 then
            local unitDir = flatDir.Unit
            -- Override X/Z while preserving natural Y velocity (gravity/jumping)
            rootPart.AssemblyLinearVelocity = Vector3.new(
                unitDir.X * Config.WalkSpeedValue,
                curVel.Y,
                unitDir.Z * Config.WalkSpeedValue
            )
            -- Call MoveTo forward to keep default walking animation playing
            humanoid:MoveTo(rootPart.Position + unitDir * 20)
        else
            -- Damp horizontal velocity when no keys are pressed
            rootPart.AssemblyLinearVelocity = Vector3.new(0, curVel.Y, 0)
            humanoid:MoveTo(rootPart.Position)
        end
    end)
end

local function stopCustomWalk()
    if walkHeartbeatConn then
        walkHeartbeatConn:Disconnect()
        walkHeartbeatConn = nil
    end
end

-- ==============================================================================
-- 3. ARC WAYPOINT GENERATION
-- ==============================================================================
local function buildArcWaypoints(startPos, targetPos)
    local distance = (startPos - targetPos).Magnitude
    local waypoints = {}

    -- Use high altitude arc if destination is beyond threshold
    if distance > Config.ArcMinDistance then
        local cruiseY = math.max(startPos.Y, targetPos.Y) + Config.CruiseAltitudeOffset
        -- 1. Climb up to cruise altitude
        table.insert(waypoints, Vector3.new(startPos.X, cruiseY, startPos.Z))
        -- 2. Fly horizontally across the sky
        table.insert(waypoints, Vector3.new(targetPos.X, cruiseY, targetPos.Z))
    end

    -- 3. Final target
    table.insert(waypoints, targetPos)
    return waypoints
end

-- ==============================================================================
-- 4. MULTI-HEIGHT OBSTACLE DETECTION (Forward Probing)
-- ==============================================================================
local function checkForwardObstacles(origin, forwardUnit)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { character, activePlatform }
    rayParams.FilterType = RaycastFilterType.Exclude

    local highestObstacleY = nil

    for _, heightOffset in ipairs(Config.ForwardProbeHeights) do
        local rayOrigin = origin + Vector3.new(0, heightOffset, 0)
        local result = workspace:Raycast(rayOrigin, forwardUnit * Config.ProbeDistance, rayParams)
        if result then
            highestObstacleY = math.max(highestObstacleY or result.Position.Y, result.Position.Y)
        end
    end

    return highestObstacleY
end

-- ==============================================================================
-- 5. CFRAME INTERPOLATION WITH ANCHORED SUPPORT PLATFORM
-- ==============================================================================
local function cancelActiveTeleport()
    activeTeleportId += 1
    if activeTeleportConn then
        activeTeleportConn:Disconnect()
        activeTeleportConn = nil
    end
    if activePlatform then
        activePlatform:Destroy()
        activePlatform = nil
    end
    print("[MovementTest] Active teleport cancelled.")
end

local function startArcTeleport(targetPosition)
    if not rootPart or not humanoid or humanoid.Health <= 0 then return end

    -- Cancel previous teleport if one was running
    cancelActiveTeleport()

    activeTeleportId += 1
    local currentSessionId = activeTeleportId

    -- Build waypoint path
    local waypoints = buildArcWaypoints(rootPart.Position, targetPosition)
    local waypointIdx = 1

    -- Create invisible anchored support platform 3.1 studs beneath the player
    local platform = Instance.new("Part")
    platform.Name = "TestMovement_Platform"
    platform.Size = Vector3.new(8, 1, 8)
    platform.Transparency = 0.6 -- semi-transparent for visibility in testing
    platform.Color = Color3.fromRGB(0, 200, 255)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Parent = workspace
    activePlatform = platform

    print(string.format("[MovementTest] Starting Arc Teleport across %d waypoints...", #waypoints))

    activeTeleportConn = RunService.Heartbeat:Connect(function(deltaTime)
        if activeTeleportId ~= currentSessionId or not rootPart or humanoid.Health <= 0 then
            cancelActiveTeleport()
            return
        end

        local currentTarget = waypoints[waypointIdx]
        local toTarget = currentTarget - rootPart.Position
        local distance = toTarget.Magnitude

        -- Check if current waypoint reached
        if distance <= Config.ArrivalDistance then
            rootPart.CFrame = rootPart.CFrame - rootPart.Position + currentTarget
            rootPart.AssemblyLinearVelocity = Vector3.zero
            waypointIdx += 1

            -- Completed all waypoints
            if waypointIdx > #waypoints then
                print("[MovementTest] Successfully arrived at destination!")
                cancelActiveTeleport()
                return
            end

            currentTarget = waypoints[waypointIdx]
            toTarget = currentTarget - rootPart.Position
            distance = toTarget.Magnitude
        end

        local stepDir = toTarget.Unit
        local stepDist = math.min(Config.TeleportSpeed * deltaTime, distance)

        -- Perform forward raycast check
        local obstacleY = checkForwardObstacles(rootPart.Position, stepDir)
        local riseOffset = Vector3.zero
        if obstacleY and obstacleY > rootPart.Position.Y then
            -- Obstacle ahead, bias step upwards
            riseOffset = Vector3.new(0, math.min(4, obstacleY - rootPart.Position.Y + 2), 0)
        end

        -- Interpolate root position towards waypoint
        local nextPos = rootPart.Position + (stepDir * stepDist) + riseOffset
        rootPart.CFrame = CFrame.lookAt(nextPos, nextPos + stepDir)
        rootPart.AssemblyLinearVelocity = Vector3.zero

        -- Sync support platform directly 3.1 studs under the feet
        if platform and platform.Parent then
            platform.CFrame = rootPart.CFrame * CFrame.new(0, -3.1, 0)
        end
    end)
end

-- ==============================================================================
-- 6. TEST CONTROLS & KEYBINDS
-- ==============================================================================
print([[
==============================================
[Movement Replication Test Initialized]
Keybinds:
  [X] - Toggle Camera-Relative Velocity WalkSpeed
  [T] - Arc Teleport to Mouse Cursor Target
  [C] - Cancel Current Teleport
==============================================
]])

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    -- [X] Toggle WalkSpeed
    if input.KeyCode == Enum.KeyCode.X then
        walkSpeedActive = not walkSpeedActive
        if walkSpeedActive then
            print("[MovementTest] WalkSpeed Enabled (Speed: " .. Config.WalkSpeedValue .. ")")
            startCustomWalk()
        else
            print("[MovementTest] WalkSpeed Disabled")
            stopCustomWalk()
        end
    end

    -- [T] Arc Teleport to Mouse Position
    if input.KeyCode == Enum.KeyCode.T then
        local mouse = LocalPlayer:GetMouse()
        if mouse and mouse.Hit then
            local targetPos = mouse.Hit.Position + Vector3.new(0, 3, 0)
            print(string.format("[MovementTest] Teleporting to (%.1f, %.1f, %.1f)...", targetPos.X, targetPos.Y, targetPos.Z))
            startArcTeleport(targetPos)
        end
    end

    -- [C] Cancel Teleport
    if input.KeyCode == Enum.KeyCode.C then
        cancelActiveTeleport()
    end
end)

