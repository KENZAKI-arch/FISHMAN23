--[[
    ========================================================================
    ✈️ GEPPO WASD FLIGHT ENGINE (NO SEATS / 100% RELIABLE)
    ========================================================================
    Features:
      - Full 3D WASD flight steered by your Camera:
          * W = Fly Forward
          * S = Fly Backward
          * A = Strafe Left
          * D = Strafe Right
          * Space = Fly Up
          * LeftShift / LeftCtrl = Fly Down
          * Release keys = Stable Hover in place (no falling)
      - Toggle with 'F' key or on-screen GUI button
      - Automatically fires "Sky Walk2" (Geppo) remote every 1.0 second
      - Plays authentic Geppo clouds under your feet while flying
      - Zero seats used, zero capability/plugin kicks (NSE1 safe)
    ========================================================================
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local env = getgenv and getgenv() or shared

env.GeppoWASDFlight = env.GeppoWASDFlight or {
    IsFlying = false,
    FlySpeed = 95,
    GeppoInterval = 1.0, -- Fires Geppo remote every 1.0s
    Noclip = true,
}

local Flight = env.GeppoWASDFlight

-- Safe Character & RootPart detection
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

-- ========================================================================
-- 1. GEPPO REMOTE PULSE (1-SECOND INTERVAL)
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

        -- Fire the game's official remote
        local events = ReplicatedStorage:FindFirstChild("Events")
        local skillRemote = events and events:FindFirstChild("Skill")
        if skillRemote then
            local args = {
                [1] = skillName,
                [2] = {
                    ["char"] = char,
                    ["cf"] = cf,
                }
            }
            skillRemote:InvokeServer(unpack(args))
        end
    end)
end

local geppoThread = nil

local function startGeppoLoop()
    if geppoThread then return end
    geppoThread = task.spawn(function()
        while Flight.IsFlying do
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
-- 2. BODY MOVERS & WASD ENGINE
-- ========================================================================
local activeBV = nil
local activeBG = nil
local renderConn = nil
local noclipConn = nil

local function startNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        if not Flight.IsFlying or not Flight.Noclip then return end
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

function Flight.StartFlight()
    local char = getCharacter()
    local hrp = getRootPart(char)
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not hrp or not hum then return end

    Flight.IsFlying = true

    -- Clean up any existing body movers
    if hrp:FindFirstChild("GeppoFlyBV") then hrp.GeppoFlyBV:Destroy() end
    if hrp:FindFirstChild("GeppoFlyBG") then hrp.GeppoFlyBG:Destroy() end

    -- BodyVelocity: Handles smooth WASD movement & antigravity hover
    local bv = Instance.new("BodyVelocity")
    bv.Name = "GeppoFlyBV"
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    bv.P = 10000
    bv.Parent = hrp
    activeBV = bv

    -- BodyGyro: Keeps you facing camera direction smoothly
    local bg = Instance.new("BodyGyro")
    bg.Name = "GeppoFlyBG"
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 3000
    bg.D = 400
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    activeBG = bg

    startGeppoLoop()
    startNoclip()

    -- WASD Flight Loop
    if renderConn then renderConn:Disconnect() end
    renderConn = RunService.RenderStepped:Connect(function()
        if not Flight.IsFlying or not hrp or not hrp.Parent or not bv or not bv.Parent then
            Flight.StopFlight()
            return
        end

        hum.PlatformStand = true

        -- Calculate 3D movement direction relative to camera
        local moveDir = Vector3.zero
        local camCF = Camera.CFrame

        -- Only read inputs if not typing in chat
        if not UserInputService:GetFocusedTextBox() then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - camCF.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
        end

        local speed = Flight.FlySpeed or 95

        if moveDir.Magnitude > 0 then
            bv.Velocity = moveDir.Unit * speed
        else
            -- Stable hover in mid-air
            bv.Velocity = Vector3.zero
        end

        -- Rotate character towards camera view
        bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + camCF.LookVector)
    end)
end

function Flight.StopFlight()
    Flight.IsFlying = false

    stopGeppoLoop()
    stopNoclip()

    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end

    pcall(function()
        if activeBV and activeBV.Parent then activeBV:Destroy() end
        if activeBG and activeBG.Parent then activeBG:Destroy() end
    end)
    activeBV = nil
    activeBG = nil

    local char = getCharacter()
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

function Flight.Toggle()
    if Flight.IsFlying then
        Flight.StopFlight()
    else
        Flight.StartFlight()
    end
end

-- ========================================================================
-- 3. KEYBOARD TOGGLE ('F' KEY)
-- ========================================================================
pcall(function()
    if env._GeppoKeyConn then env._GeppoKeyConn:Disconnect() end
    env._GeppoKeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.F then
            Flight.Toggle()
            if Flight.UpdateUI then Flight.UpdateUI() end
        end
    end)
end)

-- ========================================================================
-- 4. CLEAN, SAFE UI (PARENTS TO PLAYERGUI)
-- ========================================================================
function Flight.CreateUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    if playerGui:FindFirstChild("GeppoWASDUI") then
        pcall(function() playerGui.GeppoWASDUI:Destroy() end)
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GeppoWASDUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = playerGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 240, 0, 185)
    Frame.Position = UDim2.new(0.5, -120, 0.35, -90)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 200, 255)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = Frame

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -30, 0, 28)
    Title.Position = UDim2.new(0, 10, 0, 4)
    Title.BackgroundTransparency = 1
    Title.Text = "Geppo WASD Flight [F]"
    Title.TextColor3 = Color3.fromRGB(0, 215, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -26, 0, 4)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = Frame

    -- Toggle Button
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, -20, 0, 36)
    ToggleBtn.Position = UDim2.new(0, 10, 0, 36)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
    ToggleBtn.Text = "FLY: OFF [F]"
    ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 12
    ToggleBtn.Parent = Frame
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

    -- Status
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -20, 0, 18)
    Status.Position = UDim2.new(0, 10, 0, 78)
    Status.BackgroundTransparency = 1
    Status.Text = "WASD = Fly | Space/Shift = Up/Down"
    Status.TextColor3 = Color3.fromRGB(140, 155, 175)
    Status.Font = Enum.Font.Gotham
    Status.TextSize = 10
    Status.Parent = Frame

    -- Speed Controls
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(0, 85, 0, 24)
    SpeedLabel.Position = UDim2.new(0, 10, 0, 102)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "Fly Speed:"
    SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    SpeedLabel.Font = Enum.Font.Gotham
    SpeedLabel.TextSize = 11
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = Frame

    local SpeedBox = Instance.new("TextBox")
    SpeedBox.Size = UDim2.new(0, 55, 0, 22)
    SpeedBox.Position = UDim2.new(0, 95, 0, 103)
    SpeedBox.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    SpeedBox.Text = tostring(Flight.FlySpeed)
    SpeedBox.TextColor3 = Color3.fromRGB(0, 255, 180)
    SpeedBox.Font = Enum.Font.GothamBold
    SpeedBox.TextSize = 11
    SpeedBox.Parent = Frame
    Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 4)

    -- Noclip Toggle
    local NoclipBtn = Instance.new("TextButton")
    NoclipBtn.Size = UDim2.new(1, -20, 0, 26)
    NoclipBtn.Position = UDim2.new(0, 10, 0, 140)
    NoclipBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 120)
    NoclipBtn.Text = "Noclip: ON ✓"
    NoclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoclipBtn.Font = Enum.Font.GothamBold
    NoclipBtn.TextSize = 10
    NoclipBtn.Parent = Frame
    Instance.new("UICorner", NoclipBtn).CornerRadius = UDim.new(0, 4)

    local function updateUIState()
        if Flight.IsFlying then
            ToggleBtn.Text = "FLY: ACTIVE ✓ [F]"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 90)
            ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Status.Text = "Geppo Remote: 1s Pulse | Active"
            Status.TextColor3 = Color3.fromRGB(0, 255, 180)
        else
            ToggleBtn.Text = "FLY: OFF [F]"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
            ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            Status.Text = "WASD = Fly | Space/Shift = Up/Down"
            Status.TextColor3 = Color3.fromRGB(140, 155, 175)
        end
    end

    Flight.UpdateUI = updateUIState

    ToggleBtn.MouseButton1Click:Connect(function()
        Flight.Toggle()
        updateUIState()
    end)

    NoclipBtn.MouseButton1Click:Connect(function()
        Flight.Noclip = not Flight.Noclip
        if Flight.Noclip then
            NoclipBtn.Text = "Noclip: ON ✓"
            NoclipBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 120)
        else
            NoclipBtn.Text = "Noclip: OFF ✕"
            NoclipBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        end
    end)

    SpeedBox.FocusLost:Connect(function()
        local val = tonumber(SpeedBox.Text)
        if val and val > 0 then
            Flight.FlySpeed = val
        else
            SpeedBox.Text = tostring(Flight.FlySpeed)
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Flight.StopFlight()
        ScreenGui:Destroy()
    end)

    updateUIState()
    return ScreenGui
end

pcall(function()
    Flight.CreateUI()
end)

return Flight
