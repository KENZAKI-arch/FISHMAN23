-- ========================================================
-- HOVERBOARD FLIGHT PANEL V8 (Always-On Anti-Fling)
-- ========================================================

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- ========================================================
-- PERMANENT ANTI-CATAPULT BACKGROUND SYSTEM
-- ========================================================
local function setupAntiFling(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    
    hum.Seated:Connect(function(isSeated, seat)
        -- The millisecond we sit in ANY vehicle seat, arm the safety net!
        if isSeated and seat and seat:IsA("VehicleSeat") then
            local dismountConnection
            dismountConnection = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                if not seat.Occupant then
                    -- We jumped out! Catch us instantly!
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        hrp.CFrame = seat.CFrame * CFrame.new(0, 3, 3)
                    end
                    -- Disarm the net until we sit down again
                    if dismountConnection then dismountConnection:Disconnect() end
                end
            end)
        end
    end)
end

-- Hook the background system immediately, and every time you respawn!
if player.Character then setupAntiFling(player.Character) end
player.CharacterAdded:Connect(setupAntiFling)
-- ========================================================


-- ========================================================
-- GUI CREATION
-- ========================================================
local guiName = "HoverboardFlightPanel"
local targetGui = (gethui and gethui()) or CoreGui
if targetGui:FindFirstChild(guiName) then targetGui[guiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.Parent = targetGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 200)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.Text = "Hoverboard Flight"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = title
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseButton1Click:Connect(function()
    RunService:UnbindFromRenderStep("CustomHoverboardLaser")
    screenGui:Destroy()
end)

local dragging, dragInput, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local heightInput = Instance.new("TextBox")
heightInput.Size = UDim2.new(1, -20, 0, 30)
heightInput.Position = UDim2.new(0, 10, 0, 40)
heightInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
heightInput.Text = "50"
heightInput.PlaceholderText = "Enter Altitude..."
heightInput.TextColor3 = Color3.fromRGB(255, 255, 255)
heightInput.Font = Enum.Font.Gotham
heightInput.TextSize = 14
heightInput.Parent = mainFrame
Instance.new("UICorner", heightInput).CornerRadius = UDim.new(0, 6)

local setBtn = Instance.new("TextButton")
setBtn.Size = UDim2.new(1, -20, 0, 35)
setBtn.Position = UDim2.new(0, 10, 0, 75)
setBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
setBtn.Text = "Set Flight Height"
setBtn.TextColor3 = Color3.new(1, 1, 1)
setBtn.Font = Enum.Font.GothamBold
setBtn.TextSize = 14
setBtn.Parent = mainFrame
Instance.new("UICorner", setBtn).CornerRadius = UDim.new(0, 6)

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(1, -20, 0, 35)
resetBtn.Position = UDim2.new(0, 10, 0, 115)
resetBtn.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
resetBtn.Text = "Reset to Normal"
resetBtn.TextColor3 = Color3.new(1, 1, 1)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 14
resetBtn.Parent = mainFrame
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)

local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(1, -20, 0, 35)
spawnBtn.Position = UDim2.new(0, 10, 0, 155)
spawnBtn.BackgroundColor3 = Color3.fromRGB(150, 45, 200)
spawnBtn.Text = "Auto Spawn Ship"
spawnBtn.TextColor3 = Color3.new(1, 1, 1)
spawnBtn.Font = Enum.Font.GothamBold
spawnBtn.TextSize = 14
spawnBtn.Parent = mainFrame
Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 6)

-- ========================================================
-- HELPER FUNCTIONS
-- ========================================================
local function getMyShip()
    local ships = workspace:FindFirstChild("Ships")
    if not ships then return nil end
    for _, ship in ipairs(ships:GetChildren()) do
        if ship.Name == player.Name or ship.Name == (player.Name .. "Ship") then return ship end
        
        local info = ship:FindFirstChild("Info")
        if info then
            local owner = info:FindFirstChild("Owner") or info:FindFirstChild("owner")
            if owner and (owner.Value == player or owner.Value == player.Name) then
                return ship
            end
        end
        
        local seat = ship:FindFirstChildWhichIsA("VehicleSeat", true)
        if seat and seat.Occupant and seat.Occupant.Parent == player.Character then
            return ship
        end
    end
    return nil
end

local function flyToWithGeppo(targetPos)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local lastGeppoTick = 0
    while (hrp.Position - targetPos).Magnitude > 5 do
        local currentTick = tick()
        if currentTick - lastGeppoTick >= 1.5 then
            lastGeppoTick = currentTick
            pcall(function()
                local cf = hrp.CFrame * CFrame.new(0, -2, 0)
                local stats = game.ReplicatedStorage:FindFirstChild("Stats" .. player.Name)
                local fs = stats and stats:FindFirstChild("Stats") and stats.Stats:FindFirstChild("FightingStyle")
                local skillName = "Sky Walk2"
                if fs then
                    if fs.Value == "Rokushiki" then skillName = "Geppo"
                    elseif fs.Value == "BlackLeg" then skillName = "Sky Walk"
                    elseif fs.Value == "Kamishiki" then skillName = "KamishikiGeppo"
                    end
                end
                game.ReplicatedStorage.Events.Skill:InvokeServer(skillName, {char = char, cf = cf})
            end)
        end
        
        local moveTargetSpot = targetPos
        
        -- Pathfinding strategy: Go up Y first!
        if targetPos.Y > hrp.Position.Y + 10 then
            moveTargetSpot = Vector3.new(hrp.Position.X, targetPos.Y, hrp.Position.Z)
        else
            -- Once we reached the Y altitude, fly horizontally
            moveTargetSpot = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
            
            -- Finish the last few studs directly
            if Vector2.new(hrp.Position.X - targetPos.X, hrp.Position.Z - targetPos.Z).Magnitude < 10 then
                moveTargetSpot = targetPos
            end
        end
        
        local direction = (moveTargetSpot - hrp.Position).Unit
        
        local bg = hrp:FindFirstChild("AntiRotation") or Instance.new("BodyGyro")
        bg.Name = "AntiRotation"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 3000
        bg.D = 500
        
        -- Prevent NaN rotation if flying straight up (which breaks physics and teleports you)
        local horizontalLook = Vector3.new(direction.X, 0, direction.Z)
        if horizontalLook.Magnitude > 0.001 then
            bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + horizontalLook)
        end
        bg.Parent = hrp
        
        local bv = hrp:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
        bv.Name = "AntiGravity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = direction * 90 -- 90 studs per second speed
        bv.Parent = hrp
        
        task.wait()
    end
    
    if hrp:FindFirstChild("AntiRotation") then hrp.AntiRotation:Destroy() end
    if hrp:FindFirstChild("AntiGravity") then hrp.AntiGravity:Destroy() end
end

-- ========================================================
-- DIRECT HIJACK ELEVATOR LOGIC
-- ========================================================

local absoluteTargetY = 0

setBtn.MouseButton1Click:Connect(function()
    local desiredHeight = tonumber(heightInput.Text)
    if not desiredHeight then return end
    
    local myShip = getMyShip()
    if not myShip then
        setBtn.Text = "Spawn Hoverboard 1st!"
        task.wait(1)
        setBtn.Text = "Set Flight Height"
        return
    end
    
    local seat = myShip:FindFirstChildWhichIsA("VehicleSeat", true) or myShip:FindFirstChildWhichIsA("Seat", true)
    local char = Players.LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hum and hrp and seat then
        local sitTimeout = 0
        while not hum.SeatPart and sitTimeout < 50 do
            hrp.CFrame = seat.CFrame * CFrame.new(0, 1.5, 0)
            task.wait(0.1)
            sitTimeout = sitTimeout + 1
        end
    end
    
    local bodyPos = myShip:FindFirstChild("m") and myShip.m:FindFirstChild("BodyPosition")
    if not bodyPos then return end
    
    absoluteTargetY = bodyPos.Position.Y

    local hasReachedHeight = false

    pcall(function() RunService:UnbindFromRenderStep("CustomHoverboardLaser") end)
    RunService:BindToRenderStep("CustomHoverboardLaser", 2000, function()
        if absoluteTargetY < desiredHeight - 2 then
            absoluteTargetY = absoluteTargetY + 2
        elseif absoluteTargetY > desiredHeight + 2 then
            absoluteTargetY = absoluteTargetY - 2
        else
            absoluteTargetY = desiredHeight + (math.sin(tick() * 4) * 0.8)
            
            if not hasReachedHeight then
                hasReachedHeight = true
                if hum and hrp then
                    hum.Sit = false
                    task.delay(0.1, function()
                        hrp.CFrame = seat.CFrame * CFrame.new(0, 3, 4.5)
                    end)
                end
            end
        end
        
        bodyPos.Position = Vector3.new(bodyPos.Position.X, absoluteTargetY, bodyPos.Position.Z)
    end)
    
    setBtn.Text = "Ascending Safely!"
    setBtn.BackgroundColor3 = Color3.fromRGB(45, 200, 100)
    task.wait(1)
    setBtn.Text = "Set Flight Height"
    setBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
end)

resetBtn.MouseButton1Click:Connect(function()
    RunService:UnbindFromRenderStep("CustomHoverboardLaser")
    
    resetBtn.Text = "Restored!"
    resetBtn.BackgroundColor3 = Color3.fromRGB(45, 200, 100)
    task.wait(1)
    resetBtn.Text = "Reset to Normal"
    resetBtn.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
end)

spawnBtn.MouseButton1Click:Connect(function()
    spawnBtn.Text = "Flying to Target..."
    spawnBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 45)
    
    local targetPos = Vector3.new(-3710, 244, 7598)
    flyToWithGeppo(targetPos)
    
    spawnBtn.Text = "Spawning & Setting Height..."
    spawnBtn.BackgroundColor3 = Color3.fromRGB(45, 200, 100)
    
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local events = ReplicatedStorage:FindFirstChild("Events")

        local myShip = getMyShip()
        print("[Auto Spawn] Initial ship check result:", myShip and myShip.Name or "Not found")

        if events and events:FindFirstChild("ShipEvents") and events.ShipEvents:FindFirstChild("Spawn") then
            if not myShip then
                print("[Auto Spawn] Invoking Spawn Remote...")
                pcall(function()
                    events.ShipEvents.Spawn:InvokeServer("true")
                end)
                
                -- Wait for the ship to actually appear
                print("[Auto Spawn] Waiting for ship to appear in workspace...")
                local timeout = 0
                while not getMyShip() and timeout < 50 do
                    task.wait(0.1)
                    timeout = timeout + 1
                end
                myShip = getMyShip()
                print("[Auto Spawn] Spawn wait finished. myShip:", myShip and myShip.Name or "Still not found")
            else
                print("[Auto Spawn] Ship already spawned. Skipping invoke.")
            end
        else
            print("[Auto Spawn] Error: Could not find ShipEvents.Spawn remote!")
        end
        
        -- Auto-set flight height if we successfully have a ship
        if myShip then
            print("[Auto Spawn] Found ship model! Teleporting to seat to gain Network Ownership...")
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local seat = myShip:FindFirstChildWhichIsA("VehicleSeat", true) or myShip:FindFirstChildWhichIsA("Seat", true)
            
            if hum and hrp and seat then
                print("[Auto Spawn] Forcing seat teleport...")
                local sitTimeout = 0
                while not hum.SeatPart and sitTimeout < 50 do
                    hrp.CFrame = seat.CFrame * CFrame.new(0, 1.5, 0)
                    task.wait(0.1)
                    sitTimeout = sitTimeout + 1
                end
                
                if hum.SeatPart then
                    print("[Auto Spawn] Successfully seated!")
                    local desiredHeight = tonumber(heightInput.Text)
                    
                    if desiredHeight then
                        local bodyPos = myShip:FindFirstChild("m") and myShip.m:FindFirstChild("BodyPosition")
                        
                        if bodyPos then
                            print("[Auto Spawn] BodyPosition found. Lifting off to height:", desiredHeight)
                            absoluteTargetY = bodyPos.Position.Y
                    
                    local hasReachedHeight = false
                    
                    pcall(function() RunService:UnbindFromRenderStep("CustomHoverboardLaser") end)
                    RunService:BindToRenderStep("CustomHoverboardLaser", 2000, function()
                        if absoluteTargetY < desiredHeight - 2 then
                            absoluteTargetY = absoluteTargetY + 2
                        elseif absoluteTargetY > desiredHeight + 2 then
                            absoluteTargetY = absoluteTargetY - 2
                        else
                            absoluteTargetY = desiredHeight + (math.sin(tick() * 4) * 0.8)
                            
                            if not hasReachedHeight then
                                hasReachedHeight = true
                                if hum and hrp then
                                    hum.Sit = false
                                    task.delay(0.1, function()
                                        hrp.CFrame = seat.CFrame * CFrame.new(0, 3, 4.5)
                                    end)
                                end
                            end
                        end
                        bodyPos.Position = Vector3.new(bodyPos.Position.X, absoluteTargetY, bodyPos.Position.Z)
                    end)
                        else
                            print("[Auto Spawn] Error: Could not find BodyPosition ('m' part) in ship model.")
                        end
                    else
                        print("[Auto Spawn] Error: Invalid height input.")
                    end
                else
                    print("[Auto Spawn] Error: Failed to sit in vehicle seat.")
                end
            else
                print("[Auto Spawn] Error: Missing Humanoid, HRP, or Seat.")
            end
        end
        
        spawnBtn.Text = "Auto Spawn Ship"
        spawnBtn.BackgroundColor3 = Color3.fromRGB(150, 45, 200)
    end)
end)
