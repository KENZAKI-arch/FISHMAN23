--[[
    ========================================================================
    ✈️ FLIGHT & GLIDE ENGINE (WASD HOVER + AERODYNAMIC GLIDE)
    ========================================================================
    Features:
      - ✈️ Dual-Mode Flight System:
          * HOVER FLIGHT ('F' key): 3D WASD camera-steered flight with rock-solid hover.
          * AERODYNAMIC GLIDE ('G' key or Space in mid-air): High-speed gliding steered by camera.
      - 🦅 Realistic Aerodynamics:
          * Pitch down to dive -> gains airspeed (up to GlideMaxSpeed)
          * Pitch up / level off -> trades speed for lift (slower descent)
          * Smooth camera look vector steering with body roll & pitch
      - 🎵 Authentic GPO Assets Integration (with standalone fallbacks):
          * Plays 'Glide' animation (game.ReplicatedStorage.Util.Glide.Glide)
          * Dynamically scales wind loop audio (pitch & volume scale with airspeed)
          * Spawns authentic wind trails
      - 🛡️ Built-in Geppo Remote Pulse Loop (prevents server flight kicks)
      - 👻 Integrated Noclip support
      - 📊 Draggable On-Screen HUD with Airspeed gauge, telemetry & mobile buttons
    ========================================================================
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local env = getgenv and getgenv() or shared

env.GeppoWASDFlight = env.GeppoWASDFlight or {
    Mode = "None",              -- "None", "Hover", or "Glide"
    FlySpeed = 95,              -- WASD Hover speed
    GlideBaseSpeed = 105,       -- Base aerodynamic glide speed
    GlideMaxSpeed = 180,        -- Top dive speed
    GlideMinSpeed = 45,         -- Minimum stall speed
    DiveAcceleration = 55,      -- Speed gained per second while diving
    LiftDeceleration = 35,      -- Speed bled per second while climbing
    Noclip = true,
    GeppoInterval = 1.0,        -- Fires Geppo remote every 1.0s
    EnableSpaceGlide = true,    -- Holding space mid-air triggers glide
}

local Flight = env.GeppoWASDFlight

-- Backward compatibility aliases
Flight.IsFlying = false
Flight.IsGliding = false

-- ========================================================================
-- 1. SAFE CHARACTER & ROOTPART UTILITIES
-- ========================================================================
local function getCharacter()
    local char = nil
    pcall(function()
        local pChars = Workspace:FindFirstChild("PlayerCharacters")
        if pChars and pChars:FindFirstChild(LocalPlayer.Name) then
            char = pChars[LocalPlayer.Name]
        end
    end)
    return char or LocalPlayer.Character
end

local function getRootPart(char)
    char = char or getCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

local function getHumanoid(char)
    char = char or getCharacter()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function isFloorBelow(char, hrp, dist)
    dist = dist or 6
    local ray = Ray.new(hrp.Position, Vector3.new(0, -dist, 0))
    local ignore = { char, Workspace:FindFirstChild("Effects") }
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, ignore)
    return hit ~= nil and hit.CanCollide
end

-- ========================================================================
-- 2. GEPPO REMOTE PULSE (PREVENTS SERVER SPEED/FLIGHT CHECKS)
-- ========================================================================
local function getSkillName()
    local name = "Sky Walk2"
    pcall(function()
        local statsFolder = ReplicatedStorage:FindFirstChild("Stats" .. LocalPlayer.Name)
        local fs = statsFolder and statsFolder:FindFirstChild("Stats") and statsFolder.Stats:FindFirstChild("FightingStyle")
        if fs and fs.Value ~= "" then
            if fs.Value == "Rokushiki" then name = "Geppo"
            elseif fs.Value == "BlackLeg" then name = "Sky Walk"
            elseif fs.Value == "Kamishiki" then name = "KamishikiGeppo"
            end
        end
    end)
    return name
end

local function castGeppoPulse()
    pcall(function()
        local char = getCharacter()
        local hrp = getRootPart(char)
        if not char or not hrp then return end

        local cf = hrp.CFrame * CFrame.new(0, -2, 0)
        local skillName = getSkillName()

        -- Play visual Geppo cloud locally
        if _G.PlayEffect then
            pcall(function()
                _G.PlayEffect("Geppo", nil, { char = char, cf = cf })
            end)
        end

        -- Fire game remote
        local events = ReplicatedStorage:FindFirstChild("Events")
        local skillRemote = events and events:FindFirstChild("Skill")
        if skillRemote then
            skillRemote:InvokeServer(skillName, {
                ["char"] = char,
                ["cf"] = cf,
            })
        end
    end)
end

local geppoThread = nil
local function startGeppoLoop()
    if geppoThread then return end
    geppoThread = task.spawn(function()
        while Flight.Mode ~= "None" do
            castGeppoPulse()
            task.wait(Flight.GeppoInterval or 1.0)
        end
        geppoThread = nil
    end)
end

local function stopGeppoLoop()
    if geppoThread then
        task.cancel(geppoThread)
        geppoThread = nil
    end
end

-- ========================================================================
-- 3. NOCLIP ENGINE
-- ========================================================================
local noclipConn = nil
local function startNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        if Flight.Mode == "None" or not Flight.Noclip then return end
        pcall(function()
            local char = getCharacter()
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

local function stopNoclip()
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
end

-- ========================================================================
-- 4. GLIDE ASSETS, AUDIO & ANIMATION CONTROLLER
-- ========================================================================
local activeGlideAnimTrack = nil
local activeGlideLoopSound = nil
local activeGlideTrailParts = {}

local function startGlideVFX(char, hrp, hum)
    -- Clean previous
    table.clear(activeGlideTrailParts)

    pcall(function()
        local util = ReplicatedStorage:FindFirstChild("Util")
        local glideFolder = util and util:FindFirstChild("Glide")
        if not glideFolder then return end

        -- 1. Animation
        local animObj = glideFolder:FindFirstChild("Glide")
        if animObj and animObj:IsA("Animation") and hum then
            local animator = hum:FindFirstChildOfClass("Animator") or hum
            activeGlideAnimTrack = animator:LoadAnimation(animObj)
            activeGlideAnimTrack.Priority = Enum.AnimationPriority.Action4
            activeGlideAnimTrack:Play(0.2)
        end

        -- 2. Start Sound
        local startSound = glideFolder:FindFirstChild("start")
        if startSound and startSound:IsA("Sound") and char:FindFirstChild("Head") then
            local snd = startSound:Clone()
            snd.Parent = char.Head
            snd:Play()
            task.delay(1.5, function() pcall(function() snd:Destroy() end) end)
        end

        -- 3. Loop Sound
        local loopSound = glideFolder:FindFirstChild("loop")
        if loopSound and loopSound:IsA("Sound") and char:FindFirstChild("Head") then
            local loop = loopSound:Clone()
            loop.Looped = true
            loop.Volume = 0.5
            loop.Pitch = 1.0
            loop.Parent = char.Head
            loop:Play()
            activeGlideLoopSound = loop
        end

        -- 4. Trails
        local trailTemplate = glideFolder:FindFirstChild("Trail")
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or hrp
        if trailTemplate and torso then
            local att0 = Instance.new("Attachment")
            att0.Name = "GlideAtt0"
            att0.Position = Vector3.new(0, 0.4, 0)
            att0.Parent = torso

            local att1 = Instance.new("Attachment")
            att1.Name = "GlideAtt1"
            att1.Position = Vector3.new(0, -0.4, 0)
            att1.Parent = torso

            local tr = trailTemplate:Clone()
            tr.Attachment0 = att0
            tr.Attachment1 = att1
            tr.Parent = torso

            table.insert(activeGlideTrailParts, att0)
            table.insert(activeGlideTrailParts, att1)
            table.insert(activeGlideTrailParts, tr)
        end
    end)
end

local function stopGlideVFX()
    pcall(function()
        if activeGlideAnimTrack then
            activeGlideAnimTrack:Stop(0.25)
            activeGlideAnimTrack = nil
        end
    end)

    pcall(function()
        if activeGlideLoopSound and activeGlideLoopSound.Parent then
            local s = activeGlideLoopSound
            local tween = TweenService:Create(s, TweenInfo.new(0.3), { Volume = 0 })
            tween:Play()
            task.delay(0.35, function() pcall(function() s:Destroy() end) end)
            activeGlideLoopSound = nil
        end
    end)

    for _, obj in ipairs(activeGlideTrailParts) do
        pcall(function() obj:Destroy() end)
    end
    table.clear(activeGlideTrailParts)
end

-- ========================================================================
-- 5. UNIFIED MOVEMENT & AERODYNAMIC GLIDE LOOP
-- ========================================================================
local activeBV = nil
local activeBG = nil
local renderConn = nil
local currentAirspeed = Flight.GlideBaseSpeed
local lastStepTime = tick()

local function clearMovers(hrp)
    pcall(function()
        if activeBV and activeBV.Parent then activeBV:Destroy() end
        if activeBG and activeBG.Parent then activeBG:Destroy() end
        if hrp then
            if hrp:FindFirstChild("GeppoFlyBV") then hrp.GeppoFlyBV:Destroy() end
            if hrp:FindFirstChild("GeppoFlyBG") then hrp.GeppoFlyBG:Destroy() end
        end
    end)
    activeBV = nil
    activeBG = nil
end

local function setupMovers(hrp)
    clearMovers(hrp)

    local bv = Instance.new("BodyVelocity")
    bv.Name = "GeppoFlyBV"
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    bv.P = 15000
    bv.Parent = hrp
    activeBV = bv

    local bg = Instance.new("BodyGyro")
    bg.Name = "GeppoFlyBG"
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 4000
    bg.D = 350
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    activeBG = bg

    return bv, bg
end

local function onRenderStep()
    local char = getCharacter()
    local hrp = getRootPart(char)
    local hum = getHumanoid(char)

    if Flight.Mode == "None" or not hrp or not hrp.Parent or not activeBV or not activeBV.Parent then
        Flight.SetMode("None")
        return
    end

    local now = tick()
    local dt = math.clamp(now - lastStepTime, 0.001, 0.1)
    lastStepTime = now

    hum.PlatformStand = true
    hum.AutoRotate = false

    local camCF = Camera.CFrame
    local lookVec = camCF.LookVector
    local rightVec = camCF.RightVector

    -- --------------------------------------------------------------------
    -- A. HOVER FLIGHT MODE (3D WASD)
    -- --------------------------------------------------------------------
    if Flight.Mode == "Hover" then
        local moveDir = Vector3.zero
        if not UserInputService:GetFocusedTextBox() then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + lookVec end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - lookVec end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - rightVec end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + rightVec end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
        end

        local speed = Flight.FlySpeed or 95
        if moveDir.Magnitude > 0 then
            activeBV.Velocity = moveDir.Unit * speed
        else
            activeBV.Velocity = Vector3.zero -- Absolute hover in place
        end

        activeBG.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + lookVec)
        Flight.CurrentAirspeed = (activeBV.Velocity).Magnitude

    -- --------------------------------------------------------------------
    -- B. AERODYNAMIC GLIDE MODE (CAMERA-STEERED MOMENTUM)
    -- --------------------------------------------------------------------
    elseif Flight.Mode == "Glide" then
        local pitch = lookVec.Y -- -1 (looking straight down) to +1 (straight up)

        -- 1. Aerodynamic Speed Calculation:
        if pitch < -0.15 then
            -- Diving down: gain massive speed
            local diveIntensity = math.clamp((-pitch - 0.15) / 0.85, 0, 1)
            currentAirspeed = math.min(Flight.GlideMaxSpeed, currentAirspeed + (Flight.DiveAcceleration * dt * (1 + diveIntensity)))
        elseif pitch > 0.15 then
            -- Climbing up: trade airspeed for altitude/lift
            local climbIntensity = math.clamp((pitch - 0.15) / 0.85, 0, 1)
            currentAirspeed = math.max(Flight.GlideMinSpeed, currentAirspeed - (Flight.LiftDeceleration * dt * (1 + climbIntensity)))
        else
            -- Level flight: smoothly return towards GlideBaseSpeed
            if currentAirspeed > Flight.GlideBaseSpeed then
                currentAirspeed = math.max(Flight.GlideBaseSpeed, currentAirspeed - (15 * dt))
            elseif currentAirspeed < Flight.GlideBaseSpeed then
                currentAirspeed = math.min(Flight.GlideBaseSpeed, currentAirspeed + (15 * dt))
            end
        end

        -- 2. Forward Velocity Vector:
        local targetVelocity = lookVec * currentAirspeed

        -- Slight lift boost when flying horizontal to give natural glide ratio
        if pitch >= -0.15 and pitch <= 0.2 then
            targetVelocity = Vector3.new(targetVelocity.X, math.clamp(targetVelocity.Y, -8, 8), targetVelocity.Z)
        end

        activeBV.Velocity = activeBV.Velocity:Lerp(targetVelocity, math.clamp(dt * 10, 0.1, 1))
        Flight.CurrentAirspeed = activeBV.Velocity.Magnitude

        -- 3. Dynamic Orientation:
        -- Character smoothly tilts towards camera aim
        local targetRot = CFrame.lookAt(hrp.Position, hrp.Position + lookVec)
        activeBG.CFrame = activeBG.CFrame:Lerp(targetRot, math.clamp(dt * 12, 0.1, 1))

        -- 4. Dynamic Audio Feedback:
        if activeGlideLoopSound and activeGlideLoopSound.Parent then
            activeGlideLoopSound.Pitch = math.clamp(Flight.CurrentAirspeed / 45, 0.7, 2.2)
            activeGlideLoopSound.Volume = math.clamp(0.3 + (Flight.CurrentAirspeed / 70), 0.3, 1.6)
        end

        -- 5. Dynamic Animation Speed:
        if activeGlideAnimTrack then
            activeGlideAnimTrack:AdjustSpeed(math.clamp(Flight.CurrentAirspeed / 50, 0.8, 2.5))
        end

        -- 6. Floor check: Land automatically if touching floor
        if isFloorBelow(char, hrp, 3.5) then
            Flight.SetMode("None")
            return
        end
    end

    if Flight.UpdateUI then
        Flight.UpdateUI()
    end
end

-- ========================================================================
-- 6. STATE MANAGER (HOVER, GLIDE, OFF)
-- ========================================================================
function Flight.SetMode(newMode)
    if Flight.Mode == newMode then return end

    local char = getCharacter()
    local hrp = getRootPart(char)
    local hum = getHumanoid(char)

    local previousMode = Flight.Mode
    Flight.Mode = newMode
    Flight.IsFlying = (newMode == "Hover")
    Flight.IsGliding = (newMode == "Glide")

    if newMode == "None" then
        -- Shutdown
        if renderConn then
            renderConn:Disconnect()
            renderConn = nil
        end
        clearMovers(hrp)
        stopGlideVFX()
        stopGeppoLoop()
        stopNoclip()

        if hum then
            hum.PlatformStand = false
            hum.AutoRotate = true
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        Flight.CurrentAirspeed = 0

    elseif newMode == "Hover" then
        -- Start WASD Hover Flight
        if not hrp or not hum then return end
        stopGlideVFX()
        setupMovers(hrp)
        startGeppoLoop()
        startNoclip()

        lastStepTime = tick()
        if not renderConn then
            renderConn = RunService.RenderStepped:Connect(onRenderStep)
        end

    elseif newMode == "Glide" then
        -- Start Aerodynamic Glide
        if not hrp or not hum then return end
        setupMovers(hrp)
        currentAirspeed = Flight.GlideBaseSpeed or 105
        startGlideVFX(char, hrp, hum)
        startGeppoLoop()
        startNoclip()

        lastStepTime = tick()
        if not renderConn then
            renderConn = RunService.RenderStepped:Connect(onRenderStep)
        end
    end

    if Flight.UpdateUI then
        Flight.UpdateUI()
    end
end

function Flight.ToggleHover()
    if Flight.Mode == "Hover" then
        Flight.SetMode("None")
    else
        Flight.SetMode("Hover")
    end
end

function Flight.ToggleGlide()
    if Flight.Mode == "Glide" then
        Flight.SetMode("None")
    else
        Flight.SetMode("Glide")
    end
end

-- Compatibility wrappers
Flight.StartFlight = function() Flight.SetMode("Hover") end
Flight.StopFlight = function() Flight.SetMode("None") end
Flight.Toggle = Flight.ToggleHover

-- ========================================================================
-- 7. INPUT & HOTKEY BINDINGS
-- ========================================================================
pcall(function()
    if env._FlightKeyConn then env._FlightKeyConn:Disconnect() end
    env._FlightKeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end

        -- 'F' Key: Toggle Hover Flight
        if input.KeyCode == Enum.KeyCode.F then
            Flight.ToggleHover()

        -- 'G' Key: Toggle Aerodynamic Glide
        elseif input.KeyCode == Enum.KeyCode.G then
            Flight.ToggleGlide()

        -- Space mid-air glide trigger
        elseif input.KeyCode == Enum.KeyCode.Space and Flight.EnableSpaceGlide and Flight.Mode == "None" then
            local char = getCharacter()
            local hrp = getRootPart(char)
            if hrp and not isFloorBelow(char, hrp, 7) then
                Flight.SetMode("Glide")
            end
        end
    end)
end)

-- ========================================================================
-- 8. MODERN ON-SCREEN HUD & TELEMETRY PANEL
-- ========================================================================
function Flight.CreateUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    if playerGui:FindFirstChild("FlightGlideUI") then
        pcall(function() playerGui.FlightGlideUI:Destroy() end)
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FlightGlideUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = playerGui

    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 260, 0, 230)
    Frame.Position = UDim2.new(0.5, -130, 0.3, -115)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 200, 255)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = Frame

    -- Title Bar
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -30, 0, 28)
    Title.Position = UDim2.new(0, 12, 0, 4)
    Title.BackgroundTransparency = 1
    Title.Text = "✈️ Flight & Glide Engine"
    Title.TextColor3 = Color3.fromRGB(0, 220, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -28, 0, 5)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = Frame

    -- Mode Badge
    local ModeBadge = Instance.new("TextLabel")
    ModeBadge.Size = UDim2.new(1, -24, 0, 24)
    ModeBadge.Position = UDim2.new(0, 12, 0, 32)
    ModeBadge.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
    ModeBadge.Text = "MODE: OFF"
    ModeBadge.TextColor3 = Color3.fromRGB(160, 170, 185)
    ModeBadge.Font = Enum.Font.GothamBold
    ModeBadge.TextSize = 11
    ModeBadge.Parent = Frame
    Instance.new("UICorner", ModeBadge).CornerRadius = UDim.new(0, 5)

    -- Airspeed Bar & Readout
    local AirspeedLabel = Instance.new("TextLabel")
    AirspeedLabel.Size = UDim2.new(1, -24, 0, 16)
    AirspeedLabel.Position = UDim2.new(0, 12, 0, 60)
    AirspeedLabel.BackgroundTransparency = 1
    AirspeedLabel.Text = "Airspeed: 0 studs/s"
    AirspeedLabel.TextColor3 = Color3.fromRGB(0, 255, 190)
    AirspeedLabel.Font = Enum.Font.GothamMedium
    AirspeedLabel.TextSize = 10
    AirspeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    AirspeedLabel.Parent = Frame

    local BarBG = Instance.new("Frame")
    BarBG.Size = UDim2.new(1, -24, 0, 6)
    BarBG.Position = UDim2.new(0, 12, 0, 78)
    BarBG.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
    BarBG.BorderSizePixel = 0
    BarBG.Parent = Frame
    Instance.new("UICorner", BarBG).CornerRadius = UDim.new(0, 3)

    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(0, 230, 255)
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBG
    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(0, 3)

    -- Action Buttons Row
    local FlyBtn = Instance.new("TextButton")
    FlyBtn.Size = UDim2.new(0.5, -16, 0, 32)
    FlyBtn.Position = UDim2.new(0, 12, 0, 92)
    FlyBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    FlyBtn.Text = "✈️ FLY [F]"
    FlyBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    FlyBtn.Font = Enum.Font.GothamBold
    FlyBtn.TextSize = 11
    FlyBtn.Parent = Frame
    Instance.new("UICorner", FlyBtn).CornerRadius = UDim.new(0, 6)

    local GlideBtn = Instance.new("TextButton")
    GlideBtn.Size = UDim2.new(0.5, -16, 0, 32)
    GlideBtn.Position = UDim2.new(0.5, 4, 0, 92)
    GlideBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    GlideBtn.Text = "🦅 GLIDE [G]"
    GlideBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    GlideBtn.Font = Enum.Font.GothamBold
    GlideBtn.TextSize = 11
    GlideBtn.Parent = Frame
    Instance.new("UICorner", GlideBtn).CornerRadius = UDim.new(0, 6)

    -- Controls & Tips Label
    local Tips = Instance.new("TextLabel")
    Tips.Size = UDim2.new(1, -24, 0, 16)
    Tips.Position = UDim2.new(0, 12, 0, 130)
    Tips.BackgroundTransparency = 1
    Tips.Text = "Hover: WASD | Glide: Pitch down to dive"
    Tips.TextColor3 = Color3.fromRGB(120, 135, 155)
    Tips.Font = Enum.Font.Gotham
    Tips.TextSize = 9
    Tips.Parent = Frame

    -- Speed Input Row
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(0, 90, 0, 22)
    SpeedLabel.Position = UDim2.new(0, 12, 0, 152)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "Fly/Glide Spd:"
    SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    SpeedLabel.Font = Enum.Font.Gotham
    SpeedLabel.TextSize = 10
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = Frame

    local FlySpeedBox = Instance.new("TextBox")
    FlySpeedBox.Size = UDim2.new(0, 50, 0, 20)
    FlySpeedBox.Position = UDim2.new(0, 105, 0, 153)
    FlySpeedBox.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    FlySpeedBox.Text = tostring(Flight.FlySpeed)
    FlySpeedBox.TextColor3 = Color3.fromRGB(0, 255, 200)
    FlySpeedBox.Font = Enum.Font.GothamBold
    FlySpeedBox.TextSize = 10
    FlySpeedBox.Parent = Frame
    Instance.new("UICorner", FlySpeedBox).CornerRadius = UDim.new(0, 4)

    local GlideSpeedBox = Instance.new("TextBox")
    GlideSpeedBox.Size = UDim2.new(0, 50, 0, 20)
    GlideSpeedBox.Position = UDim2.new(0, 162, 0, 153)
    GlideSpeedBox.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    GlideSpeedBox.Text = tostring(Flight.GlideBaseSpeed)
    GlideSpeedBox.TextColor3 = Color3.fromRGB(255, 210, 0)
    GlideSpeedBox.Font = Enum.Font.GothamBold
    GlideSpeedBox.TextSize = 10
    GlideSpeedBox.Parent = Frame
    Instance.new("UICorner", GlideSpeedBox).CornerRadius = UDim.new(0, 4)

    -- Toggles Row: Noclip & AutoGlide
    local NoclipBtn = Instance.new("TextButton")
    NoclipBtn.Size = UDim2.new(0.5, -16, 0, 26)
    NoclipBtn.Position = UDim2.new(0, 12, 0, 185)
    NoclipBtn.BackgroundColor3 = Flight.Noclip and Color3.fromRGB(25, 80, 120) or Color3.fromRGB(70, 35, 35)
    NoclipBtn.Text = Flight.Noclip and "Noclip: ON ✓" or "Noclip: OFF ✕"
    NoclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoclipBtn.Font = Enum.Font.GothamBold
    NoclipBtn.TextSize = 10
    NoclipBtn.Parent = Frame
    Instance.new("UICorner", NoclipBtn).CornerRadius = UDim.new(0, 5)

    local MidAirBtn = Instance.new("TextButton")
    MidAirBtn.Size = UDim2.new(0.5, -16, 0, 26)
    MidAirBtn.Position = UDim2.new(0.5, 4, 0, 185)
    MidAirBtn.BackgroundColor3 = Flight.EnableSpaceGlide and Color3.fromRGB(30, 95, 85) or Color3.fromRGB(60, 60, 70)
    MidAirBtn.Text = Flight.EnableSpaceGlide and "Air Space: ON" or "Air Space: OFF"
    MidAirBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MidAirBtn.Font = Enum.Font.GothamBold
    MidAirBtn.TextSize = 10
    MidAirBtn.Parent = Frame
    Instance.new("UICorner", MidAirBtn).CornerRadius = UDim.new(0, 5)

    -- Dynamic UI updater
    local function updateUI()
        local spd = math.floor(Flight.CurrentAirspeed or 0)
        AirspeedLabel.Text = string.format("Airspeed: %d studs/s", spd)

        local maxCap = (Flight.Mode == "Glide") and Flight.GlideMaxSpeed or Flight.FlySpeed
        local fillRatio = math.clamp(spd / (maxCap or 100), 0, 1)
        BarFill.Size = UDim2.new(fillRatio, 0, 1, 0)

        if Flight.Mode == "Hover" then
            ModeBadge.Text = "MODE: ✈️ HOVER FLIGHT"
            ModeBadge.BackgroundColor3 = Color3.fromRGB(20, 110, 65)
            ModeBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
            FlyBtn.BackgroundColor3 = Color3.fromRGB(25, 150, 85)
            GlideBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            BarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 180)
        elseif Flight.Mode == "Glide" then
            ModeBadge.Text = "MODE: 🦅 AERODYNAMIC GLIDE"
            ModeBadge.BackgroundColor3 = Color3.fromRGB(150, 100, 20)
            ModeBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
            FlyBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            GlideBtn.BackgroundColor3 = Color3.fromRGB(210, 140, 25)
            BarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
        else
            ModeBadge.Text = "MODE: OFF"
            ModeBadge.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
            ModeBadge.TextColor3 = Color3.fromRGB(160, 170, 185)
            FlyBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            GlideBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            BarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        end
    end

    Flight.UpdateUI = updateUI

    -- Button Actions
    FlyBtn.MouseButton1Click:Connect(function()
        Flight.ToggleHover()
    end)

    GlideBtn.MouseButton1Click:Connect(function()
        Flight.ToggleGlide()
    end)

    NoclipBtn.MouseButton1Click:Connect(function()
        Flight.Noclip = not Flight.Noclip
        NoclipBtn.Text = Flight.Noclip and "Noclip: ON ✓" or "Noclip: OFF ✕"
        NoclipBtn.BackgroundColor3 = Flight.Noclip and Color3.fromRGB(25, 80, 120) or Color3.fromRGB(70, 35, 35)
    end)

    MidAirBtn.MouseButton1Click:Connect(function()
        Flight.EnableSpaceGlide = not Flight.EnableSpaceGlide
        MidAirBtn.Text = Flight.EnableSpaceGlide and "Air Space: ON" or "Air Space: OFF"
        MidAirBtn.BackgroundColor3 = Flight.EnableSpaceGlide and Color3.fromRGB(30, 95, 85) or Color3.fromRGB(60, 60, 70)
    end)

    FlySpeedBox.FocusLost:Connect(function()
        local val = tonumber(FlySpeedBox.Text)
        if val and val > 0 then
            Flight.FlySpeed = val
        else
            FlySpeedBox.Text = tostring(Flight.FlySpeed)
        end
    end)

    GlideSpeedBox.FocusLost:Connect(function()
        local val = tonumber(GlideSpeedBox.Text)
        if val and val > 0 then
            Flight.GlideBaseSpeed = val
        else
            GlideSpeedBox.Text = tostring(Flight.GlideBaseSpeed)
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Flight.SetMode("None")
        ScreenGui:Destroy()
    end)

    updateUI()
    return ScreenGui
end

pcall(function()
    Flight.CreateUI()
end)

return Flight
