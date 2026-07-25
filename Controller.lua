-- Fetch the modules (Change these to your github raw links if loading from executor)
-- Fetch the modules using safe, public links
local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/View.lua"))()

local RunService = game:GetService("RunService")

-- 1. Setup UI and handle the toggle button
View.Build(function(isFarming)
    Model.State.isAutoFarming = isFarming

    if not isFarming then
        Model.ResetPhysics()
    else
        -- Start Combat Loop
        task.spawn(function()
            while Model.State.isAutoFarming do
                Model.DoCombatCombo()
            end
        end)
    end
end)

-- 2. Hook into Roblox Engine Loops
RunService.Stepped:Connect(function()
    if Model.State.isAutoFarming then
        Model.ApplyNoclip()
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if Model.State.isAutoFarming then
        Model.UpdateTracking(deltaTime)
    end
end)

-- 3. Background Quest Loop
task.spawn(function()
    while true do
        task.wait(50)
        -- Only attempt to grab quest if we are actively farming
        if Model.State.isAutoFarming then 
            Model.GrabQuest()
        end
    end
end)
