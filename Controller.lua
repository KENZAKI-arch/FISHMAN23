local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/View.lua"))()

local RunService = game:GetService("RunService")
local lastState = "OFF"

-- 1. Setup UI
local uiHandle = View.Build(function(isFarming)
    Model.State.isAutoFarming = isFarming

    if not isFarming then
        Model.ResetPhysics()
        Model.State.isReturningToZone = false
        uiHandle.UpdateUI("AUTO FARM: OFF", Color3.fromRGB(255, 85, 85))
        lastState = "OFF"
    else
        uiHandle.UpdateUI("AUTO FARM: ON", Color3.fromRGB(85, 255, 85))
        lastState = "FARMING"
        
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
        -- Ask the Model what it is currently doing
        local currentState = Model.UpdateTracking(deltaTime)
        
        -- If it changed from Farming to Returning (or vice versa), update the UI
        if currentState ~= lastState then
            lastState = currentState
            
            if currentState == "RETURNING" then
                uiHandle.UpdateUI("OUT OF BOUNDS: RETURNING", Color3.fromRGB(255, 170, 0))
            elseif currentState == "FARMING" then
                uiHandle.UpdateUI("AUTO FARM: ON", Color3.fromRGB(85, 255, 85))
            end
        end
    end
end)

-- 3. Background Quest Loop
task.spawn(function()
    while true do
        task.wait(50)
        -- Only attempt to grab quest if we are farming AND NOT currently out of bounds
        if Model.State.isAutoFarming and not Model.State.isReturningToZone then 
            Model.GrabQuest()
        end
    end
end)