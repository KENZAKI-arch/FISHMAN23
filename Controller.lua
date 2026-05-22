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
        -- *** TRIGGER THE KILL SWITCH ***
        _G.CancelAutoTravel = true 
        
        Model.ResetPhysics()
        Model.State.isRecovering = false 
        Model.State.isQuesting = false
    else
        -- *** RESET THE KILL SWITCH ***
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
                task.wait(0.1) 
            end
        end)
    end
end)

-- 2. Hook into Roblox Engine Loops
RunService.Stepped:Connect(function()
    if Model.State.isAutoFarming and not Model.State.isRecovering and not Model.State.isQuesting then
        Model.ApplyNoclip()
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if not Model.State.isAutoFarming then return end

    local char = Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local fishmanIsland = Workspace:FindFirstChild("Islands") and Workspace.Islands:FindFirstChild("Fishman Island")

    if root and fishmanIsland then
        local islandCFrame, islandSize = fishmanIsland:GetBoundingBox()
        local relativePos = islandCFrame:PointToObjectSpace(root.Position)
        local halfSize = islandSize / 2

        local isOutsideBox = math.abs(relativePos.X) > halfSize.X or 
                             math.abs(relativePos.Y) > halfSize.Y or 
                             math.abs(relativePos.Z) > halfSize.Z

        if isOutsideBox and not Model.State.isRecovering then
            Model.State.isRecovering = true 
            Model.ResetPhysics() 
            
            task.spawn(function()
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/auttotpisland.lua"))()
                end)
                
                while Model.State.isRecovering and Model.State.isAutoFarming do
                    task.wait(1)
                    local currentRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if currentRoot then
                        local relPos = islandCFrame:PointToObjectSpace(currentRoot.Position)
                        if math.abs(relPos.X) <= halfSize.X and math.abs(relPos.Y) <= halfSize.Y and math.abs(relPos.Z) <= halfSize.Z then
                            break 
                        end
                    end
                end
                
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
task.spawn(function()
    while true do
        task.wait(50)
        if Model.State.isAutoFarming and not Model.State.isRecovering and not Model.State.isQuesting then 
            Model.GrabQuest()
        end
    end
end)