-- Fetch the modules (Change these to your github raw links if loading from executor)
-- Fetch the modules using safe, public links
local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/View.lua"))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Clean up any previously running instance of this script
if typeof(getgenv().StopAutofarm) == "function" then
    pcall(getgenv().StopAutofarm)
end

local isRunning = true
local steppedConnection
local heartbeatConnection

local function cleanupAutoFarm()
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

    -- Attempt to clear the exploit teleport queue so it stops following you across servers
    local clear_queue = clear_teleport_queue or (syn and syn.clear_teleport_queue) or (fluxus and fluxus.clear_teleport_queue) or (queue_on_teleport and function() queue_on_teleport("") end)
    if clear_queue then
        pcall(clear_queue)
    end

    -- Destroy any existing UI instances
    local coreGui = CoreGui:FindFirstChild("AutoFarmGui")
    if coreGui then coreGui:Destroy() end
    local pGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild("AutoFarmGui") then 
        pGui.AutoFarmGui:Destroy() 
    end

    print("[Controller] Auto-Farm cleaned up, memory cleared, and UI destroyed.")
end

-- Assign to global so Joiner System's "Stop Autofarm / Halt" button can invoke this cleanup
getgenv().StopAutofarm = cleanupAutoFarm

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
end, cleanupAutoFarm)

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

-- 3. Background Quest Loop (Dynamic check)
task.spawn(function()
    while isRunning do
        task.wait(5)
        -- Only attempt to grab quest if we are actively farming, not already questing, and running
        if Model.State.isAutoFarming and not Model.State.isQuesting and isRunning then 
            local hasQuest = false
            pcall(function()
                local args = { [1] = "getNPCQuestLocations" }
                local questData = game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("Quest", 9e9):InvokeServer(unpack(args))
                
                -- If it returns an active quest table (not empty), or any truthy value other than an empty table
                if type(questData) == "table" and next(questData) ~= nil then
                    hasQuest = true
                elseif questData and type(questData) ~= "table" then
                    hasQuest = true
                end
            end)
            
            -- If the quest stops running (returns empty/nil), head back to Becky
            if not hasQuest then
                Model.GrabQuest()
            end
        end
    end
end)

-- 4. Background Auto-Stats Loop (Every 1 second)
task.spawn(function()
    while isRunning do
        task.wait(1)
        if Model.State.isAutoFarming and isRunning then 
            Model.UpgradeStats()
        end
    end
end)

