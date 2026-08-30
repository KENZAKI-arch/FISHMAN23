-- ============================================================================
-- CYBORG AUTOFARM SCRIPT (SEQUENCE TARGETING) THIS IS UPDATED v2
-- Contains Model, View, and Controller logic in a single file
-- ============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

if getgenv().StopAutofarm then
    pcall(getgenv().StopAutofarm)
end

print("Cyborg autofarm v2 is running!")

local _connections = {}
local function addConn(conn)
    table.insert(_connections, conn)
    return conn
end

-- ==========================================
-- CONFIGURATION
-- ==========================================
-- The script will search for these targets in order.
-- Priority 1 is checked first. If not found, it moves to Priority 2.
local TARGET_SEQUENCE = {
    "Megalodon"
}

-- Global Speed Adjuster
getgenv().CyborgFlySpeed = 80

-- Global Altitude Adjuster (Y offset above enemy)
getgenv().CyborgFlyAltitude = 250

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
                return a.seq < b.seq -- Absolute Priority 1: Target Sequence
            else
                -- Priority 2: Farthest vertical distance
                local distA = math.abs(myPos.Y - posA.Y)
                local distB = math.abs(myPos.Y - posB.Y)
                return distA > distB
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
        
        -- Teleport back before dropping physics!
        if getgenv().CachedHoverboard and getgenv().CachedHoverboard.Parent then
            -- Teleport to the tail of the hoverboard (approx 4 studs backwards)
            root.CFrame = getgenv().CachedHoverboard.CFrame * CFrame.new(0, 3, 4)
        elseif Model.State.originalPosition then
            root.CFrame = CFrame.new(Model.State.originalPosition)
        end
        
        root.Anchored = false
        local bv = root:FindFirstChild("AntiGravity")
        if bv then bv:Destroy() end
        local bg = root:FindFirstChild("AntiRotation")
        if bg then bg:Destroy() end
    end
    currentEnemy = nil
    Model.State.originalPosition = nil
    Model.SetFlightAnimation(false)
end

function Model.SetCyborgFlight(enabled)
    -- Stub to prevent Heartbeat crash from missing legacy function
end

function Model.SetFlightAnimation(enabled)
    -- Disabled: The user requested to use Geppo (Sky Walk) instead of Cyborg Flight!
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
        
        -- Fire the remote to use a bit of stamina (every 3 seconds)
        if currentTick - lastGeppoRemoteTick >= 3 then
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
    -- Disabled: Rely purely on custom physics so we don't drain stamina!
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
            local barrel = currentEnemy:FindFirstChild("barrelHP")
            
            if barrel then
                isAlive = (barrel.Value > 0)
            elseif hum then
                isAlive = (hum.Health > 0)
            elseif currentEnemy.Name == "FactoryPool" then
                if currentEnemy:FindFirstChild("hitbox") or currentEnemy:FindFirstChild("Pool") then
                    isAlive = true
                end
            end
        end
        if not isAlive then
            currentEnemy = nil
            targetSwitchTimer = switchInterval
        end
    end

    targetSwitchTimer = targetSwitchTimer + deltaTime

    if targetSwitchTimer >= switchInterval then
        targetSwitchTimer = 0
        local newEnemy = findBestTarget(allEnemies)
        
        -- Target found!
        if newEnemy then
            Model.State.hasReturned = false
        end
        
        currentEnemy = newEnemy
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
        
        -- Auto-Equip Hoverboard Tool from ReplicatedStorage if we aren't tracking one yet
        if not getgenv().CachedHoverboard or not getgenv().CachedHoverboard.Parent then
            local rsTools = game:GetService("ReplicatedStorage"):FindFirstChild("Tools")
            if rsTools then
                local rsHoverboard = rsTools:FindFirstChild("Hoverboard")
                if rsHoverboard then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    local char = LocalPlayer.Character
                    if backpack and char and not backpack:FindFirstChild("Hoverboard") and char:FindFirstChild("Humanoid") and not char:FindFirstChild("Hoverboard") then
                        local clone = rsHoverboard:Clone()
                        clone.Parent = backpack
                        char.Humanoid:EquipTool(clone)
                        print("🎒 [DEBUG] Auto-Equipped Hoverboard Tool from ReplicatedStorage!")
                    end
                end
            end
        end
        
        -- Auto-detect Hoverboard if standing on it but not seated!
        if not getgenv().CachedHoverboard then
            local ray = RaycastParams.new()
            ray.FilterDescendantsInstances = {LocalPlayer.Character}
            local hit = workspace:Raycast(rootPart.Position, Vector3.new(0, -15, 0), ray)
            if hit and hit.Instance then
                local model = hit.Instance:FindFirstAncestorOfClass("Model")
                if model then
                    local seat = model:FindFirstChildWhichIsA("VehicleSeat", true)
                    if seat then
                        print("✅ [DEBUG] Hoverboard Auto-Detected from standing on it!", seat:GetFullName())
                        getgenv().CachedHoverboard = seat
                    end
                end
            end
        end
        
        local targetSpot
        if currentEnemy.Name == "Megalodon" and getgenv().CachedHoverboard and getgenv().CachedHoverboard.Parent then
            print("🚀 [DEBUG] Hoverboard Detected! Anchoring 5 studs below.")
            targetSpot = getgenv().CachedHoverboard.Position - Vector3.new(0, 5, 0)
        else
            if currentEnemy.Name == "Megalodon" then
                print("❌ [DEBUG] Hoverboard NOT Detected! Anchoring to Megalodon.")
                -- Remove the height thing completely! Just stay 5 studs above the Megalodon's root.
                targetSpot = targetRoot.Position + Vector3.new(0, 5, 0)
            else
                -- Apply orbital anti-gravity positioning (custom studs above target) for other enemies
                local alt = getgenv().CyborgFlyAltitude or 250
                targetSpot = Vector3.new(targetRoot.Position.X, alt, targetRoot.Position.Z)
            end
        end
        

        
        local distance = (rootPart.Position - targetSpot).Magnitude
        
        local moveTargetSpot = targetSpot
        local finalCFrame = CFrame.lookAt(targetSpot, targetRoot.Position)
        
        Model.Geppo()
        
        if distance > 0.5 then
            -- Keep character facing the enemy like a bomber
            local bg = rootPart:FindFirstChild("AntiRotation") or Instance.new("BodyGyro")
            bg.Name = "AntiRotation"
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 3000
            bg.D = 500
            bg.CFrame = CFrame.lookAt(rootPart.Position, targetRoot.Position)
            bg.Parent = rootPart
            
            -- Universal Teleport with Anti-Gravity Anchor (Replaces slow Geppo flight)
            local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
            bv.Name = "AntiGravity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = rootPart
            
            rootPart.CFrame = CFrame.new(moveTargetSpot) * bg.CFrame.Rotation
        else
            local bv = rootPart:FindFirstChild("AntiGravity")
            if bv then bv.Velocity = Vector3.new(0, 0, 0) end
            local bg = rootPart:FindFirstChild("AntiRotation")
            if bg then bg.CFrame = finalCFrame end
            rootPart.CFrame = finalCFrame
        end
    else
        -- If we have no target, return to our original position or hover in place
        Model.SetCyborgFlight(true)
        Model.Geppo()
        
        if Model.State.hasReturned then return end
        
        local targetSpot
        if getgenv().CachedHoverboard and getgenv().CachedHoverboard.Parent then
            -- Teleport to the tail of the hoverboard (approx 4 studs backwards)
            targetSpot = (getgenv().CachedHoverboard.CFrame * CFrame.new(0, 3, 4)).Position
        elseif Model.State.originalPosition then
            targetSpot = Model.State.originalPosition
        else
            local alt = getgenv().CyborgFlyAltitude or 250
            targetSpot = Vector3.new(rootPart.Position.X, alt, rootPart.Position.Z)
        end
        local distance = (rootPart.Position - targetSpot).Magnitude
        
        if distance > 1.5 then
            -- Universal Teleport Return!
            local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
            bv.Name = "AntiGravity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = rootPart
            
            rootPart.CFrame = CFrame.new(targetSpot) * rootPart.CFrame.Rotation
        else
            local bv = rootPart:FindFirstChild("AntiGravity")
            if bv then bv:Destroy() end
            Model.State.hasReturned = true
        end
        
        if rootPart:FindFirstChild("AntiRotation") then
            rootPart.AntiRotation:Destroy()
        end
        
        if Model.State.currentTween then
            Model.State.currentTween:Cancel()
            Model.State.currentTween = nil
        end
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
                    local alt = getgenv().CyborgFlyAltitude or 250
                    if distXZ <= 80 then
                        table.insert(enemiesList, npc)
                    end
                end
                break
            end
        end
    end
    
    local myPos = character.HumanoidRootPart.Position
    table.sort(enemiesList, function(a, b)
        local rootA = getRoot(a)
        local rootB = getRoot(b)
        local distA = rootA and math.abs(myPos.Y - rootA.Position.Y) or -1
        local distB = rootB and math.abs(myPos.Y - rootB.Position.Y) or -1
        return distA > distB
    end)
    
    return enemiesList
end

-- ==========================================
-- VIEW
-- ==========================================
local View = {}

function View.Build(onToggleCallback)
    local isFarming = false
    
    local function setFarmingState(state)
        if isFarming == state then return end
        isFarming = state
        Model.State.isAutoFarming = isFarming
        
        if isFarming then
            Model.State.hasEnteredFactory = false
            Model.State.hasReturned = false
            
            -- Record true starting position when toggled ON
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                Model.State.originalPosition = char.HumanoidRootPart.Position
            end
        else
            Model.State.originalPosition = nil
        end
        
        onToggleCallback(isFarming)
    end
    
    getgenv().ToggleCyborgAutofarm = setFarmingState
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
                        local isAtHoverSpot = false
                        
                        if targetRoot then
                            if currentEnemy.Name == "Megalodon" and getgenv().CachedHoverboard and getgenv().CachedHoverboard.Parent then
                                -- If we're anchored to the hoverboard, just check if we're in range!
                                local dist = (rootPart.Position - targetRoot.Position).Magnitude
                                if dist < 2500 then
                                    isAtHoverSpot = true
                                    print("🎯 [DEBUG] Shooting from Hoverboard! Distance to Megalodon:", dist)
                                end
                            else
                                if currentEnemy.Name == "Megalodon" then
                                    targetSpot = targetRoot.Position + Vector3.new(0, 5, 0)
                                else
                                    targetSpot = Vector3.new(targetRoot.Position.X, alt, targetRoot.Position.Z)
                                end
                                local distToEnemyGround = Vector2.new(rootPart.Position.X - targetSpot.X, rootPart.Position.Z - targetSpot.Z).Magnitude
                                isAtHoverSpot = distToEnemyGround < 10
                            end
                        end
                        
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
                                local initialTarget = currentEnemy
                                local releaseEvent = skillEvent:InvokeServer(skillName, aimCFrame)
                                if releaseEvent then
                                    task.wait(0.4)
                                    
                                    -- Missle shower can be held for up to 10 seconds (111 ticks of 0.09s)
                                    -- We continuously track the enemy and rain missiles down on them until they die!
                                    for i = 1, 110 do
                                        if not Model.State.isAutoFarming then break end
                                        
                                        local targetToShoot = currentEnemy
                                        if currentEnemy then
                                            local currentTargets = Model.GetEnemiesInRange()
                                            targetToShoot = currentTargets[1] or currentEnemy
                                        end
                                        
                                        local targetRootPart = targetToShoot and getRoot(targetToShoot)
                                        
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
                        end -- Missing end added here to close distance check
                    end
                end
                task.wait(0.5) -- Fast check to re-activate skill as soon as cooldown ends
            end
        end)

        -- Strength auto-stat loop removed
    end
end)

local steppedConn = addConn(RunService.Stepped:Connect(function()
    if Model.State.isAutoFarming and not Model.State.isWaitingAtSafeSpot then
        Model.ApplyNoclip()
    end
end))

local heartbeatConn = addConn(RunService.Heartbeat:Connect(function(deltaTime)
    if not Model.State.isAutoFarming then return end
    Model.UpdateTracking(deltaTime)
end))

getgenv().StopAutofarm = function()
    Model.State.isAutoFarming = false
    Model.ResetPhysics()
    
    for _, c in ipairs(_connections) do
        if c and c.Connected then c:Disconnect() end
    end
    table.clear(_connections)
    
    local coreGui = game:GetService("CoreGui"):FindFirstChild("AutoFarmGui")
    if coreGui then coreGui:Destroy() end
    
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild("AutoFarmGui") then 
        pGui.AutoFarmGui:Destroy() 
    end
    
    local hGui = game:GetService("CoreGui"):FindFirstChild("HoverboardFlightPanel")
    if hGui then hGui:Destroy() end
    

    print("[Cyborg Autofarm] Autofarm forcefully stopped, memory cleared, and UI destroyed.")
end

