-- ============================================================================
-- CYBORG AUTOFARM SCRIPT (SEQUENCE TARGETING) - UNIVERSAL
-- Contains Model, View, and Controller logic in a single file
-- Factory and location logic removed.
-- ============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- CONFIGURATION
-- ==========================================
-- The script will search for these targets in order.
-- Priority 1 is checked first. If not found, it moves to Priority 2.
local TARGET_SEQUENCE = {
    "Megalodon",
}

-- Global Speed Adjuster
getgenv().CyborgFlySpeed = 50

-- Global Altitude Adjuster (Y offset above enemy)
getgenv().CyborgFlyAltitude = 300

-- ==========================================
-- WEAPON IDENTIFICATION
-- ==========================================
-- This defines the folder name inside ReplicatedStorage.Modules.SwordHandle.Swords
local WEAPON_NAME = "Cyborg" -- Identifies the weapon folder
local WEAPON_TYPE = "FistStyles" -- Identifies it as a fighting style for CombatRegister

-- ==========================================
-- MODEL
-- ==========================================
local Model = {}
local combatRegister = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("CombatRegister", 9e9)

Model.State = {
    isAutoFarming = false
}

local flySpeed = 35
local currentEnemy = nil
local targetSwitchTimer = 2
local switchInterval = 2

-- Helper to find valid enemies across multiple folders
local function getAllEnemies()
    local allEnemies = {}
    local foldersToSearch = {}
    
    if Workspace:FindFirstChild("NPCs") then table.insert(foldersToSearch, Workspace.NPCs) end
    if Workspace:FindFirstChild("Env") then table.insert(foldersToSearch, Workspace.Env) end
    
    for _, folder in pairs(foldersToSearch) do
        for _, npc in pairs(folder:GetChildren()) do
            allEnemies[#allEnemies + 1] = npc
        end
    end
    return allEnemies
end

local function getRoot(npc)
    if not npc then return nil end
    return npc:FindFirstChild("HumanoidRootPart")
end

local function getStamina(character)
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if PlayerGui then
        local progressLabel = PlayerGui:FindFirstChild("HUD")
            and PlayerGui.HUD:FindFirstChild("Main")
            and PlayerGui.HUD.Main:FindFirstChild("Bars")
            and PlayerGui.HUD.Main.Bars:FindFirstChild("Stamina")
            and PlayerGui.HUD.Main.Bars.Stamina:FindFirstChild("Detail")
            and PlayerGui.HUD.Main.Bars.Stamina.Detail:FindFirstChild("Progress")
            
        if progressLabel and progressLabel:IsA("TextLabel") then
            local currentStaminaStr = string.match(progressLabel.Text, "^(%d+)")
            if currentStaminaStr then
                return tonumber(currentStaminaStr) or 0
            end
        end
    end
    
    if not character then return 0 end
    local energy = character:FindFirstChild("Energy") or character:FindFirstChild("Stamina") or character:FindFirstChild("Mana")
    if energy and (energy:IsA("NumberValue") or energy:IsA("IntValue")) then
        return energy.Value
    end
    local attr = character:GetAttribute("Energy") or character:GetAttribute("Stamina") or character:GetAttribute("Mana")
    if type(attr) == "number" then return attr end
    return 0
end

local function isValidTarget(npc, targetName)
    if npc.Name ~= targetName then return false end

    if not npc:FindFirstChild("HumanoidRootPart") then return false end
    
    -- Check normal Humanoid
    local humanoid = npc:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then return true end
    
    return false
end

-- Find the highest priority target, prioritizing the closest one
local function findBestTarget(allEnemies)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    local validEnemies = {}
    for seqIndex, targetName in ipairs(TARGET_SEQUENCE) do
        for _, npc in pairs(allEnemies) do
            if isValidTarget(npc, targetName) then
                local root = getRoot(npc)
                if root then
                    table.insert(validEnemies, {npc = npc, root = root, seq = seqIndex})
                end
            end
        end
    end
    
    if #validEnemies > 0 and rootPart then
        local myPos = rootPart.Position
        
        table.sort(validEnemies, function(a, b)
            local posA = a.root.Position
            local posB = b.root.Position
            
            if a.seq ~= b.seq then
                return a.seq < b.seq -- Priority 1: Target Sequence
            else
                -- Priority 2: Closest horizontal distance
                local distA = Vector2.new(myPos.X - posA.X, myPos.Z - posA.Z).Magnitude
                local distB = Vector2.new(myPos.X - posB.X, myPos.Z - posB.Z).Magnitude
                return distA < distB
            end
        end)
        
        return validEnemies[1].npc
    elseif #validEnemies > 0 then
        return validEnemies[1].npc
    end
    return nil
end

function Model.ResetPhysics()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        root.Anchored = false
        local bv = root:FindFirstChild("AntiGravity")
        if bv then bv:Destroy() end
        local bg = root:FindFirstChild("AntiRotation")
        if bg then bg:Destroy() end
    end
    currentEnemy = nil
    Model.SetFlightAnimation(false)
    Model.SetCyborgFlight(false)
end

function Model.SetFlightAnimation(enabled)
    -- Disabled: Using Geppo instead!
end

local lastGeppoTick = 0
local lastGeppoRemoteTick = 0
function Model.Geppo()
    local currentTick = tick()
    if currentTick - lastGeppoTick < 0.3 then return end
    lastGeppoTick = currentTick
    
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    task.spawn(function()
        local cf = rootPart.CFrame * CFrame.new(0, -2, 0)
        
        -- Play visual Geppo clouds locally (fast)
        pcall(function()
            if _G.PlayEffect then
                _G.PlayEffect("Geppo", nil, {char = character, cf = cf})
            end
        end)
        
        -- Fire the remote to use a bit of stamina (every 2 seconds)
        if currentTick - lastGeppoRemoteTick >= 2 then
            lastGeppoRemoteTick = currentTick
            pcall(function()
                local stats = game.ReplicatedStorage:FindFirstChild("Stats" .. LocalPlayer.Name)
                local fs = stats and stats:FindFirstChild("Stats") and stats.Stats:FindFirstChild("FightingStyle")
                local skillName = "Sky Walk2"
                if fs then
                    if fs.Value == "Rokushiki" then skillName = "Geppo"
                    elseif fs.Value == "BlackLeg" then skillName = "Sky Walk"
                    elseif fs.Value == "Kamishiki" then skillName = "KamishikiGeppo"
                    end
                end
                game.ReplicatedStorage.Events.Skill:InvokeServer(skillName, {char = character, cf = cf})
            end)
        end
    end)
end

function Model.SetCyborgFlight(enabled)
    -- Disabled: Using Geppo instead!
end

function Model.ApplyNoclip()
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

function Model.UpdateTracking(deltaTime)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return end
    
    local rootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid
    
    local isRagdolled = (character.Parent and character.Parent.Name == "Ragdolls")
    local isStunned = character:FindFirstChild("Stun") or character:FindFirstChild("frozen") or _G.canuse == false
    local isDead = humanoid.Health <= 0
    
    if isRagdolled or isStunned or isDead then
        rootPart.Anchored = true
        rootPart.Velocity = Vector3.new(0, 0, 0)
        return
    else
        rootPart.Anchored = false
    end

    local allEnemies = getAllEnemies()

    -- Check if current enemy died
    if currentEnemy then
        local isAlive = false
        if currentEnemy.Parent ~= nil then
            local hum = currentEnemy:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then isAlive = true end
        end
        if not isAlive then
            currentEnemy = nil
            targetSwitchTimer = switchInterval
        end
    end

    targetSwitchTimer = targetSwitchTimer + deltaTime
    
    Model.State.isWaitingAtSafeSpot = false

    if targetSwitchTimer >= switchInterval then
        targetSwitchTimer = 0
        currentEnemy = findBestTarget(allEnemies)
        -- Trigger flight when finding a new target to maintain altitude
        if currentEnemy then
            Model.SetCyborgFlight(true)
        end
    end

    if currentEnemy then
        Model.SetCyborgFlight(true)
        
        -- No flyMode ground fallback needed, we fly forever using physics!
        
        local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
        bv.Name = "AntiGravity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = rootPart

        local targetRoot = getRoot(currentEnemy)
        if not targetRoot then return end
        
        -- Apply orbital anti-gravity positioning (custom studs above target)
        local alt = getgenv().CyborgFlyAltitude or 190
        
        local targetSpot = Vector3.new(targetRoot.Position.X, targetRoot.Position.Y + alt, targetRoot.Position.Z)
        
        -- Proactive Raycast Anti-Stuck System
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character, currentEnemy}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        pcall(function() rayParams.RespectCanCollide = true end)
        
        local testDir = (targetRoot.Position - targetSpot)
        local isBlocked = workspace:Raycast(targetSpot, testDir, rayParams)
        
        if isBlocked then
            local rootLook = rootPart.CFrame.LookVector
            local rootRight = rootPart.CFrame.RightVector
            local lookDir = Vector3.new(rootLook.X, 0, rootLook.Z)
            local rightDir = Vector3.new(rootRight.X, 0, rootRight.Z)
            
            lookDir = lookDir.Magnitude > 0 and lookDir.Unit or Vector3.new(1,0,0)
            rightDir = rightDir.Magnitude > 0 and rightDir.Unit or Vector3.new(0,0,1)
            
            local testOffsets = {
                lookDir * 20, lookDir * -20, rightDir * 20, rightDir * -20,
                lookDir * 40, lookDir * -40, rightDir * 40, rightDir * -40,
                lookDir * 60, lookDir * -60, rightDir * 60, rightDir * -60
            }
            
            for _, offset in ipairs(testOffsets) do
                local testSpot = targetSpot + offset
                local testHit = workspace:Raycast(testSpot, (targetRoot.Position - testSpot), rayParams)
                if not testHit then
                    targetSpot = testSpot
                    break
                end
            end
        end
        
        local distance = (rootPart.Position - targetSpot).Magnitude
        
        -- Pathfinding Strategy
        local moveTargetSpot = targetSpot
        
        if targetSpot.Y > rootPart.Position.Y + 30 then
            -- Generic ascend logic for normal targets (avoids getting stuck on small ground geometry)
            moveTargetSpot = Vector3.new(rootPart.Position.X, targetSpot.Y, rootPart.Position.Z)
        end
        
        local finalCFrame = CFrame.lookAt(targetSpot, targetRoot.Position)
        
        Model.Geppo()
        
        if distance > 0.5 then
            local direction = (moveTargetSpot - rootPart.Position).Unit
            
            -- Keep character facing the enemy like a bomber
            local bg = rootPart:FindFirstChild("AntiRotation") or Instance.new("BodyGyro")
            bg.Name = "AntiRotation"
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 3000
            bg.D = 500
            bg.CFrame = CFrame.lookAt(rootPart.Position, targetRoot.Position)
            bg.Parent = rootPart
            
            -- Pure physics flight!
            local speed = getgenv().CyborgFlySpeed or 50
            bv.Velocity = direction * speed
        else
            bv.Velocity = Vector3.new(0, 0, 0)
            local bg = rootPart:FindFirstChild("AntiRotation")
            if bg then bg.CFrame = finalCFrame end
            rootPart.CFrame = finalCFrame
        end
    else
        -- If we have no target, clean up physics and flight
        Model.SetFlightAnimation(false)
        if rootPart:FindFirstChild("AntiGravity") then
            rootPart.AntiGravity:Destroy()
        end
        if rootPart:FindFirstChild("AntiRotation") then
            rootPart.AntiRotation:Destroy()
        end
        -- Also cancel Cyborg Flight if it's active
        Model.SetCyborgFlight(false)
    end
end

function Model.EquipWeapon()
    local character = LocalPlayer.Character
    if not character or character:FindFirstChild(WEAPON_NAME) then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if humanoid and backpack then
        local weaponTool = backpack:FindFirstChild(WEAPON_NAME)
        if weaponTool then humanoid:EquipTool(weaponTool) end
    end
end

function Model.GetEnemiesInRange()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return {} end
    
    local enemiesList = {}
    local allEnemies = getAllEnemies()
    
    for _, npc in pairs(allEnemies) do
        for _, tName in ipairs(TARGET_SEQUENCE) do
            if isValidTarget(npc, tName) then
                local root = getRoot(npc)
                if root then
                    local myPos = character.HumanoidRootPart.Position
                    local npcPos = root.Position
                    local distXZ = Vector2.new(myPos.X - npcPos.X, myPos.Z - npcPos.Z).Magnitude
                    local expectedY = myPos.Y - (getgenv().CyborgFlyAltitude or 190)
                    local distY = math.abs(npcPos.Y - expectedY)
                    if distXZ <= 80 and distY <= 50 then
                        table.insert(enemiesList, npc)
                    end
                end
                break
            end
        end
    end
    
    local expectedY = character.HumanoidRootPart.Position.Y - (getgenv().CyborgFlyAltitude or 190)
    table.sort(enemiesList, function(a, b)
        local rootA = getRoot(a)
        local rootB = getRoot(b)
        local diffA = rootA and math.abs(rootA.Position.Y - expectedY) or 9999
        local diffB = rootB and math.abs(rootB.Position.Y - expectedY) or 9999
        return diffA < diffB
    end)
    
    return enemiesList
end

-- ==========================================
-- VIEW
-- ==========================================
local View = {}

function View.Build(onToggleCallback)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFarmGui"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
    if not success then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 180, 0, 50)
    toggleBtn.Position = UDim2.new(0.5, -90, 0.1, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255) -- Cyborg Blue
    toggleBtn.Text = "CYBORG FARM: OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.Parent = screenGui

    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

    local speedInput = Instance.new("TextBox")
    speedInput.Size = UDim2.new(1, 0, 0, 25)
    speedInput.Position = UDim2.new(0, 0, 1, 5)
    speedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedInput.Font = Enum.Font.GothamSemibold
    speedInput.TextSize = 12
    speedInput.Text = "Speed: " .. tostring(getgenv().CyborgFlySpeed or 50)
    speedInput.PlaceholderText = "Speed"
    speedInput.Parent = toggleBtn
    Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 4)

    speedInput.FocusLost:Connect(function()
        local num = tonumber(string.match(speedInput.Text, "%d+"))
        if num then
            getgenv().CyborgFlySpeed = math.clamp(num, 10, 300)
            speedInput.Text = "Speed: " .. tostring(getgenv().CyborgFlySpeed)
        else
            speedInput.Text = "Speed: " .. tostring(getgenv().CyborgFlySpeed or 50)
        end
    end)

    local heightInput = Instance.new("TextBox")
    heightInput.Size = UDim2.new(1, 0, 0, 25)
    heightInput.Position = UDim2.new(0, 0, 1, 35)
    heightInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    heightInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    heightInput.Font = Enum.Font.GothamSemibold
    heightInput.TextSize = 12
    heightInput.Text = "Height: " .. tostring(getgenv().CyborgFlyAltitude or 190)
    heightInput.PlaceholderText = "Height"
    heightInput.Parent = toggleBtn
    Instance.new("UICorner", heightInput).CornerRadius = UDim.new(0, 4)

    heightInput.FocusLost:Connect(function()
        local num = tonumber(string.match(heightInput.Text, "%d+"))
        if num then
            getgenv().CyborgFlyAltitude = math.max(10, num) -- Removed the upper limit!
            heightInput.Text = "Height: " .. tostring(getgenv().CyborgFlyAltitude)
        else
            heightInput.Text = "Height: " .. tostring(getgenv().CyborgFlyAltitude or 190)
        end
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -12, 0, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = toggleBtn
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

    closeBtn.MouseButton1Click:Connect(function()
        if getgenv().StopAutofarm then
            getgenv().StopAutofarm()
        end
    end)

    local dragging, dragInput, dragStart, startPos
    
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    toggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local isFarming = false

    local function setFarmingState(state)
        if isFarming == state then return end
        isFarming = state
        Model.State.isAutoFarming = isFarming
        if toggleBtn then
            toggleBtn.Text = isFarming and "CYBORG FARM: ON" or "CYBORG FARM: OFF"
            toggleBtn.BackgroundColor3 = isFarming and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 150, 255)
        end
        onToggleCallback(isFarming)
    end

    local allowAutoStart = true

    toggleBtn.MouseButton1Click:Connect(function()
        allowAutoStart = false 
        setFarmingState(not isFarming)
    end)

    task.spawn(function()
        task.wait(5)
        if allowAutoStart and not isFarming then
            allowAutoStart = false
            setFarmingState(true)
        end
    end)
end

-- ==========================================
-- CONTROLLER
-- ==========================================

View.Build(function(isFarming)
    Model.State.isAutoFarming = isFarming

    if not isFarming then
        Model.ResetPhysics()
    else
        -- No M1 loop needed for Cyborg, purely skills!
        
        -- Automatically use Cyborg Skills
        task.spawn(function()
            local skillEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Skill", 9e9)
            local skills = {"Missle Shower"}
            
            while Model.State.isAutoFarming do
                if currentEnemy then
                    -- Make sure Cyborg Flight is active!
                    Model.SetCyborgFlight(true)
                    
                    for _, skillName in ipairs(skills) do
                        if not Model.State.isAutoFarming then break end
                        -- Ensure we have actually reached the target before unleashing the payload!
                        local rootPart = LocalPlayer.Character.HumanoidRootPart
                        local targetRoot = getRoot(currentEnemy)
                        local alt = getgenv().CyborgFlyAltitude or 190
                        
                        local targetSpot = rootPart.Position
                        if targetRoot then
                            targetSpot = Vector3.new(targetRoot.Position.X, targetRoot.Position.Y + alt, targetRoot.Position.Z)
                        end
                        
                        local distanceToTarget = (rootPart.Position - targetSpot).Magnitude
                        
                        local distToEnemyGround = Vector2.new(rootPart.Position.X - targetSpot.X, rootPart.Position.Z - targetSpot.Z).Magnitude
                        local isAtHoverSpot = distToEnemyGround < 10
                        
                        if isAtHoverSpot then -- Only bomb if we have arrived at the intended hover spot
                            -- Fire the skill. We wait for it to finish before looping again.
                            pcall(function()
                                local targetPos = rootPart.Position
                                if targetRoot then
                                    targetPos = targetRoot.Position
                                end
                                
                                -- Send the target position directly like Mouse.Hit does, instead of the character's position
                                local aimCFrame = CFrame.new(targetPos)
                            
                            if skillName == "Missle Shower" then
                                local releaseEvent = skillEvent:InvokeServer(skillName, aimCFrame)
                                if releaseEvent then
                                    task.wait(0.4)
                                    
                                    -- Missle shower can be held for up to 10 seconds (111 ticks of 0.09s)
                                    -- We continuously track the enemy and rain missiles down on them until they die!
                                    for i = 1, 110 do
                                        if not Model.State.isAutoFarming then break end
                                        
                                        -- Dynamically find the closest enemy right now to carpet bomb
                                        local currentTargets = Model.GetEnemiesInRange()
                                        local targetToShoot = currentTargets[1] or currentEnemy
                                        
                                        local currentAim
                                        if targetToShoot and targetToShoot:FindFirstChild("HumanoidRootPart") then
                                            currentAim = CFrame.new(targetToShoot.HumanoidRootPart.Position)
                                        else
                                            -- If flying between distant enemies, rain missiles straight down!
                                            currentAim = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0, 50, 0))
                                        end
                                        
                                        releaseEvent:FireServer(currentAim)
                                        task.wait(0.09)
                                    end
                                    releaseEvent:FireServer()
                                end
                            else
                                local releaseEvent = skillEvent:InvokeServer(skillName, { ["cf"] = aimCFrame })
                                if releaseEvent then
                                    task.wait(0.5)
                                    releaseEvent:FireServer()
                                end
                            end
                        end)
                        task.wait(0.2) -- Slight delay between skill casts
                        end
                    end
                end
                task.wait(0.5) -- Fast check to re-activate skill as soon as cooldown ends
            end
        end)

        task.spawn(function()
            local statsEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("stats", 9e9)
            local args = { "Strength", nil, 1 }
            
            while Model.State.isAutoFarming do
                pcall(function()
                    statsEvent:FireServer(unpack(args))
                end)
                task.wait(3) 
            end
        end)
    end
end)

local steppedConn = RunService.Stepped:Connect(function()
    if Model.State.isAutoFarming and not Model.State.isWaitingAtSafeSpot then
        Model.ApplyNoclip()
    end
end)

local heartbeatConn = RunService.Heartbeat:Connect(function(deltaTime)
    if not Model.State.isAutoFarming then return end
    Model.UpdateTracking(deltaTime)
end)

getgenv().StopAutofarm = function()
    Model.State.isAutoFarming = false
    Model.ResetPhysics()
    
    if steppedConn then steppedConn:Disconnect() end
    if heartbeatConn then heartbeatConn:Disconnect() end
    
    local coreGui = game:GetService("CoreGui"):FindFirstChild("AutoFarmGui")
    if coreGui then coreGui:Destroy() end
    
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild("AutoFarmGui") then 
        pGui.AutoFarmGui:Destroy() 
    end
    
    print("[Cyborg Autofarm] Autofarm forcefully stopped and UI destroyed.")
end
