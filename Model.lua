local Model = {}

local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local combatRegister = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("CombatRegister", 9e9)
local questEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Quest", 9e9)
local npcsFolder = workspace:WaitForChild("NPCs", 9e9)

Model.State = {
    isAutoFarming = false
}

local flySpeed = 40 
local returnSpeed = 90
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
        
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
    currentEnemy = nil
    absoluteFloorHeight = nil
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
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return "WAITING" end
    
    local rootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid
    
    local isRagdolled = (character.Parent and character.Parent.Name == "Ragdolls")
    local isStunned = character:FindFirstChild("Stun") or character:FindFirstChild("frozen") or _G.canuse == false
    local isDead = humanoid.Health <= 0
    
    if isRagdolled or isStunned or isDead then
        rootPart.Anchored = true
        rootPart.Velocity = Vector3.new(0, 0, 0)
        return "WAITING"
    else
        rootPart.Anchored = false
    end

    -- SIMPLE SAFE ZONE CHECK
    local islandsFolder = workspace:FindFirstChild("Islands")
    local fishmanIsland = islandsFolder and islandsFolder:FindFirstChild("Fishman Island")
    
    if fishmanIsland then
        local islandCFrame, islandSize = fishmanIsland:GetBoundingBox()
        local relativePos = islandCFrame:PointToObjectSpace(rootPart.Position)
        local halfSize = islandSize / 2 -- EXACT size, no buffer
        
        local isOutsideBox = math.abs(relativePos.X) > halfSize.X or 
                             math.abs(relativePos.Y) > halfSize.Y or 
                             math.abs(relativePos.Z) > halfSize.Z

        if isOutsideBox then
            local target = Vector3.new(7976.704, -2152.832, -17074.277)
            local nextPoint
            if math.abs(rootPart.Position.X - target.X) > 1 then
                nextPoint = Vector3.new(target.X, rootPart.Position.Y, rootPart.Position.Z)
            elseif math.abs(rootPart.Position.Z - target.Z) > 1 then
                nextPoint = Vector3.new(target.X, rootPart.Position.Y, target.Z)
            elseif math.abs(rootPart.Position.Y - target.Y) > 1 then
                nextPoint = Vector3.new(target.X, target.Y, target.Z)
            else
                nextPoint = target
            end

            local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
            bv.Name = "AntiGravity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = rootPart
            humanoid.PlatformStand = true

            local distance = (rootPart.Position - nextPoint).Magnitude
            if distance > 0 then
                local alpha = math.clamp((returnSpeed * deltaTime) / distance, 0, 1)
                rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(nextPoint), alpha)
            end
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.RotVelocity = Vector3.new(0, 0, 0)
            
            return "RETURNING"
        end
    end

    -- NORMAL ENEMY TRACKING (If inside the safe zone)
    humanoid.PlatformStand = false
    
    if currentEnemy and (currentEnemy.Parent == nil or not currentEnemy:FindFirstChild("Humanoid") or currentEnemy.Humanoid.Health <= 0) then
        currentEnemy = nil
        targetSwitchTimer = switchInterval
    end

    targetSwitchTimer = targetSwitchTimer + deltaTime
    if targetSwitchTimer >= switchInterval and npcsFolder then
        targetSwitchTimer = 0
        local validEnemies = {}
        for _, npc in pairs(npcsFolder:GetChildren()) do
            if npc.Name == "Fishman Karate User" and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                if npc ~= currentEnemy then table.insert(validEnemies, npc) end
            end
        end
        if #validEnemies > 0 then currentEnemy = validEnemies[math.random(1, #validEnemies)] end
    end

    if currentEnemy then
        local targetRoot = currentEnemy.HumanoidRootPart
        if absoluteFloorHeight == nil then absoluteFloorHeight = targetRoot.Position.Y + 7.5 end
        
        local dynamicAltitude = absoluteFloorHeight
        for _, npc in pairs(npcsFolder:GetChildren()) do
            if npc.Name == "Fishman Karate User" and npc:FindFirstChild("HumanoidRootPart") and npc.Humanoid.Health > 0 then
                local h = npc.HumanoidRootPart.Position.Y + 7.5
                if h > dynamicAltitude then dynamicAltitude = h end
            end
        end

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

    return "FARMING"
end

function Model.GrabQuest()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local becky = npcsFolder and npcsFolder:FindFirstChild("Becky")
    local beckyRoot = becky and becky:FindFirstChild("HumanoidRootPart")
    
    if not rootPart or not beckyRoot then return end

    local wasFarming = Model.State.isAutoFarming
    Model.State.isAutoFarming = false 

    local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
    bv.Name = "AntiGravity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = rootPart

    local beckyPos = beckyRoot.Position
    local hoverAltitude = absoluteFloorHeight or (beckyPos.Y + 7.5)
    local targetSpot = Vector3.new(beckyPos.X, hoverAltitude, beckyPos.Z + 3)

    while wasFarming do 
        local distance = (rootPart.Position - targetSpot).Magnitude
        if distance <= 2 then break end
        local dt = task.wait()
        local lerpAlpha = math.clamp((flySpeed * dt) / distance, 0, 1)
        rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.lookAt(targetSpot, beckyPos), lerpAlpha)
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
    end

    if wasFarming then
        -- Removed pcalls
        questEvent:InvokeServer("npcChat", true)
        task.wait(0.5)
        questEvent:InvokeServer("takequest", "Help becky")
        task.wait(0.5)
        Model.State.isAutoFarming = true 
    end
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
            if (character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude <= 15 then
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
        if not Model.State.isAutoFarming then break end
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then break end
        
        local myCFrame = character.HumanoidRootPart.CFrame
        local animName = "Punch" .. currentHit
        local punchAnim = ReplicatedStorage:WaitForChild("CombatAnimations", 9e9):WaitForChild("Melee", 9e9):WaitForChild(animName, 9e9)
        
        local swingArgs = { "swingsfx", "Melee", currentHit, "Ground", false, punchAnim, 2, 1.5 }
        -- Removed pcall
        task.spawn(function() combatRegister:InvokeServer(unpack(swingArgs)) end)
        task.wait(0.2)
        
        if not Model.State.isAutoFarming then break end
        
        local currentTargets = Model.GetEnemiesInRange()
        local roots = {}
        for _, npc in pairs(currentTargets) do
            if npc:FindFirstChild("HumanoidRootPart") then table.insert(roots, npc.HumanoidRootPart) end
        end
        
        if #roots > 0 then
            local damageArgs = {
                "damage", roots, "Melee", {currentHit, "Ground", "Melee"}, true, myCFrame, ["aircombo"] = "Ground"
            }
            -- Removed pcall
            task.spawn(function() combatRegister:InvokeServer(unpack(damageArgs)) end)
        end
        task.wait(0.2)
    end
    if Model.State.isAutoFarming then task.wait(0.1) end
end

return Model