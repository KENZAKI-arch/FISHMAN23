local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/View.lua"))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local isCheckingBounds = false

-- 1. Setup UI and handle the toggle button
View.Build(function(isFarming)
    Model.State.isAutoFarming = isFarming

    if not isFarming then
        Model.ResetPhysics()
        Model.State.isRecovering = false -- Reset recovery if they turn it off manually
    else
        -- Start Combat Loop
        task.spawn(function()
            while Model.State.isAutoFarming do
                -- If recovering, don't swing! Just wait.
                if Model.State.isRecovering then
                    task.wait(1) 
                else
                    Model.DoCombatCombo()
                end
            end
        end)
    end
end)

-- 2. Hook into Roblox Engine Loops
RunService.Stepped:Connect(function()
    -- Only Noclip if we are NOT recovering
    if Model.State.isAutoFarming and not Model.State.isRecovering then
        Model.ApplyNoclip()
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if not Model.State.isAutoFarming then return end

    -- THE SEPARATE HOOK: Check if out of bounds
    if not Model.State.isRecovering then
        local char = Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local fishmanIsland = Workspace:FindFirstChild("Islands") and Workspace.Islands:FindFirstChild("Fishman Island")

        if root and fishmanIsland and not isCheckingBounds then
            isCheckingBounds = true
            local islandCFrame, islandSize = fishmanIsland:GetBoundingBox()
            local relativePos = islandCFrame:PointToObjectSpace(root.Position)
            local halfSize = islandSize / 2

            local isOutsideBox = math.abs(relativePos.X) > halfSize.X or 
                                 math.abs(relativePos.Y) > halfSize.Y or 
                                 math.abs(relativePos.Z) > halfSize.Z

            if isOutsideBox then
                -- TRIGGER RECOVERY MODE
                Model.State.isRecovering = true
                Model.ResetPhysics() -- Stop the autofarm from fighting gravity
                
                task.spawn(function()
                    -- 1. Execute your external teleport script
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/auttotpisland.lua"))()
                    end)
                    
                    -- 2. Wait until player is safely back inside the island box
                    while Model.State.isRecovering and Model.State.isAutoFarming do
                        task.wait(1)
                        local currentRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if currentRoot then
                            local relPos = islandCFrame:PointToObjectSpace(currentRoot.Position)
                            if math.abs(relPos.X) <= halfSize.X and math.abs(relPos.Y) <= halfSize.Y and math.abs(relPos.Z) <= halfSize.Z then
                                break -- We Arrived!
                            end
                        end
                    end
                    
                    -- 3. 10 Second Task Delay before resuming AutoFarm
                    if Model.State.isAutoFarming then
                        task.wait(10)
                        Model.State.isRecovering = false -- Flips switch to resume!
                    end
                    isCheckingBounds = false
                end)
                return
            end
            isCheckingBounds = false
        end
    end

    -- Normal AutoFarm Tracking (Only runs if NOT recovering)
    if not Model.State.isRecovering then
        Model.UpdateTracking(deltaTime)
    end
end)

-- 3. Background Quest Loop
task.spawn(function()
    while true do
        task.wait(50)
        -- Only attempt to grab quest if we are actively farming and safely on the island
        if Model.State.isAutoFarming and not Model.State.isRecovering then 
            Model.GrabQuest()
        end
    end
end)