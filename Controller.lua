local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/View.lua"))()

local RunService = game:GetService("RunService")
local lastState = "OFF"

local uiHandle = View.Build(function(isFarming)
    Model.State.isAutoFarming = isFarming

    if not isFarming then
        Model.ResetPhysics()
        uiHandle.UpdateUI("AUTO FARM: OFF", Color3.fromRGB(255, 85, 85))
        lastState = "OFF"
    else
        uiHandle.UpdateUI("AUTO FARM: ON", Color3.fromRGB(85, 255, 85))
        lastState = "FARMING"
        
        task.spawn(function()
            while Model.State.isAutoFarming do
                Model.DoCombatCombo()
            end
        end)
    end
end)

RunService.Stepped:Connect(function()
    if Model.State.isAutoFarming then
        Model.ApplyNoclip()
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if Model.State.isAutoFarming then
        local currentState = Model.UpdateTracking(deltaTime)
        
        if currentState ~= lastState then
            lastState = currentState
            
            if currentState == "RETURNING" then
                uiHandle.UpdateUI("OUT OF BOUNDS: RETURNING", Color3.fromRGB(255, 170, 0))
            elseif currentState == "FARMING" then
                uiHandle.UpdateUI("AUTO FARM: ON", Color3.fromRGB(85, 255, 85))
            elseif currentState == "WAITING" then
                uiHandle.UpdateUI("WAITING / STUNNED", Color3.fromRGB(150, 150, 150))
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(50)
        -- Grab quest whenever it is turned on
        if Model.State.isAutoFarming then 
            Model.GrabQuest()
        end
    end
end)