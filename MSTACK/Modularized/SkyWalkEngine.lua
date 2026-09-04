local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Make it standalone by attaching to global environment
local env = getgenv and getgenv() or shared
env.SkyWalkEngine = env.SkyWalkEngine or {
    IsActive = false,
    NoclipActive = false,
}
local SkyWalkEngine = env.SkyWalkEngine

-- ==========================================
-- PHASE 1: Kill Client-Side Anti-Cheat
-- ==========================================
-- The AC script at ReplicatedFirst connects to:
--   1. Humanoid WalkSpeed changed signal
--   2. ScriptContext.Error signal
-- It also runs a while loop that sets WalkSpeed to -70 every second as a trap.
-- We disconnect ALL signals on the Humanoid to kill the WalkSpeed trap.

local function killClientAC()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- Get all connections on WalkSpeed and disconnect them
        -- This kills the AC's WalkSpeed monitor AND the -70 trap
        if getconnections then
            -- getconnections is available in most executors (Synapse, Krnl, Fluxus, etc.)
            for _, connection in ipairs(getconnections(humanoid:GetPropertyChangedSignal("WalkSpeed"))) do
                pcall(function()
                    connection:Disable()
                end)
            end
            
            -- Also kill the ScriptContext error reporter
            for _, connection in ipairs(getconnections(game:GetService("ScriptContext").Error)) do
                pcall(function()
                    -- Only disable non-core connections
                    if connection.Function then
                        connection:Disable()
                    end
                end)
            end
        end
    end)
end

-- ==========================================
-- PHASE 2: Invisible Seat (Server-Side Bypass)
-- ==========================================
-- When you sit in a seat, the server sets Humanoid.Sit = true
-- and COMPLETELY stops checking your speed/flight.
-- We create a tiny invisible seat welded to you.

local activeSeat = nil
local activeWeld = nil

local function createInvisibleSeat()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Destroy old seat if it exists
    if activeSeat and activeSeat.Parent then
        activeSeat:Destroy()
    end
    
    -- Create a tiny invisible seat
    local seat = Instance.new("Seat")
    seat.Size = Vector3.new(0.1, 0.1, 0.1)
    seat.Transparency = 1
    seat.CanCollide = false
    seat.Anchored = false
    seat.CFrame = hrp.CFrame
    seat.Name = "VehicleSeat" -- Blend in with game objects
    seat.Parent = workspace
    
    -- Weld the seat to the HRP so it follows us
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = seat
    weld.Part1 = hrp
    weld.Parent = seat
    
    -- Force sit in the seat
    seat:Sit(humanoid)
    
    activeSeat = seat
    activeWeld = weld
    
    return seat
end

local function destroySeat()
    pcall(function()
        if activeSeat and activeSeat.Parent then
            activeSeat:Destroy()
        end
        activeSeat = nil
        activeWeld = nil
        
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Sit = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end)
end

-- ==========================================
-- PHASE 3: Noclip Loop
-- ==========================================
local noclipConnection = nil

local function startNoclip()
    if noclipConnection then return end
    SkyWalkEngine.NoclipActive = true
    
    noclipConnection = RunService.Stepped:Connect(function()
        pcall(function()
            local character = LocalPlayer.Character
            if not character then return end
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            -- Also noclip the invisible seat
            if activeSeat and activeSeat.Parent then
                activeSeat.CanCollide = false
            end
        end)
    end)
end

local function stopNoclip()
    SkyWalkEngine.NoclipActive = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

-- ==========================================
-- PHASE 4: Full Speed Tween (AC Bypassed)
-- ==========================================
function SkyWalkEngine.Stop()
    SkyWalkEngine.IsActive = false
end

function SkyWalkEngine.FullCleanup()
    SkyWalkEngine.Stop()
    stopNoclip()
    destroySeat()
end

function SkyWalkEngine.TweenTo(targets, speed)
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Fallback to Torso/UpperTorso if HRP is destroyed (GodMode)
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if not hrp then return end
    
    if typeof(targets) == "CFrame" then
        targets = {targets}
    end
    
    -- Step 1: Kill the client AC
    killClientAC()
    
    -- Step 2: Create invisible seat (server bypass)
    createInvisibleSeat()
    
    -- Step 3: Start noclip
    startNoclip()
    
    SkyWalkEngine.IsActive = true
    speed = speed or 35
    
    local humanoid = character:FindFirstChild("Humanoid")
    
    -- Apply BodyVelocity to the HRP (or Torso if HRP destroyed)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Name = "geppo"
    bv.P = 10000
    bv.Parent = hrp
    
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.CFrame = hrp.CFrame
    bg.D = 100
    bg.Parent = hrp
    
    task.spawn(function()
        for _, targetCFrame in ipairs(targets) do
            if not SkyWalkEngine.IsActive then break end
            
            while SkyWalkEngine.IsActive and character and hrp.Parent do
                local currentPos = hrp.Position
                local targetPos = targetCFrame.Position
                local distance = (targetPos - currentPos).Magnitude
                
                if distance < 10 then
                    break
                end
                
                local direction = (targetPos - currentPos).Unit
                bv.Velocity = direction * speed
                
                pcall(function()
                    bg.CFrame = CFrame.lookAt(currentPos, targetPos)
                end)
                
                task.wait()
            end
        end
        
        -- Cleanup body movers
        pcall(function()
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end)
        
        SkyWalkEngine.IsActive = false
    end)
end

-- ==========================================
-- Convenience Functions
-- ==========================================
function SkyWalkEngine.MoveForward(distance, height, speed)
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if not hrp then return end
    
    height = height or 400
    speed = speed or 200
    local startLook = hrp.CFrame.LookVector
    
    local upPos = hrp.Position + Vector3.new(0, height, 0)
    local upCFrame = CFrame.lookAt(upPos, upPos + startLook)
    
    local finalPos = upPos + (startLook * distance)
    local finalCFrame = CFrame.lookAt(finalPos, finalPos + startLook)
    
    SkyWalkEngine.TweenTo({upCFrame, finalCFrame}, speed)
end

function SkyWalkEngine.FlyTo(targetCFrame, speed)
    SkyWalkEngine.TweenTo(targetCFrame, speed or 200)
end

-- ==========================================
-- UI
-- ==========================================
function SkyWalkEngine.CreateUI()
    local CoreGui = game:GetService("CoreGui")
    if CoreGui:FindFirstChild("SkyWalkUI") then
        CoreGui.SkyWalkUI:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SkyWalkUI"
    ScreenGui.Parent = CoreGui
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 240, 0, 270)
    Frame.Position = UDim2.new(0.5, -120, 0.5, -135)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Frame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(80, 255, 120)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = Frame
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -30, 0, 28)
    Title.BackgroundTransparency = 1
    Title.Text = "  SkyWalk v3 (AC Bypass)"
    Title.TextColor3 = Color3.fromRGB(80, 255, 120)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame
    
    -- Close
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -28, 0, 0)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = Frame
    
    -- Status
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, 0, 0, 14)
    Status.Position = UDim2.new(0, 0, 0, 26)
    Status.BackgroundTransparency = 1
    Status.Text = "AC: Not Bypassed | Seat: Off | Noclip: Off"
    Status.TextColor3 = Color3.fromRGB(140, 140, 140)
    Status.Font = Enum.Font.Gotham
    Status.TextSize = 9
    Status.Name = "Status"
    Status.Parent = Frame
    
    local function makeButton(text, pos, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.88, 0, 0, 32)
        btn.Position = UDim2.new(0.06, 0, 0, pos)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = Frame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn
        return btn
    end
    
    local BypassBtn = makeButton("Kill AC + Seat + Noclip", 46, Color3.fromRGB(180, 60, 60))
    local DashBtn = makeButton("Dash 1000 (Speed: 200)", 84, Color3.fromRGB(40, 120, 80))
    local SlideBtn = makeButton("Ground Slide 1000", 122, Color3.fromRGB(60, 60, 60))
    local GodModeBtn = makeButton("GodMode (Destroy HRP + Fly)", 160, Color3.fromRGB(140, 50, 180))
    local StopBtn = makeButton("FULL STOP + CLEANUP", 198, Color3.fromRGB(120, 30, 30))
    
    local acBypassed = false
    
    BypassBtn.MouseButton1Click:Connect(function()
        if not acBypassed then
            killClientAC()
            createInvisibleSeat()
            startNoclip()
            acBypassed = true
            BypassBtn.Text = "AC Bypassed ✓"
            BypassBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
            Status.Text = "AC: Killed | Seat: Active | Noclip: On"
            Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        end
    end)
    
    DashBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            SkyWalkEngine.MoveForward(1000, 400, 200)
        end)
    end)
    
    SlideBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local character = LocalPlayer.Character
            if not character then return end
            local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
            if not hrp then return end
            local look = hrp.CFrame.LookVector
            local targetPos = hrp.Position + (look * 1000)
            local targetCFrame = CFrame.lookAt(targetPos, targetPos + look)
            SkyWalkEngine.TweenTo(targetCFrame, 200)
        end)
    end)

    GodModeBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart:Destroy()
            end
            -- Give the server a moment to register HRP destruction if needed, then dash
            task.wait(0.1)
            SkyWalkEngine.MoveForward(1000, 400, 200)
        end)
    end)
    
    StopBtn.MouseButton1Click:Connect(function()
        SkyWalkEngine.FullCleanup()
        acBypassed = false
        BypassBtn.Text = "Kill AC + Seat + Noclip"
        BypassBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        Status.Text = "AC: Not Bypassed | Seat: Off | Noclip: Off"
        Status.TextColor3 = Color3.fromRGB(140, 140, 140)
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        SkyWalkEngine.FullCleanup()
        ScreenGui:Destroy()
    end)
    
    return ScreenGui
end

-- Auto-launch UI
pcall(function()
    SkyWalkEngine.CreateUI()
end)

