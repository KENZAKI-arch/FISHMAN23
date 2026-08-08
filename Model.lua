local Model = {}

local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local combatRegister = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("CombatRegister", 9e9)
local questEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Quest", 9e9)
local statsEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("stats", 9e9)
local npcsFolder = workspace:WaitForChild("NPCs", 9e9)

-- ADDED: isQuesting switch
Model.State = {
    isAutoFarming = false,
    isRecovering = false,
    isQuesting = false 
}

local flySpeed = 35
local currentEnemy = nil
local absoluteFloorHeight = nil 
local targetSwitchTimer = 2
local switchInterval = 2

function Model.ResetPhysics()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        root.Anchored = false
        local bv = root:FindFirstChild("AntiGravity")
        if bv then bv:Destroy() end
    end
    currentEnemy = nil
    absoluteFloorHeight = nil
end

function Model.ApplyNoclip()
    -- Intentionally left blank to avoid Msg 15
end

function Model.UpdateTracking(deltaTime)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return end
    
    -- Prevent combat tracking from fighting against questing or recovery flight loops
    if Model.State.isQuesting or Model.State.isRecovering then return end

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

    -- Clear enemy if it is dead, destroyed, or missing its RootPart
    if currentEnemy and (currentEnemy.Parent == nil or not currentEnemy:FindFirstChild("HumanoidRootPart") or not currentEnemy:FindFirstChild("Humanoid") or currentEnemy.Humanoid.Health <= 0) then
        currentEnemy = nil
        targetSwitchTimer = switchInterval
    end

    targetSwitchTimer = targetSwitchTimer + deltaTime
    if targetSwitchTimer >= switchInterval and npcsFolder then
        targetSwitchTimer = 0
        -- Switch between NEARBY valid enemies to keep combat dynamic without causing slow cross-map floating
        local nearbyEnemies = {}
        for _, npc in pairs(npcsFolder:GetChildren()) do
            if npc.Name == "Fishman Karate User" and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                -- Increased radius from 40 to 150 to ensure it detects the rest of the mob cluster
                if npc ~= currentEnemy and (rootPart.Position - npc.HumanoidRootPart.Position).Magnitude <= 150 then
                    table.insert(nearbyEnemies, npc)
                end
            end
        end
        if #nearbyEnemies > 0 then
            currentEnemy = nearbyEnemies[math.random(1, #nearbyEnemies)]
        end
    end

    -- Select the CLOSEST valid enemy if we don't have a target
    if not currentEnemy and npcsFolder then
        local closestEnemy = nil
        local shortestDistance = math.huge
        for _, npc in pairs(npcsFolder:GetChildren()) do
            if npc.Name == "Fishman Karate User" and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                local dist = (rootPart.Position - npc.HumanoidRootPart.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestEnemy = npc
                end
            end
        end
        currentEnemy = closestEnemy
    end

    if currentEnemy then
        local targetRoot = currentEnemy.HumanoidRootPart
        if absoluteFloorHeight == nil then absoluteFloorHeight = targetRoot.Position.Y + 7.5 end
        
        -- Hover directly above current target rather than highest NPC across the entire map
        local dynamicAltitude = targetRoot.Position.Y + 7.5

        local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
        bv.Name = "AntiGravity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = rootPart

        local targetSpot = Vector3.new(targetRoot.Position.X, dynamicAltitude, targetRoot.Position.Z)
        local finalCFrame = CFrame.lookAt(targetSpot, targetRoot.Position)
        local distance = (rootPart.Position - targetSpot).Magnitude
        
        if distance > 0.5 then
            local lerpAlpha = math.clamp((flySpeed * deltaTime) / distance, 0, 1)
            rootPart.CFrame = rootPart.CFrame:Lerp(finalCFrame, lerpAlpha)
        else
            rootPart.CFrame = finalCFrame
        end
    else
        if absoluteFloorHeight then
            rootPart.CFrame = CFrame.new(rootPart.Position.X, absoluteFloorHeight, rootPart.Position.Z)
        end
    end
    
    rootPart.Velocity = Vector3.new(0, 0, 0)
    rootPart.RotVelocity = Vector3.new(0, 0, 0)
end

function Model.GrabQuest()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local becky = npcsFolder and npcsFolder:FindFirstChild("Becky")
    local beckyRoot = becky and becky:FindFirstChild("HumanoidRootPart")
    
    if not rootPart or not beckyRoot then return end

    -- Prevent getting the quest if player is below level 190
    local isHighEnoughLevel = true
    pcall(function()
        local levelLabel = LocalPlayer.PlayerGui.HUD.Main.Bars.Experience.Detail.Level
        local levelNum = tonumber(string.match(levelLabel.Text, "%d+"))
        if levelNum and levelNum < 190 then
            isHighEnoughLevel = false
        end
    end)
    
    if not isHighEnoughLevel then return end

    -- Turn ON questing mode to pause combat smoothly
    Model.State.isQuesting = true 

    local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
    bv.Name = "AntiGravity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = rootPart

    local beckyPos = beckyRoot.Position
    local hoverAltitude = absoluteFloorHeight or (beckyPos.Y + 7.5)
    local targetSpot = Vector3.new(beckyPos.X, hoverAltitude, beckyPos.Z + 3)

    -- Fly to Becky
    while Model.State.isQuesting and Model.State.isAutoFarming do 
        local distance = (rootPart.Position - targetSpot).Magnitude
        if distance <= 2 then break end
        local dt = task.wait()
        local lerpAlpha = math.clamp((flySpeed * dt) / distance, 0, 1)
        rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.lookAt(targetSpot, beckyPos), lerpAlpha)
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
    end

    -- Grab the quest
    if Model.State.isAutoFarming then
        pcall(function() questEvent:InvokeServer("npcChat", true) end)
        task.wait(0.5)
        pcall(function()
            local args = {
                [1] = {
                    [1] = "takequest";
                    [2] = "Help becky";
                };
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("Quest", 9e9):InvokeServer(unpack(args))
        end)
        task.wait(0.5)
    end
    
    -- Turn OFF questing mode to resume combat
    Model.State.isQuesting = false 
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
    for _, npc in pairs(npcsFolder:GetChildren()) do
        if npc.Name == "Fishman Karate User" and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
            if (character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude <= 22 then
                table.insert(enemiesList, npc)
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
        -- Break if turned off, recovering, or questing
        if not Model.State.isAutoFarming or Model.State.isRecovering or Model.State.isQuesting then break end
        
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
        
        if not Model.State.isAutoFarming or Model.State.isRecovering or Model.State.isQuesting then break end
        
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

function Model.UpgradeStats()
    pcall(function()
        local args = {
            "Strength",
            nil,
            1
        }
        if statsEvent then
            statsEvent:FireServer(unpack(args))
        end
    end)
end

return Model