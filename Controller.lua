-- Fetch the modules (Change these to your github raw links if loading from executor)
-- Fetch the modules using safe, public links
local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/View.lua"))()

local RunService = game:GetService("RunService")

local isRunning = true
local steppedConnection
local heartbeatConnection

-- 1. Setup UI and handle the toggle button
View.Build(function(isFarming)
    Model.State.isAutoFarming = isFarming

    if not isFarming then
        Model.ResetPhysics()
    else
        -- Start Combat Loop
        task.spawn(function()
            while Model.State.isAutoFarming and isRunning do
                Model.DoCombatCombo()
            end
        end)
    end
end, function() -- onCloseCallback (Clean up)
    isRunning = false
    Model.State.isAutoFarming = false
    Model.State.isQuesting = false
    Model.State.isRecovering = false
    Model.ResetPhysics()

    if steppedConnection then
        steppedConnection:Disconnect()
        steppedConnection = nil
    end
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end

    if getgenv().FishmanAutoFarmRunning ~= nil then
        getgenv().FishmanAutoFarmRunning = false
    end
    print("[Controller] Auto-Farm cleaned up and terminated.")
end)

-- 2. Hook into Roblox Engine Loops
steppedConnection = RunService.Stepped:Connect(function()
    if Model.State.isAutoFarming and isRunning then
        Model.ApplyNoclip()
    end
end)

heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
    if Model.State.isAutoFarming and isRunning then
        Model.UpdateTracking(deltaTime)
    end
end)

-- 3. Background Quest Loop
task.spawn(function()
    while isRunning do
        task.wait(50)
        -- Only attempt to grab quest if we are actively farming and running
        if Model.State.isAutoFarming and isRunning then 
            Model.GrabQuest()
        end
    end
end)
