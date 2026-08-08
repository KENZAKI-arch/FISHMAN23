local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FLY_SPEED = 75
local isFlying = false
local flyBv = nil

local lastGeppoTick = 0
local lastGeppoRemoteTick = 0

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpecialFlyGui"
ScreenGui.ResetOnSpawn = false

local success = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 40)
ToggleButton.Position = UDim2.new(0.5, -75, 0, 20)
ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Text = "FLY: OFF [F]"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)

local function drainStamina(character)
    local currentTick = tick()
    if currentTick - lastStaminaTick < 0.3 then return end
    lastStaminaTick = currentTick
    
    local player = game.Players.LocalPlayer
    
    -- 1. Try to drain from LocalPlayer.Data (where energy usually lives in these games)
    local dataFolder = player:FindFirstChild("Data")
    if dataFolder then
        local energy = dataFolder:FindFirstChild("Energy") or dataFolder:FindFirstChild("Stamina")
        if energy and energy:IsA("NumberValue") then
            energy.Value = math.max(0, energy.Value - 25) -- Geppo usually takes ~25 energy
        end
    end
    
    -- 2. Try to drain from Character
    local charEnergy = character:FindFirstChild("Energy") or character:FindFirstChild("Stamina")
    if charEnergy and charEnergy:IsA("NumberValue") then
        charEnergy.Value = math.max(0, charEnergy.Value - 25)
    end
    
    -- 3. Force server drain by firing a generic mobility remote (Dash) since you don't have Geppo
    pcall(function()
        local combatRegister = game.ReplicatedStorage:FindFirstChild("Events") and game.ReplicatedStorage.Events:FindFirstChild("CombatRegister")
        if combatRegister then
            combatRegister:InvokeServer({
                [1] = "mobility",
                [2] = "Dash"
            })
        end
    end)
end

local function stopFly()
    isFlying = false
    ToggleButton.Text = "FLY: OFF [F]"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        local existingBv = hrp:FindFirstChild("SpecialFlyBV")
        if existingBv then existingBv:Destroy() end
    end
    flyBv = nil
end

local function startFly()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    
    isFlying = true
    ToggleButton.Text = "FLY: ON [F]"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
    
    flyBv = Instance.new("BodyVelocity")
    flyBv.Name = "SpecialFlyBV"
    flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBv.Velocity = Vector3.new(0, 0, 0)
    flyBv.Parent = hrp
end

local function toggleFly()
    if isFlying then stopFly() else startFly() end
end

ToggleButton.MouseButton1Click:Connect(toggleFly)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        toggleFly()
    end
end)

RunService.RenderStepped:Connect(function()
    if not isFlying then return end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
        stopFly()
        return
    end
    
    local hrp = character.HumanoidRootPart
    local humanoid = character.Humanoid
    
    if not flyBv or flyBv.Parent ~= hrp then
        stopFly()
        startFly()
    end
    
    -- Calculate movement direction relative to camera
    local moveDir = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
    
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
    
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
        flyBv.Velocity = moveDir * FLY_SPEED
        
        -- Drain stamina silently while moving
        syncFlightStamina(character)
        
        -- Face movement direction slightly
        local lookPos = hrp.Position + (Camera.CFrame.LookVector * 10)
        hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(lookPos.X, hrp.Position.Y, lookPos.Z))
    else
        flyBv.Velocity = Vector3.new(0, 0, 0)
    end
    
    -- Anti-fall/noclip loop
    humanoid.PlatformStand = true
end)

-- Cleanup when script restarts
if getgenv().StopSpecialFly then pcall(function() getgenv().StopSpecialFly() end) end
getgenv().StopSpecialFly = function()
    stopFly()
    ScreenGui:Destroy()
end
