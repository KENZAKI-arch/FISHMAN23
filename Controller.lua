local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/View.lua"))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Setup UI and handle the toggle button
View.Build(function(isFarming)
    Model.State.isAutoFarming = isFarming

    if not isFarming then
        _G.CancelAutoTravel = true 
        Model.ResetPhysics()
        Model.State.isRecovering = false 
        Model.State.isQuesting = false
    else
        _G.CancelAutoTravel = false 
        
        -- Start Combat Loop
        task.spawn(function()
            while Model.State.isAutoFarming do
                if Model.State.isRecovering or Model.State.isQuesting then
                    task.wait(0.5) 
                else
                    Model.DoCombatCombo()
                end
            end
        end)

        -- Start Auto Stats Loop
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

-- 2. Hook into Roblox Engine Loops
local steppedConn = RunService.Stepped:Connect(function()
    if Model.State.isAutoFarming and not Model.State.isRecovering and not Model.State.isQuesting then
        Model.ApplyNoclip()
    end
end)

local heartbeatConn = RunService.Heartbeat:Connect(function(deltaTime)
    if not Model.State.isAutoFarming then return end

    local char = Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local fishmanIsland = Workspace:FindFirstChild("Islands") and Workspace.Islands:FindFirstChild("Fishman Island")

    if root and fishmanIsland then
        local islandCFrame, islandSize = fishmanIsland:GetBoundingBox()
        local relativePos = islandCFrame:PointToObjectSpace(root.Position)
        local halfSize = islandSize / 2

        -- Check if outside the island boundary
        local isOutsideBox = math.abs(relativePos.X) > halfSize.X or 
                             math.abs(relativePos.Y) > halfSize.Y or 
                             math.abs(relativePos.Z) > halfSize.Z

        if isOutsideBox and not Model.State.isRecovering then
            Model.State.isRecovering = true 
            Model.ResetPhysics() 
            
            task.spawn(function()
                -- 1. Trigger Teleport Script
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/auttotpisland.lua"))()
                end)
                
                -- 2. FOOLPROOF ARRIVAL CHECK: Wait until you reach the exact coordinates
                local targetLandingPos = Vector3.new(7976.704, -2152.832, -17074.277)
                
                while Model.State.isRecovering and Model.State.isAutoFarming do
                    task.wait(1)
                    local currentRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if currentRoot then
                        -- Measure the distance to the target spot
                        local distance = (currentRoot.Position - targetLandingPos).Magnitude
                        if distance < 15 then
                            break -- We are within 15 studs of the target! Stop waiting!
                        end
                    end
                end
                
                -- 3. We arrived! Wait 10 seconds for the NPC save to finish, then resume farming
                if Model.State.isAutoFarming then
                    task.wait(10)
                    Model.State.isRecovering = false 
                end
            end)
        end
    end

    if not Model.State.isRecovering and not Model.State.isQuesting then
        Model.UpdateTracking(deltaTime)
    end
end)

-- 3. Background Quest Loop
local questLoopActive = true
task.spawn(function()
    while questLoopActive do
        task.wait(50)
        if Model.State.isAutoFarming and not Model.State.isRecovering and not Model.State.isQuesting then 
            Model.GrabQuest()
        end
    end
end)

-- 4. Global Stop Hook
getgenv().StopAutofarm = function()
    -- Stop all state loops
    Model.State.isAutoFarming = false
    Model.State.isRecovering = false
    Model.State.isQuesting = false
    questLoopActive = false
    _G.CancelAutoTravel = true
    
    Model.ResetPhysics()
    
    -- Disconnect engine hooks
    if steppedConn then steppedConn:Disconnect() end
    if heartbeatConn then heartbeatConn:Disconnect() end
    
    -- Destroy the Autofarm UI
    local coreGui = game:GetService("CoreGui"):FindFirstChild("AutoFarmGui")
    if coreGui then coreGui:Destroy() end
    
    local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild("AutoFarmGui") then 
        pGui.AutoFarmGui:Destroy() 
    end
    
    print("[Controller] Autofarm forcefully stopped and UI destroyed.")
end