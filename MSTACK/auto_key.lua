local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().CurrentPhase = "1. Auto Key"

local function findTargetAndPrompt()
    -- 0. ALWAYS check for super rare items first in Effects, regardless of phase
    local priorityItems = {"Musashi", "Rose Katana", "SP Reset"}
    local effects = Workspace:FindFirstChild("Effects")
    if effects then
        for _, itemName in ipairs(priorityItems) do
            for _, desc in ipairs(effects:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
                    local pName = string.lower(desc.Parent.Name)
                    local ppName = desc.Parent.Parent and string.lower(desc.Parent.Parent.Name) or ""
                    local targetName = string.lower(itemName)
                    
                    if string.find(pName, targetName) or string.find(ppName, targetName) then
                        return desc.Parent, desc, itemName
                    end
                end
            end
        end
    end

    if getgenv().CurrentPhase == "1. Auto Key" then
        -- 1. Prioritize Keys (Look in Effects first)
        if effects then
            local keyModel = effects:FindFirstChild("Key")
            if keyModel then
                local keyPart = keyModel:FindFirstChild("Key")
                if keyPart then
                    local prompt = keyPart:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and prompt.Enabled then
                        return keyPart, prompt, "Key"
                    end
                end
            end
        end
        
        -- 2. Fallback for Keys
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
                if desc.Parent.Name == "Key" then
                    return desc.Parent, desc, "Key"
                end
            end
        end
        
        print("[AutoKey] Key collected or not found. Moving to 2. Looting phase...")
        getgenv().CurrentPhase = "2. Looting phase"
    end
    
    if getgenv().CurrentPhase == "2. Looting phase" then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil, nil, nil end
        
        local myPos = hrp.Position
        
        local bestTargetPart = nil
        local bestPrompt = nil
        local bestName = nil
        local bestDist = math.huge
        local bestHasLOS = false
        
        -- Search for Chests or any other loot
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
                local actText = string.lower(desc.ActionText)
                local objText = string.lower(desc.ObjectText)
                
                -- Target any prompt that looks like a Chest
                if string.find(actText, "chest") or string.find(objText, "chest") then
                    local targetPart = desc.Parent
                    local targetPos = targetPart:IsA("Model") and targetPart:GetPivot().Position or targetPart.Position
                    local dist = (myPos - targetPos).Magnitude
                    
                    local name = desc.ObjectText ~= "" and desc.ObjectText or desc.ActionText
                    if name == "" then name = "Chest" end
                    
                    -- Check Line of Sight (LOS) so we don't try phasing through solid walls
                    local hasLOS = true
                    local dir = (targetPos - myPos)
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.IgnoreWater = true
                    
                    local currentIgnore = {char}
                    
                    -- Ignore the entire target model if it belongs to one
                    local tModel = targetPart:FindFirstAncestorOfClass("Model")
                    if tModel then
                        table.insert(currentIgnore, tModel)
                    else
                        table.insert(currentIgnore, targetPart)
                    end

                    for i = 1, 10 do
                        params.FilterDescendantsInstances = currentIgnore
                        local result = Workspace:Raycast(myPos, dir, params)
                        if result then
                            if result.Instance.CanCollide then
                                hasLOS = false
                                break
                            else
                                -- It's a non-collide part (like an effect or zone), ignore it and cast again
                                table.insert(currentIgnore, result.Instance)
                            end
                        else
                            break
                        end
                    end
                    
                    -- Smart Scoring Logic
                    if hasLOS and not bestHasLOS then
                        -- First unobstructed chest found! It automatically beats any obstructed ones.
                        bestTargetPart = targetPart
                        bestPrompt = desc
                        bestName = name
                        bestDist = dist
                        bestHasLOS = true
                    elseif hasLOS == bestHasLOS then
                        -- Both have LOS, or both don't have LOS. Pick the closer one.
                        if dist < bestDist then
                            bestTargetPart = targetPart
                            bestPrompt = desc
                            bestName = name
                            bestDist = dist
                        end
                    end
                end
            end
        end
        
        return bestTargetPart, bestPrompt, bestName
    end
    
    return nil, nil, nil
end

local function flyToAndInteract()
    local targetPart, prompt, targetType = findTargetAndPrompt()
    
    if not targetPart or not prompt then
        return
    end
    
    if prompt and prompt:IsA("ProximityPrompt") then
        print("[" .. getgenv().CurrentPhase .. "] " .. targetType .. " found! Flying to it...")
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            local bv = hrp:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
            bv.Name = "AntiGravity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp
            
            local targetCFrame = targetPart:IsA("Model") and targetPart:GetPivot() or targetPart.CFrame
            local targetPos = (targetCFrame * CFrame.new(0, 0, 1.5)).Position
            local flySpeed = 50
            
            -- Fly towards the target smoothly
            while getgenv().AutoKey and targetPart.Parent and hrp.Parent do
                local dist = (hrp.Position - targetPos).Magnitude
                if dist <= 1.5 then
                    break
                end
                
                local deltaTime = task.wait()
                local lerpAlpha = math.clamp((flySpeed * deltaTime) / dist, 0, 1)
                
                local lookAtCFrame = CFrame.lookAt(hrp.Position, targetPos)
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos) * lookAtCFrame.Rotation, lerpAlpha)
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
            end
            
            -- Keep the BodyVelocity alive so we don't fall during the interaction!
            if bv then bv.Velocity = Vector3.new(0, 0, 0) end
            
            -- Double check if the target is still valid after arriving
            if targetPart.Parent and prompt.Parent then
                -- Bypass ProximityPrompt restrictions locally
                local oldLOS = prompt.RequiresLineOfSight
                local oldDist = prompt.MaxActivationDistance
                pcall(function()
                    prompt.RequiresLineOfSight = false
                    prompt.MaxActivationDistance = math.huge
                end)
                
                -- Face the chest explicitly
                hrp.CFrame = CFrame.lookAt(hrp.Position, targetCFrame.Position)
                task.wait(0.15)
                
                pcall(function()
                    -- Trigger both methods just to be absolutely sure
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.15)
                    if fireproximityprompt then
                        pcall(fireproximityprompt, prompt)
                    end
                    prompt:InputHoldEnd()
                end)
                
                pcall(function()
                    prompt.RequiresLineOfSight = oldLOS
                    prompt.MaxActivationDistance = oldDist
                end)
                
                print("[" .. getgenv().CurrentPhase .. "] Successfully interacted with " .. targetType .. "!")
                
                -- Attempt to equip it if it's a priority item that went into our backpack
                if targetType == "Musashi" or targetType == "Rose Katana" or targetType == "SP Reset" then
                    task.wait(0.5) -- Give it time to enter backpack
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        for _, tool in ipairs(backpack:GetChildren()) do
                            if tool:IsA("Tool") then
                                local tName = string.lower(tool.Name)
                                if string.find(tName, "musashi") or string.find(tName, "rose") or string.find(tName, "sp reset") then
                                    tool.Parent = char
                                    print("[AutoKey] Auto-Equipped " .. tool.Name .. "!")
                                end
                            end
                        end
                    end
                end
                
                if getgenv().CurrentPhase == "1. Auto Key" and targetType == "Key" then
                    print("[AutoKey] Key collected! Switching to 2. Looting phase...")
                    getgenv().CurrentPhase = "2. Looting phase"
                elseif targetType == "Chest" then
                    task.wait(0.5) -- Wait a bit before flying to the next chest
                end
            end
            
            if bv then bv:Destroy() end
        end
    end
end

-- Toggles for auto loop
local getgenv = getgenv or function() return _G end
getgenv().AutoKey = true
getgenv().CurrentPhase = "1. Auto Key"

local function createStopButton()
    local coreGui = game:GetService("CoreGui")
    local oldGui = coreGui:FindFirstChild("AutoKeyStopGui")
    if oldGui then oldGui:Destroy() end
    
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local oldPgui = pGui:FindFirstChild("AutoKeyStopGui")
        if oldPgui then oldPgui:Destroy() end
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoKeyStopGui"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function() screenGui.Parent = coreGui end)
    if not success and pGui then screenGui.Parent = pGui end

    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 150, 0, 40)
    stopBtn.Position = UDim2.new(0.5, -75, 0, 20)
    stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    stopBtn.Text = "STOP LOOTING"
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 14
    stopBtn.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = stopBtn
    
    stopBtn.MouseButton1Click:Connect(function()
        getgenv().AutoKey = false
        print("[AutoKey] Stopped via UI button!")
        screenGui:Destroy()
        
        -- Reset character velocity just in case it was flying
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local bv = char.HumanoidRootPart:FindFirstChild("AntiGravity")
            if bv then bv:Destroy() end
            char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

createStopButton()

print("[AutoKey] Started: Phase 1 (Auto Key) -> Phase 2 (Looting)")

task.spawn(function()
    while getgenv().AutoKey and task.wait(1) do
        pcall(flyToAndInteract)
    end
end)
