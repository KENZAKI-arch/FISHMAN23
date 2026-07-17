-- ============================================================================
-- CYBORG AUTOFARM SCRIPT (SEQUENCE TARGETING)
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
    "Megalodon"
}

-- Global Speed Adjuster
getgenv().CyborgFlySpeed = 80

-- Global Altitude Adjuster (Y offset above enemy)
getgenv().CyborgFlyAltitude = 250

-- Batch Farming Config
getgenv().MegalodonBatchLimit = 1
getgenv().CombatAltitudeOffset = 4

-- ==========================================
-- WEAPON IDENTIFICATION
-- ==========================================
-- This defines the folder name inside ReplicatedStorage.Modules.SwordHandle.Swords
local WEAPON_NAME = "Cyborg" -- Identifies the weapon folder
local WEAPON_TYPE = "FistStyles" -- Identifies it as a fighting style for CombatRegister

-- ==========================================
-- FISHING CONFIGURATION
-- ==========================================
-- AutoFish is permanently enabled during farming
local FishingActionRemote = ReplicatedStorage:WaitForChild("Fishing", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("Action", 9e9)
local BAIT_NAME = "Common Fish Bait"
local THROW_ANIMATION_ID = "rbxassetid://140322334422224"
local REEL_ANIMATION_ID = "rbxassetid://136623058564703"
local VALID_RODS = { "Devil Fruit Rod", "Merchants Banana Rod", "Lovestruck Rod", "Fishing Rod" }
local loadedAnimations = {}

local function playAnimation(animationId)
    local character = LocalPlayer.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

    local track = loadedAnimations[animationId]
    if track and not track.IsPlaying and not pcall(function() return track.Length end) then
        loadedAnimations[animationId] = nil
        track = nil
    end

    if not track then
        local anim = Instance.new("Animation")
        anim.AnimationId = animationId
        track = animator:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action
        loadedAnimations[animationId] = track
    end

    track:Play(0.1)
    return track
end

-- ==========================================
-- MODEL
-- ==========================================
local Model = {}
local combatRegister = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("CombatRegister", 9e9)

Model.State = {
    isAutoFarming = false
}

-- ==========================================
-- DEEP SEA SOUND DETECTION
-- ==========================================
function Model.ListenForDeepSeaSound()
    -- Disconnect old connections if they exist to prevent memory leaks on script re-execution
    if getgenv().DSC_Connections then
        for _, conn in ipairs(getgenv().DSC_Connections) do
            if conn.Connected then conn:Disconnect() end
        end
    end
    getgenv().DSC_Connections = {}
    getgenv().DSC_SoundCache = {}
    
    local function onNewSound(child)
        if child:IsA("Sound") and string.find(child.Name, "DeepSea") then
            table.insert(getgenv().DSC_SoundCache, child)
        end
    end
    
    -- Listen to Workspace and SoundService (where the game usually spawns global sounds)
    table.insert(getgenv().DSC_Connections, workspace.DescendantAdded:Connect(onNewSound))
    table.insert(getgenv().DSC_Connections, game:GetService("SoundService").DescendantAdded:Connect(onNewSound))
    
    -- Listen to LocalPlayer (catches sounds in PlayerGui, etc.)
    table.insert(getgenv().DSC_Connections, LocalPlayer.DescendantAdded:Connect(onNewSound))
    for _, child in ipairs(LocalPlayer:GetDescendants()) do
        onNewSound(child)
    end
    
    -- Listen to Character (catches sounds in HumanoidRootPart)
    if LocalPlayer.Character then
        table.insert(getgenv().DSC_Connections, LocalPlayer.Character.DescendantAdded:Connect(onNewSound))
        for _, child in ipairs(LocalPlayer.Character:GetDescendants()) do
            onNewSound(child)
        end
    end
    table.insert(getgenv().DSC_Connections, LocalPlayer.CharacterAdded:Connect(function(char)
        table.insert(getgenv().DSC_Connections, char.DescendantAdded:Connect(onNewSound))
    end))
end
Model.ListenForDeepSeaSound()

function Model.CheckBeastSound()
    local beastDetected = false
    
    -- Quickly copy valid sounds from our zero-lag cache
    local beastSounds = {}
    if getgenv().DSC_SoundCache then
        for i = #getgenv().DSC_SoundCache, 1, -1 do
            local s = getgenv().DSC_SoundCache[i]
            if s.Parent then
                table.insert(beastSounds, s)
            else
                table.remove(getgenv().DSC_SoundCache, i) -- Clean up deleted sounds
            end
        end
    end
    
    -- Check ALL beast sounds globally
    for _, s in ipairs(beastSounds) do
        if s.Playing and s.TimePosition < 3.0 then
            local parentName = s.Parent and s.Parent.Name or "nil"
            print("🔥 BEAST SOUND DETECTED! Name:", s.Name, "Time:", string.format("%.1f", s.TimePosition), "Parent:", parentName)
            beastDetected = true
            break
        end
    end
    
    return beastDetected
end

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
    if Workspace:FindFirstChild("Terrain") then table.insert(foldersToSearch, Workspace.Terrain) end
    
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

local function countTargets(allEnemies, targetName)
    local count = 0
    for _, npc in pairs(allEnemies) do
        if isValidTarget(npc, targetName) then
            count = count + 1
        end
    end
    return count
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
            getgenv().RoarHeard = false
        end
    end

    targetSwitchTimer = targetSwitchTimer + deltaTime

    if getgenv().WaitForRoar and not getgenv().RoarHeard then
        if Model.CheckBeastSound() then
            getgenv().RoarHeard = true
        end
    end

    if targetSwitchTimer >= switchInterval then
        targetSwitchTimer = 0
        
        if getgenv().WaitForRoar and not getgenv().RoarHeard then
            currentEnemy = nil
        else
            local targetCount = countTargets(allEnemies, "Megalodon")
            local limit = getgenv().MegalodonBatchLimit or 10
            
            if targetCount >= limit then
                Model.State.isBatchAttacking = true
            elseif targetCount == 0 then
                Model.State.isBatchAttacking = false
            end
            
            if Model.State.isBatchAttacking then
                currentEnemy = findBestTarget(allEnemies)
            else
                currentEnemy = nil
            end
        end
        
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
        
        -- Apply combat offset positioning relative to target
        local altOffset = getgenv().CombatAltitudeOffset or 4
        local targetSpot = Vector3.new(targetRoot.Position.X, targetRoot.Position.Y + altOffset, targetRoot.Position.Z)
        local isUnderHoverboard = false
        
        if currentEnemy.Name == "Megalodon" and getgenv().CachedHoverboard and getgenv().CachedHoverboard.Parent then
            local main = getgenv().CachedHoverboard:FindFirstChild("m")
            if main then
                -- Hide 5 studs below and 4 studs forward underneath the hoverboard!
                targetSpot = (main.CFrame * CFrame.new(0, -5, -4)).Position
                isUnderHoverboard = true
            end
        end
        
        -- Proactive Raycast Anti-Stuck System
        if not isUnderHoverboard then
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
        end
        
        local distance = (rootPart.Position - targetSpot).Magnitude
        
        local moveTargetSpot = targetSpot
        local finalCFrame = CFrame.lookAt(targetSpot, targetRoot.Position)
        
        Model.Geppo()
        
        if distance > 0.5 and not isUnderHoverboard then
            -- Keep character facing the enemy like a bomber
            local bg = rootPart:FindFirstChild("AntiRotation") or Instance.new("BodyGyro")
            bg.Name = "AntiRotation"
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 3000
            bg.D = 500
            bg.CFrame = CFrame.lookAt(rootPart.Position, targetRoot.Position)
            bg.Parent = rootPart
            
            -- Pure physics flight with Geppo!
            local speed = getgenv().CyborgFlySpeed or 50
            local direction = (moveTargetSpot - rootPart.Position).Unit
            local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
            bv.Name = "AntiGravity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = direction * speed
            bv.Parent = rootPart
        else
            local bv = rootPart:FindFirstChild("AntiGravity")
            if bv then bv.Velocity = Vector3.new(0, 0, 0) end
            local bg = rootPart:FindFirstChild("AntiRotation")
            if bg then bg.CFrame = finalCFrame end
            rootPart.CFrame = finalCFrame
        end
    else
        -- If we have no target, return to Hoverboard (if exists) or hover at altitude
        local hoverboardModel = nil
        local hoverboardPos = nil
        
        if getgenv().CachedHoverboard and getgenv().CachedHoverboard.Parent then
            hoverboardModel = getgenv().CachedHoverboard
            local main = hoverboardModel:FindFirstChild("m")
            if main then
                hoverboardPos = (main.CFrame * CFrame.new(0, 4, 5)).Position
            else
                getgenv().CachedHoverboard = nil
            end
        else
            local closestDist = math.huge
            for _, obj in ipairs(workspace:GetDescendants()) do
                -- Identify hoverboard robustly by looking for 'm' and 'BodyPosition'
                if obj:IsA("Model") and obj:FindFirstChild("m") and obj.m:FindFirstChild("BodyPosition") then
                    local main = obj.m
                    local distToBoard = (main.Position - rootPart.Position).Magnitude
                    if distToBoard < closestDist then
                        closestDist = distToBoard
                        hoverboardModel = obj
                        getgenv().CachedHoverboard = obj
                        hoverboardPos = (main.CFrame * CFrame.new(0, 4, 5)).Position
                    end
                end
            end
        end
        
        local isStandingOnHoverboard = false
        if hoverboardModel then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {character}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local rayHit = workspace:Raycast(rootPart.Position, Vector3.new(0, -15, 0), rayParams)
            if rayHit and rayHit.Instance and rayHit.Instance:IsDescendantOf(hoverboardModel) then
                isStandingOnHoverboard = true
            end
        end
        
        if hoverboardModel and hoverboardPos then
            if isStandingOnHoverboard then
                -- Safely on the hoverboard! Disable flight!
                if rootPart:FindFirstChild("AntiGravity") then rootPart.AntiGravity:Destroy() end
                if rootPart:FindFirstChild("AntiRotation") then rootPart.AntiRotation:Destroy() end
            else
                local dist = (rootPart.Position - hoverboardPos).Magnitude
                
                if dist > 6 then
                    -- Not on the hoverboard, fly to it smoothly
                    Model.SetCyborgFlight(true)
                    Model.Geppo()
                    
                    local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
                    bv.Name = "AntiGravity"
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    bv.Parent = rootPart
                    
                    local speed = getgenv().CyborgFlySpeed or 50
                    local direction = (hoverboardPos - rootPart.Position).Unit
                    bv.Velocity = direction * speed
                    
                    local bg = rootPart:FindFirstChild("AntiRotation") or Instance.new("BodyGyro")
                    bg.Name = "AntiRotation"
                    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                    bg.CFrame = CFrame.lookAt(rootPart.Position, hoverboardPos)
                    bg.Parent = rootPart
                else
                    -- Very close! Snap (tween) perfectly to the spot so the raycast detects us next frame!
                    rootPart.CFrame = CFrame.new(hoverboardPos)
                    if rootPart:FindFirstChild("AntiGravity") then rootPart.AntiGravity.Velocity = Vector3.new(0,0,0) end
                end
            end
        else
            -- Fallback if no hoverboard found: hover in the air
            Model.SetCyborgFlight(true)
            Model.Geppo()
            
            local alt = getgenv().CyborgFlyAltitude or 250
            local targetSpot = Vector3.new(rootPart.Position.X, alt, rootPart.Position.Z)
            local distance = (rootPart.Position - targetSpot).Magnitude
            
            local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
            bv.Name = "AntiGravity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = rootPart
            
            if distance > 0.5 then
                local speed = getgenv().CyborgFlySpeed or 50
                local direction = (targetSpot - rootPart.Position).Unit
                bv.Velocity = direction * speed
            else
                bv.Velocity = Vector3.new(0, 0, 0)
                rootPart.CFrame = CFrame.new(targetSpot) * rootPart.CFrame.Rotation
            end
            
            if rootPart:FindFirstChild("AntiRotation") then
                rootPart.AntiRotation:Destroy()
            end
        end
        
        if Model.State.currentTween then
            Model.State.currentTween:Cancel()
            Model.State.currentTween = nil
        end
    end
end

function Model.EquipRod()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    -- Check if weapon is equipped and unequip it first
    if character:FindFirstChild(WEAPON_NAME) then
        humanoid:UnequipTools()
        task.wait(0.2)
    end
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and table.find(VALID_RODS, tool.Name) then return end
    end
    
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and table.find(VALID_RODS, tool.Name) then
                humanoid:EquipTool(tool)
                task.wait(0.2)
                return
            end
        end
    end
end

function Model.UnequipRod()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and table.find(VALID_RODS, tool.Name) then
            humanoid:UnequipTools()
            task.wait(0.2)
            return
        end
    end
end

function Model.EquipWeapon()
    Model.UnequipRod() -- Ensure rod is unequipped before equipping Cyborg
    local character = LocalPlayer.Character
    if not character or character:FindFirstChild(WEAPON_NAME) then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if humanoid and backpack then
        local weaponTool = backpack:FindFirstChild(WEAPON_NAME)
        if weaponTool then humanoid:EquipTool(weaponTool) end
    end
end

function Model.DoFishingCycle()
    local hookName = LocalPlayer.Name .. "'s hook"
    if workspace.Effects:FindFirstChild(hookName) then 
        pcall(function() FishingActionRemote:InvokeServer({ Action = "Cancel" }) end)
        task.wait(0.5) 
        return 
    end
    local character = LocalPlayer.Character
    if not character then return end

    Model.EquipRod()
    task.wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local throwTrack = playAnimation(THROW_ANIMATION_ID)
    if throwTrack then task.delay(0.8, function() throwTrack:Stop(0.15) end) end

    local lookPos = rootPart.Position + (rootPart.CFrame.LookVector * 40)
    local throwGoal = Vector3.new(lookPos.X, 10, lookPos.Z) -- Ensure it reaches the water level
    pcall(function() FishingActionRemote:InvokeServer({ Bait = getgenv().CyborgTargetBait or "Deep Sea Bait", Action = "Throw", Goal = throwGoal }) end)

    local hook = workspace.Effects:WaitForChild(hookName, 3)
    if hook then
        local maxWait, waited = 15, 0
        while waited < maxWait do
            if not Model.State.isAutoFarming or getgenv().RoarHeard then 
                pcall(function() FishingActionRemote:InvokeServer({ Action = "Cancel" }) end)
                return 
            end
            
            if hook:GetAttribute("Caught") == true or hook:FindFirstChild("ReelLoop") then
                local isBeast = false
                local bWaited = 0
                local initialSoundTime = nil
                
                while hook.Parent do
                    -- Quickly copy valid sounds from our zero-lag cache
                    local beastSounds = {}
                    if getgenv().DSC_SoundCache then
                        for i = #getgenv().DSC_SoundCache, 1, -1 do
                            local s = getgenv().DSC_SoundCache[i]
                            if s.Parent then
                                table.insert(beastSounds, s)
                            else
                                table.remove(getgenv().DSC_SoundCache, i) -- Clean up deleted sounds
                            end
                        end
                    end
                    
                    -- 1. Check for initial sound in character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        for _, child in ipairs(rootPart:GetChildren()) do
                            if child:IsA("Sound") and child.Playing then
                                if not initialSoundTime and (child.Name == "Small" or child.Name == "Medium" or child.Name == "Large" or child.Name == "Giant") then
                                    print("🐟 Initial sound detected:", child.Name, "- Waiting 0.3s for possible Beast sound...")
                                    initialSoundTime = bWaited
                                end
                            end
                        end
                    end
                    
                    -- 2. Check ALL beast sounds globally
                    for _, s in ipairs(beastSounds) do
                        -- A fresh bite sound will have just started (TimePosition < 3.0)
                        -- Lingering roars from previous catches will be > 7.0s because the reel animation takes 6s!
                        if s.Playing and s.TimePosition < 3.0 then
                            local parentName = s.Parent and s.Parent.Name or "nil"
                            print("🔥 BEAST SOUND DETECTED! Name:", s.Name, "Time:", string.format("%.1f", s.TimePosition), "Parent:", parentName)
                            isBeast = true
                            break
                        end
                    end
                    
                    if isBeast then break end
                    
                    if initialSoundTime and (bWaited - initialSoundTime >= 0.3) then
                        print("⏱️ 0.3s passed with no Beast sound. Safe to cancel.")
                        break
                    end
                    
                    if bWaited >= 5.0 then
                        break -- Hard safety timeout
                    end
                    
                    task.wait(0.1)
                    bWaited += 0.1
                end
                
                if isBeast then
                    getgenv().RoarHeard = true
                    print("🔥 REELING IN THE BEAST! 🔥")
                    local reelTrack = playAnimation(REEL_ANIMATION_ID)
                    task.wait(6)
                    pcall(function() FishingActionRemote:InvokeServer({ Action = "Reel" }) end)
                    if reelTrack then reelTrack:Stop(0.2) end
                    return -- Done fishing, ready for combat!
                else
                    -- Not a beast, cancel immediately to save bait
                    print("❌ No Megalodon detected. Cancelling normal fish to save bait.")
                    pcall(function() FishingActionRemote:InvokeServer({ Action = "Reel" }) end)
                    task.wait()
                    pcall(function() FishingActionRemote:InvokeServer({ Action = "Cancel" }) end)
                end
                break
            end
            
            -- Keep checking for Beast Sound while waiting for bite
            if not getgenv().RoarHeard then
                if Model.CheckBeastSound() then
                    getgenv().RoarHeard = true
                    -- Beast heard, cancel fishing and prepare for battle!
                    pcall(function() FishingActionRemote:InvokeServer({ Action = "Cancel" }) end)
                    return
                end
            end
            
            task.wait(0.1); waited += 0.1
        end
    end
    pcall(function() FishingActionRemote:InvokeServer({ Action = "Cancel" }) end)
    task.wait()
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
        if isFarming then
            Model.State.hasEnteredFactory = false
        end
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
    local setHoverBtn = Instance.new("TextButton")
    setHoverBtn.Size = UDim2.new(1, 0, 0, 25)
    setHoverBtn.Position = UDim2.new(0, 0, 1, 65)
    setHoverBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
    setHoverBtn.Text = "Set Hoverboard Height"
    setHoverBtn.TextColor3 = Color3.new(1, 1, 1)
    setHoverBtn.Font = Enum.Font.GothamBold
    setHoverBtn.TextSize = 12
    setHoverBtn.Parent = toggleBtn
    Instance.new("UICorner", setHoverBtn).CornerRadius = UDim.new(0, 4)

    local resetHoverBtn = Instance.new("TextButton")
    resetHoverBtn.Size = UDim2.new(1, 0, 0, 25)
    resetHoverBtn.Position = UDim2.new(0, 0, 1, 95)
    resetHoverBtn.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
    resetHoverBtn.Text = "Reset Hoverboard"
    resetHoverBtn.TextColor3 = Color3.new(1, 1, 1)
    resetHoverBtn.Font = Enum.Font.GothamBold
    resetHoverBtn.TextSize = 12
    resetHoverBtn.Parent = toggleBtn
    Instance.new("UICorner", resetHoverBtn).CornerRadius = UDim.new(0, 4)


    local absoluteTargetY = 0

    setHoverBtn.MouseButton1Click:Connect(function()
        local desiredHeight = tonumber(string.match(heightInput.Text, "%d+"))
        if not desiredHeight then return end
        
        local character = Players.LocalPlayer.Character
        if not character or not character:FindFirstChild("Humanoid") or not character.Humanoid.SeatPart then
            setHoverBtn.Text = "Sit in Hoverboard!"
            task.wait(1)
            setHoverBtn.Text = "Set Hoverboard Height"
            return
        end
        
        local seat = character.Humanoid.SeatPart
        local ship = seat.Parent
        local bodyPos = ship:FindFirstChild("m") and ship.m:FindFirstChild("BodyPosition")
        
        if not bodyPos then return end
        
        absoluteTargetY = bodyPos.Position.Y

        RunService:BindToRenderStep("CustomHoverboardLaser", 2000, function()
            if absoluteTargetY < desiredHeight - 2 then
                absoluteTargetY = absoluteTargetY + 2
            elseif absoluteTargetY > desiredHeight + 2 then
                absoluteTargetY = absoluteTargetY - 2
            else
                absoluteTargetY = desiredHeight + (math.sin(tick() * 4) * 0.8)
            end
            
            bodyPos.Position = Vector3.new(bodyPos.Position.X, absoluteTargetY, bodyPos.Position.Z)
        end)
        
        setHoverBtn.Text = "Ascending Safely!"
        setHoverBtn.BackgroundColor3 = Color3.fromRGB(45, 200, 100)
        task.wait(1)
        setHoverBtn.Text = "Set Hoverboard Height"
        setHoverBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
    end)

    resetHoverBtn.MouseButton1Click:Connect(function()
        RunService:UnbindFromRenderStep("CustomHoverboardLaser")
        
        resetHoverBtn.Text = "Restored!"
        resetHoverBtn.BackgroundColor3 = Color3.fromRGB(45, 200, 100)
        task.wait(1)
        resetHoverBtn.Text = "Reset Hoverboard"
        resetHoverBtn.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
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
        -- Automatically Fish in background when waiting
        task.spawn(function()
            while Model.State.isAutoFarming do
                if not currentEnemy and not getgenv().RoarHeard then
                    Model.DoFishingCycle()
                else
                    task.wait(1)
                end
            end
        end)

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
                        
                        local isAtHoverSpot = false
                        if targetRoot then
                            if currentEnemy.Name == "Megalodon" and getgenv().CachedHoverboard and getgenv().CachedHoverboard.Parent then
                                -- If we're anchored to the hoverboard, just check if we're in range!
                                local dist = (rootPart.Position - targetRoot.Position).Magnitude
                                if dist < 250 then
                                    isAtHoverSpot = true
                                end
                            else
                                -- Standard flight mode: check if we reached the X/Z coordinates
                                local alt = getgenv().CyborgFlyAltitude or 190
                                local targetSpot = Vector3.new(targetRoot.Position.X, alt, targetRoot.Position.Z)
                                local distToEnemyGround = Vector2.new(rootPart.Position.X - targetSpot.X, rootPart.Position.Z - targetSpot.Z).Magnitude
                                if distToEnemyGround < 10 then
                                    isAtHoverSpot = true
                                end
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
