-- ============================================================================
-- COMBINED AUTOFARM SCRIPT (SEQUENCE TARGETING)
-- Contains Model, View, and Controller logic in a single file
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
    "Scientist",
    "FactoryPool"
}

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

local function isValidTarget(npc, targetName)
    if npc.Name ~= targetName then return false end
    if not npc:FindFirstChild("HumanoidRootPart") then return false end
    
    -- Check normal Humanoid
    local humanoid = npc:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then return true end
    
    -- Check FactoryPool barrelHP
    local barrelHP = npc:FindFirstChild("barrelHP")
    if barrelHP and barrelHP.Value > 0 then return true end
    
    return false
end

-- Find the highest priority target, prioritizing the closest one
local function findBestTarget(allEnemies)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    for _, targetName in ipairs(TARGET_SEQUENCE) do
        local closestNPC = nil
        local closestDistance = math.huge
        
        for _, npc in pairs(allEnemies) do
            if isValidTarget(npc, targetName) then
                if rootPart and npc:FindFirstChild("HumanoidRootPart") then
                    local dist = (rootPart.Position - npc.HumanoidRootPart.Position).Magnitude
                    if dist < closestDistance then
                        closestDistance = dist
                        closestNPC = npc
                    end
                else
                    closestNPC = npc
                end
            end
        end
        
        if closestNPC then
            return closestNPC
        end
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
    end
    currentEnemy = nil
end

function Model.ApplyNoclip()
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
            local barrel = currentEnemy:FindFirstChild("barrelHP")
            if hum and hum.Health > 0 then isAlive = true end
            if barrel and barrel.Value > 0 then isAlive = true end
        end
        if not isAlive then
            currentEnemy = nil
            targetSwitchTimer = switchInterval
        end
    end

    targetSwitchTimer = targetSwitchTimer + deltaTime
    if targetSwitchTimer >= switchInterval then
        targetSwitchTimer = 0
        currentEnemy = findBestTarget(allEnemies)
    end

    local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
    bv.Name = "AntiGravity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = rootPart

    if currentEnemy then
        local targetRoot = currentEnemy.HumanoidRootPart
        
        -- Hover exactly 7.5 studs above the CURRENT target, allowing seamless multi-floor travel.
        local targetSpot = Vector3.new(targetRoot.Position.X, targetRoot.Position.Y + 7.5, targetRoot.Position.Z)
        local finalCFrame = CFrame.lookAt(targetSpot, targetRoot.Position)
        local distance = (rootPart.Position - targetSpot).Magnitude
        
        if distance > 0.5 then
            local lerpAlpha = math.clamp((flySpeed * deltaTime) / distance, 0, 1)
            rootPart.CFrame = rootPart.CFrame:Lerp(finalCFrame, lerpAlpha)
        else
            rootPart.CFrame = finalCFrame
        end
    end
    
    rootPart.Velocity = Vector3.new(0, 0, 0)
    rootPart.RotVelocity = Vector3.new(0, 0, 0)
end

function Model.EquipMelee()
    local character = LocalPlayer.Character
    if not character or character:FindFirstChild("Melee") then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if humanoid and backpack then
        local meleeTool = backpack:FindFirstChild("Melee")
        if meleeTool then humanoid:EquipTool(meleeTool) end
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
                if (character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude <= 15 then
                    table.insert(enemiesList, npc)
                end
                break
            end
        end
    end
    return enemiesList
end

function Model.DoCombatCombo()
    Model.EquipMelee()
    local targets = Model.GetEnemiesInRange()
    if #targets == 0 then
        task.wait(0.5)
        return
    end

    for currentHit = 1, 4 do
        if not Model.State.isAutoFarming then break end
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then break end
        
        local myCFrame = character.HumanoidRootPart.CFrame
        local animName = "Punch" .. currentHit
        local punchAnim = ReplicatedStorage:WaitForChild("CombatAnimations", 9e9):WaitForChild("Melee", 9e9):WaitForChild(animName, 9e9)
        
        local swingArgs = {
            [1] = {
                [1] = "swingsfx",
                [2] = "Melee",
                [3] = currentHit,
                [4] = "Ground",
                [5] = false,
                [6] = punchAnim,
                [7] = 2,
                [8] = 1.5
            }
        }
        task.spawn(function() pcall(function() combatRegister:InvokeServer(unpack(swingArgs)) end) end)
        
        task.wait(0.35) 
        
        if not Model.State.isAutoFarming then break end
        
        local currentTargets = Model.GetEnemiesInRange()
        local roots = {}
        for _, npc in pairs(currentTargets) do
            if npc:FindFirstChild("HumanoidRootPart") then table.insert(roots, npc.HumanoidRootPart) end
        end
        
        if #roots > 0 then
            local damageArgs = {
                [1] = {
                    [1] = "damage",
                    [2] = roots,
                    [3] = "Melee",
                    [4] = {[1] = currentHit, [2] = "Ground", [3] = "Melee"},
                    [5] = true,
                    [6] = myCFrame,
                    ["aircombo"] = "Ground"
                }
            }
            task.spawn(function() pcall(function() combatRegister:InvokeServer(unpack(damageArgs)) end) end)
        end
        task.wait(0.2)
    end
    if Model.State.isAutoFarming then task.wait(0.1) end
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
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    toggleBtn.Text = "AUTO FARM: OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.Parent = screenGui

    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

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
        
        toggleBtn.Text = isFarming and "AUTO FARM: ON" or "AUTO FARM: OFF"
        toggleBtn.BackgroundColor3 = isFarming and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(255, 85, 85)
        
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
        task.spawn(function()
            while Model.State.isAutoFarming do
                Model.DoCombatCombo()
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
    if Model.State.isAutoFarming then
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
    
    print("[Combined Autofarm] Autofarm forcefully stopped and UI destroyed.")
end
