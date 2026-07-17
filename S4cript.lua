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
    "Scientist",
    "FactoryPool"
}

-- Global Speed Adjuster
getgenv().CyborgFlySpeed = 50

-- Global Altitude Adjuster (Y offset above enemy)
getgenv().CyborgFlyAltitude = 30



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
local function isAlertLevelHigh()
    if not Model.State.cachedFactorySign or not Model.State.cachedFactorySign.Parent then
        local islands = Workspace:FindFirstChild("Islands")
        local roseKingdom = islands and islands:FindFirstChild("Rose Kingdom")
        local factory = roseKingdom and roseKingdom:FindFirstChild("Factory")
        
        local exactPath = factory
            and factory:FindFirstChild("FrontDoor") 
            and factory.FrontDoor:FindFirstChild("Top") 
            and factory.FrontDoor.Top:FindFirstChild("BillboardGui")
            
        if exactPath then
            Model.State.cachedFactorySign = exactPath:FindFirstChildOfClass("TextLabel")
        end
    end
    
    if Model.State.cachedFactorySign then
        local text = Model.State.cachedFactorySign.Text
        if string.find(text, "🚨🚨🚨🚨") or string.find(text, "🚨🚨🚨🚨🚨") then
            return true
        end
    end
    return false
end

local function isFactoryOpen()
    local currentTime = os.clock()
    if currentTime - (Model.State.lastFactoryCheckTime or 0) < 5 then
        return Model.State.factoryCachedStatus ~= false
    end
    
    Model.State.lastFactoryCheckTime = currentTime
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then 
        Model.State.factoryCachedStatus = true
        return true
    end
    
    local isOpen = true
    if not Model.State.cachedFactorySign or not Model.State.cachedFactorySign.Parent then
        local islands = Workspace:FindFirstChild("Islands")
        local roseKingdom = islands and islands:FindFirstChild("Rose Kingdom")
        local factory = roseKingdom and roseKingdom:FindFirstChild("Factory")
        
        local exactPath = factory
            and factory:FindFirstChild("FrontDoor") 
            and factory.FrontDoor:FindFirstChild("Top") 
            and factory.FrontDoor.Top:FindFirstChild("BillboardGui")
            
        if exactPath then
            Model.State.cachedFactorySign = exactPath:FindFirstChildOfClass("TextLabel")
        end
    end
        
    if Model.State.cachedFactorySign then
        if string.find(string.upper(Model.State.cachedFactorySign.Text), "FACTORY CLOSED") then
            isOpen = false
        end
    end
    
    Model.State.factoryCachedStatus = isOpen
    return isOpen
end
local function isValidTarget(npc, targetName)
    if npc.Name ~= targetName then return false end
    
    if targetName == "FactoryPool" then
        local barrelHP = npc:FindFirstChild("barrelHP")
        if barrelHP and barrelHP.Value > 0 then
            -- FactoryPool's HumanoidRootPart gets destroyed at low HP, so we check for hitbox/Pool
            if npc:FindFirstChild("hitbox") or npc:FindFirstChild("Pool") then
                return true
            end
        end
        return false
    end
    
    if not npc:FindFirstChild("HumanoidRootPart") then return false end
    
    -- Check normal Humanoid
    local humanoid = npc:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then return true end
    
    return false
end

-- Phase-based target and objective selection
local function determinePhaseObjective(allEnemies)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil, nil end
    
    Model.State.FarmPhase = Model.State.FarmPhase or 1
    Model.State.AggroedEnemies = Model.State.AggroedEnemies or {}
    
    local function getFloor(y)
        if y >= 250 then return 3
        elseif y >= 140 then return 2
        else return 1 end
    end
    
    -- Filter valid enemies
    local validEnemies = {}
    for _, npc in pairs(allEnemies) do
        for _, tName in ipairs(TARGET_SEQUENCE) do
            if isValidTarget(npc, tName) then
                if npc:FindFirstChild("HumanoidRootPart") or (tName == "FactoryPool" and (npc:FindFirstChild("hitbox") or npc:FindFirstChild("Pool"))) then
                    table.insert(validEnemies, {npc = npc, name = tName})
                    break
                end
            end
        end
    end
    
    -- Cleanup dead enemies from Aggro list
    local newAggro = {}
    for _, v in pairs(validEnemies) do
        if Model.State.AggroedEnemies[v.npc] then
            newAggro[v.npc] = true
        end
    end
    Model.State.AggroedEnemies = newAggro

    local myPos = rootPart.Position
    
    -- Phase 1: Round up Floor 1 & 2
    if Model.State.FarmPhase == 1 then
        local unAggroed = {}
        for _, v in pairs(validEnemies) do
            if v.name ~= "FactoryPool" then
                local y = v.npc.HumanoidRootPart.Position.Y
                local floor = getFloor(y)
                if floor <= 2 and not Model.State.AggroedEnemies[v.npc] then
                    table.insert(unAggroed, v.npc)
                end
            end
        end
        
        if #unAggroed > 0 then
            table.sort(unAggroed, function(a, b)
                local floorA = getFloor(a.HumanoidRootPart.Position.Y)
                local floorB = getFloor(b.HumanoidRootPart.Position.Y)
                if floorA ~= floorB then
                    return floorA > floorB -- Prioritize 2nd floor first so they follow us down to the ground!
                else
                    return (myPos - a.HumanoidRootPart.Position).Magnitude < (myPos - b.HumanoidRootPart.Position).Magnitude
                end
            end)
            local target = unAggroed[1]
            for _, npc in ipairs(unAggroed) do
                if (myPos - npc.HumanoidRootPart.Position).Magnitude < 50 then
                    Model.State.AggroedEnemies[npc] = true
                end
            end
            return target, nil
        else
            Model.State.FarmPhase = 2
        end
    end
    
    -- Phase 2: Nuke Floor 1 & 2
    if Model.State.FarmPhase == 2 then
        local alive = {}
        for _, v in pairs(validEnemies) do
            if v.name ~= "FactoryPool" then
                local y = v.npc.HumanoidRootPart.Position.Y
                local floor = getFloor(y)
                if floor <= 2 then table.insert(alive, v.npc) end
            end
        end
        
        if #alive > 0 then
            -- Hover dynamically above a random enemy to keep shifting positions and dragging the train!
            return alive[math.random(1, #alive)], nil
        else
            Model.State.FarmPhase = 3
        end
    end
    
    -- Phase 3: Round up Floor 3
    if Model.State.FarmPhase == 3 then
        local unAggroed = {}
        for _, v in pairs(validEnemies) do
            if v.name ~= "FactoryPool" then
                local y = v.npc.HumanoidRootPart.Position.Y
                local floor = getFloor(y)
                if floor == 3 and not Model.State.AggroedEnemies[v.npc] then
                    table.insert(unAggroed, v.npc)
                end
            end
        end
        
        if #unAggroed > 0 then
            table.sort(unAggroed, function(a, b)
                return (myPos - a.HumanoidRootPart.Position).Magnitude < (myPos - b.HumanoidRootPart.Position).Magnitude
            end)
            local target = unAggroed[1]
            for _, npc in ipairs(unAggroed) do
                if (myPos - npc.HumanoidRootPart.Position).Magnitude < 50 then
                    Model.State.AggroedEnemies[npc] = true
                end
            end
            return target, nil
        else
            Model.State.FarmPhase = 4
        end
    end
    
    -- Phase 4: Nuke Floor 3
    if Model.State.FarmPhase == 4 then
        local alive = {}
        for _, v in pairs(validEnemies) do
            if v.name ~= "FactoryPool" then
                local y = v.npc.HumanoidRootPart.Position.Y
                local floor = getFloor(y)
                if floor == 3 then table.insert(alive, v.npc) end
            end
        end
        
        if #alive > 0 then
            -- Hover dynamically above a random enemy to keep shifting positions and dragging the train!
            return alive[math.random(1, #alive)], nil
        else
            Model.State.FarmPhase = 5
        end
    end
    
    -- Phase 5: FactoryPool
    if Model.State.FarmPhase == 5 then
        local factoryPool = nil
        local otherEnemiesAlive = false
        
        for _, v in pairs(validEnemies) do
            if v.name == "FactoryPool" then
                factoryPool = v.npc
            else
                otherEnemiesAlive = true
            end
        end
        
        if factoryPool then
            return factoryPool, nil
        elseif not otherEnemiesAlive then
            Model.State.FarmPhase = 1
            return nil, nil
        else
            Model.State.FarmPhase = 1
            return validEnemies[1].npc, nil
        end
    end
    
    return nil, nil
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
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if enabled then
        if not Model.State.flightAnimTrack then
            local anim = game.ReplicatedStorage:FindFirstChild("SkillCallbacks") 
                and game.ReplicatedStorage.SkillCallbacks:FindFirstChild("FistStyles")
                and game.ReplicatedStorage.SkillCallbacks.FistStyles:FindFirstChild("Cyborg")
                and game.ReplicatedStorage.SkillCallbacks.FistStyles.Cyborg:FindFirstChild("Fly")
                and game.ReplicatedStorage.SkillCallbacks.FistStyles.Cyborg.Fly:FindFirstChild("front")
                
            if anim then
                Model.State.flightAnimTrack = humanoid:LoadAnimation(anim)
            end
        end
        if Model.State.flightAnimTrack and not Model.State.flightAnimTrack.IsPlaying then
            Model.State.flightAnimTrack:Play()
        end
    else
        if Model.State.flightAnimTrack and Model.State.flightAnimTrack.IsPlaying then
            Model.State.flightAnimTrack:Stop()
        end
    end
end

function Model.SetCyborgFlight(enabled)
    local character = LocalPlayer.Character
    if not character then return end
    
    task.spawn(function()
        pcall(function()
            local isFlying = character:GetAttribute("flyMode")
            
            if enabled then
                if not isFlying and not Model.State.cyborgFlightCancelEvent and not Model.State.isRequestingFlight then
                    Model.State.isRequestingFlight = true
                    local skillEvent = game.ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Skill", 9e9)
                    Model.State.cyborgFlightCancelEvent = skillEvent:InvokeServer("Cyborg Flight")
                    
                    if not Model.State.cyborgFlightCancelEvent then
                        -- Cooldown or fail, wait 1s before trying again to prevent server spam
                        task.wait(1)
                    end
                    Model.State.isRequestingFlight = false
                end
            else
                if Model.State.cyborgFlightCancelEvent then
                    Model.State.cyborgFlightCancelEvent:InvokeServer()
                    Model.State.cyborgFlightCancelEvent = nil
                elseif isFlying then
                    -- Fallback to cancel natively if we lost the reference
                    local skillEvent = game.ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Skill", 9e9)
                    local tempCancel = skillEvent:InvokeServer("Cyborg Flight")
                    if tempCancel then tempCancel:InvokeServer() end
                end
                
                -- Emergency visual cleanup (Client side)
                for _, v in pairs(character:GetDescendants()) do
                    if v:IsA("ParticleEmitter") and (v.Name:lower():match("cyborg") or v.Name == "geppo") then
                        v.Enabled = false
                    end
                end
            end
        end)
    end)
end

function Model.ApplyNoclip()
    -- Map noclip: Make the whole factory a ghost EXCEPT floor1 and 2floor
    local factory = workspace:FindFirstChild("Islands") 
        and workspace.Islands:FindFirstChild("Rose Kingdom")
        and workspace.Islands["Rose Kingdom"]:FindFirstChild("Factory")
        
    if factory then
        for _, v in ipairs(factory:GetDescendants()) do
            if v:IsA("BasePart") then
                -- Check if this part is inside floor1 or 2floor
                local isExcluded = false
                local parent = v.Parent
                while parent and parent ~= factory do
                    if parent.Name == "floor1" or parent.Name == "2floor" then
                        isExcluded = true
                        break
                    end
                    parent = parent.Parent
                end
                
                -- If it's NOT in those folders, make it a ghost!
                -- This means floor1 and 2floor remain perfectly solid and immune to noclip!
                if not isExcluded then
                    v.CanCollide = false
                end
            end
        end
    end
    
    -- Ensure character remains solid so it can stand on the immune floors
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
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
            if hum and hum.Health > 0 then isAlive = true end
            if barrel and barrel.Value > 0 then isAlive = true end
        end
        if not isAlive then
            currentEnemy = nil
            targetSwitchTimer = switchInterval
        end
    end

    targetSwitchTimer = targetSwitchTimer + deltaTime
    
    Model.State.isWaitingAtSafeSpot = false
    local isFactoryClosedOrHighAlert = (not isFactoryOpen()) or isAlertLevelHigh()

    if isFactoryClosedOrHighAlert then
        Model.State.wasWaitingForFactory = true
        Model.State.resumePatrolTime = nil
        
        local safeSpot = Vector3.new(8807, 66, 11521)
        local flatTarget = Vector3.new(safeSpot.X, 0, safeSpot.Z)
        local flatCurrent = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
        
        if (flatTarget - flatCurrent).Magnitude < 15 then
            Model.State.isWaitingAtSafeSpot = true
            local bv = rootPart:FindFirstChild("AntiGravity")
            if bv then bv:Destroy() end
            
            -- Stop Flight skill if we reached safe spot
            Model.SetCyborgFlight(false)
            return
        else
            currentEnemy = nil
            Model.SetCyborgFlight(true)
            
            if not character:GetAttribute("flyMode") then
                Model.SetFlightAnimation(false)
                local bv = rootPart:FindFirstChild("AntiGravity")
                if bv then bv:Destroy() end
                local bg = rootPart:FindFirstChild("AntiRotation")
                if bg then bg:Destroy() end
                return
            end
            
            local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
            bv.Name = "AntiGravity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = rootPart
            
            Model.SetFlightAnimation(true)
            
            local direction = (safeSpot - rootPart.Position).Unit
            
            -- Keep character facing the movement direction
            local bg = rootPart:FindFirstChild("AntiRotation") or Instance.new("BodyGyro")
            bg.Name = "AntiRotation"
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 3000
            bg.D = 500
            bg.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + Vector3.new(direction.X, 0, direction.Z))
            bg.Parent = rootPart
            
            -- Pure physics flight!
            bv.Velocity = direction * flySpeed
            return
        end
    elseif Model.State.wasWaitingForFactory then
        Model.State.wasWaitingForFactory = false
        Model.State.resumePatrolTime = os.clock() + 5
        print("[AutoFarm] Factory/Alert cleared! Waiting 5 seconds before moving...")
        Model.State.isWaitingAtSafeSpot = true
        Model.SetFlightAnimation(false)
        local bv = rootPart:FindFirstChild("AntiGravity")
        if bv then bv:Destroy() end
        return
    elseif Model.State.resumePatrolTime and os.clock() < Model.State.resumePatrolTime then
        Model.State.isWaitingAtSafeSpot = true
        Model.SetFlightAnimation(false)
        local bv = rootPart:FindFirstChild("AntiGravity")
        if bv then bv:Destroy() end
        return
    end

    if targetSwitchTimer >= switchInterval then
        targetSwitchTimer = 0
        currentEnemy, Model.State.currentHoverSpot = determinePhaseObjective(allEnemies)
        -- Trigger flight when finding a new target to maintain altitude
        if currentEnemy or Model.State.currentHoverSpot then
            Model.SetCyborgFlight(true)
        end
    end

    if currentEnemy or Model.State.currentHoverSpot then
        Model.SetCyborgFlight(true)
        
        if not character:GetAttribute("flyMode") and not Model.State.currentHoverSpot then
            Model.SetFlightAnimation(false)
            
            -- If flight is on cooldown, run to the enemy on the ground directly below where we want to bomb them!
            local targetRoot = currentEnemy and currentEnemy:FindFirstChild("HumanoidRootPart")
            if currentEnemy and currentEnemy.Name == "FactoryPool" then
                targetRoot = currentEnemy:FindFirstChild("hitbox") or currentEnemy:FindFirstChild("Pool") or targetRoot
            end
            local targetPos = targetRoot and targetRoot.Position or rootPart.Position
            local targetSpot = Vector3.new(targetPos.X, targetPos.Y, targetPos.Z)
            local distance = (rootPart.Position - targetSpot).Magnitude
            
            local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
            bv.Name = "AntiGravity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = rootPart
            
            if distance > 2 then
                local direction = (targetSpot - rootPart.Position).Unit
                -- Run speed on the ground
                bv.Velocity = direction * 50
                
                -- Look at the enemy on the ground
                local bg = rootPart:FindFirstChild("AntiRotation") or Instance.new("BodyGyro")
                bg.Name = "AntiRotation"
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.P = 3000
                bg.D = 500
                bg.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z))
                bg.Parent = rootPart
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end
            return
        end
        
        local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
        bv.Name = "AntiGravity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = rootPart

        local targetRoot = currentEnemy and currentEnemy:FindFirstChild("HumanoidRootPart")
        if currentEnemy and currentEnemy.Name == "FactoryPool" then
            targetRoot = currentEnemy:FindFirstChild("hitbox") or currentEnemy:FindFirstChild("Pool") or targetRoot
        end
        local targetPos = targetRoot and targetRoot.Position or rootPart.Position
        
        local targetSpot
        if Model.State.currentHoverSpot then
            targetSpot = Model.State.currentHoverSpot
        else
            -- Apply orbital anti-gravity positioning (customizable altitude above target)
            local altitude = getgenv().CyborgFlyAltitude or 30
            if Model.State.FarmPhase == 1 or Model.State.FarmPhase == 3 then
                altitude = 15 -- Hover 15 studs above their head to pull aggro without getting hit by melee!
            end
            targetSpot = Vector3.new(targetPos.X, targetPos.Y + altitude, targetPos.Z)
            -- Target Overrides
            if currentEnemy and currentEnemy.Name == "FactoryPool" then
                -- For FactoryPool, NEVER fly over it to avoid getting stuck in the core.
                -- Always hover at the access doorway and bomb it from there!
                targetSpot = Vector3.new(8664, 427, 11793)
            end
        end
        
        local distance = (rootPart.Position - targetSpot).Magnitude
        
        local moveTargetSpot = targetSpot
        
        local finalCFrame
        if (targetSpot - targetPos).Magnitude > 0.1 then
            finalCFrame = CFrame.lookAt(targetSpot, targetPos)
        else
            finalCFrame = CFrame.new(targetSpot, targetSpot + rootPart.CFrame.LookVector)
        end
        
        Model.SetFlightAnimation(true)
        
        if distance > 0.5 then
            local direction = (moveTargetSpot - rootPart.Position).Unit
            
            -- Keep character facing the enemy like a bomber
            local bg = rootPart:FindFirstChild("AntiRotation") or Instance.new("BodyGyro")
            bg.Name = "AntiRotation"
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 3000
            bg.D = 500
            
            if (rootPart.Position - targetPos).Magnitude > 0.1 then
                bg.CFrame = CFrame.lookAt(rootPart.Position, targetPos)
            end
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
        -- Keep Cyborg Flight active continuously between targets to save recast time!
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
    if not isFactoryOpen() or isAlertLevelHigh() then return {} end
    local enemiesList = {}
    local allEnemies = getAllEnemies()
    
    local function getFloor(y)
        if y >= 250 then return 3
        elseif y >= 140 then return 2
        else return 1 end
    end
    
    local phase = Model.State.FarmPhase or 1
    
    for _, npc in pairs(allEnemies) do
        for _, tName in ipairs(TARGET_SEQUENCE) do
            if isValidTarget(npc, tName) then
                local y = npc:FindFirstChild("HumanoidRootPart") and npc.HumanoidRootPart.Position.Y or 0
                if tName == "FactoryPool" then
                    local p = npc:FindFirstChild("hitbox") or npc:FindFirstChild("Pool")
                    if p then y = p.Position.Y end
                end
                
                local floor = getFloor(y)
                
                -- Only target enemies valid for the current phase!
                local phaseValid = true
                if phase == 2 and floor > 2 then
                    phaseValid = false
                elseif phase == 4 and floor ~= 3 then
                    phaseValid = false
                end
                
                local npcPos = npc:FindFirstChild("HumanoidRootPart") and npc.HumanoidRootPart.Position or Vector3.new(0,0,0)
                if tName == "FactoryPool" then
                    local p = npc:FindFirstChild("hitbox") or npc:FindFirstChild("Pool")
                    if p then npcPos = p.Position end
                end
                
                if phaseValid and (character.HumanoidRootPart.Position - npcPos).Magnitude <= 300 then
                    table.insert(enemiesList, npc)
                end
                break
            end
        end
    end
    
    -- Sort by closest horizontal distance to bot so we shoot straight down!
    local myPos = character.HumanoidRootPart.Position
    table.sort(enemiesList, function(a, b)
        local posA = a:FindFirstChild("HumanoidRootPart") and a.HumanoidRootPart.Position or Vector3.new(0,0,0)
        local posB = b:FindFirstChild("HumanoidRootPart") and b.HumanoidRootPart.Position or Vector3.new(0,0,0)
        local distA = Vector2.new(myPos.X - posA.X, myPos.Z - posA.Z).Magnitude
        local distB = Vector2.new(myPos.X - posB.X, myPos.Z - posB.Z).Magnitude
        return distA < distB
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
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, 5, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = toggleBtn
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    
    closeBtn.MouseButton1Click:Connect(function()
        if getgenv().StopAutofarm then
            getgenv().StopAutofarm()
        end
    end)

    local speedInput = Instance.new("TextBox")
    speedInput.Size = UDim2.new(0.5, -2, 0, 25)
    speedInput.Position = UDim2.new(0, 0, 1, 5)
    speedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedInput.Font = Enum.Font.GothamSemibold
    speedInput.TextSize = 12
    speedInput.Text = "Spd: " .. tostring(getgenv().CyborgFlySpeed or 50)
    speedInput.PlaceholderText = "Speed"
    speedInput.Parent = toggleBtn
    Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 4)

    speedInput.FocusLost:Connect(function()
        local num = tonumber(string.match(speedInput.Text, "%d+"))
        if num then
            getgenv().CyborgFlySpeed = math.clamp(num, 10, 300)
            speedInput.Text = "Spd: " .. tostring(getgenv().CyborgFlySpeed)
        else
            speedInput.Text = "Spd: " .. tostring(getgenv().CyborgFlySpeed or 50)
        end
    end)
    
    local altInput = Instance.new("TextBox")
    altInput.Size = UDim2.new(0.5, -2, 0, 25)
    altInput.Position = UDim2.new(0.5, 4, 1, 5)
    altInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    altInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    altInput.Font = Enum.Font.GothamSemibold
    altInput.TextSize = 12
    altInput.Text = "Y: " .. tostring(getgenv().CyborgFlyAltitude or 30)
    altInput.PlaceholderText = "Altitude"
    altInput.Parent = toggleBtn
    Instance.new("UICorner", altInput).CornerRadius = UDim.new(0, 4)

    altInput.FocusLost:Connect(function()
        local num = tonumber(string.match(altInput.Text, "%d+"))
        if num then
            getgenv().CyborgFlyAltitude = math.clamp(num, 0, 300)
            altInput.Text = "Y: " .. tostring(getgenv().CyborgFlyAltitude)
        else
            altInput.Text = "Y: " .. tostring(getgenv().CyborgFlyAltitude or 30)
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
                        
                        local shouldCast = true
                        -- ONLY CAST MISSILE SHOWER IF IN A NUKE PHASE (Phase 2, Phase 4, Phase 5)
                        if skillName == "Missle Shower" and (Model.State.FarmPhase == 1 or Model.State.FarmPhase == 3) then
                            shouldCast = false
                        end
                        
                        if shouldCast then
                            local rootPart = LocalPlayer.Character.HumanoidRootPart
                            local targetRoot = currentEnemy:FindFirstChild("HumanoidRootPart")
                            local targetSpot
                            
                            if Model.State.currentHoverSpot then
                                targetSpot = Model.State.currentHoverSpot
                            else
                                local altitude = getgenv().CyborgFlyAltitude or 30
                                targetSpot = targetRoot and Vector3.new(targetRoot.Position.X, targetRoot.Position.Y + altitude, targetRoot.Position.Z) or rootPart.Position
                                
                                if currentEnemy.Name == "FactoryPool" then
                                    targetSpot = Vector3.new(8664, 427, 11793)
                                end
                            end
                            
                            local distanceToTarget = (rootPart.Position - targetSpot).Magnitude
                            
                            local isAtHoverSpot = distanceToTarget < 10
                            if not Model.State.currentHoverSpot and currentEnemy.Name ~= "FactoryPool" then
                                 local distToEnemyGround = Vector2.new(rootPart.Position.X - targetSpot.X, rootPart.Position.Z - targetSpot.Z).Magnitude
                                 isAtHoverSpot = distToEnemyGround < 10
                            end
                            
                            if isAtHoverSpot then -- Only bomb if we have arrived at the intended hover spot
                            -- Fire the skill. We wait for it to finish before looping again.
                            pcall(function()
                                local targetPos = rootPart.Position
                                if targetRoot then
                                    targetPos = targetRoot.Position
                                elseif currentEnemy.Name == "FactoryPool" then
                                    local hitbox = currentEnemy:FindFirstChild("hitbox") or currentEnemy:FindFirstChild("Pool")
                                    if hitbox then targetPos = hitbox.Position end
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
                                        elseif targetToShoot and targetToShoot.Name == "FactoryPool" then
                                            local hitbox = targetToShoot:FindFirstChild("hitbox") or targetToShoot:FindFirstChild("Pool")
                                            currentAim = hitbox and CFrame.new(hitbox.Position) or CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0, 50, 0))
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
                        end -- Missing end added here to close shouldCast block
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
