if getgenv().FishmanAutoFarmRunning then 
    warn("Script is already running! Preventing duplicate.")
    return 
end
getgenv().FishmanAutoFarmRunning = true




local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local targetPlaceId = 1730877806

-- ========================================== --
-- THE INFINITE LOOP (AUTO-LOAD)
-- ========================================== --
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/CombinedAutoLoad.lua"
local loadCommand = "loadstring(game:HttpGet('" .. myScriptURL .. "'))()"

if queue_on_teleport then
    queue_on_teleport(loadCommand) 
    print("[Loader] Locked and loaded for the next teleport!")
end

-- ========================================== --
-- DISCONNECT WATCHER (Runs all the time)
-- ========================================== --
task.spawn(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
    
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            print("[Watcher] Disconnected! Auto-rejoining in 5 seconds...")
            task.wait(5) 
            
            pcall(function()
                TeleportService:Teleport(targetPlaceId, LocalPlayer)
            end)
        end
    end)
end)

-- ========================================== --
-- THE FORK IN THE ROAD (Routing)
-- ========================================== --
if game.PlaceId == targetPlaceId and game.PrivateServerId == "" then
    
    -- PATH A: We are in the public lobby. Join the Private Server!
    print("[Logic] In Public Target Place. Joining Private Server in 5 seconds...")
    task.wait(10)
    
    task.spawn(function()
        local codeArgs = { [1] = "qj1ttW4JG1" }
        local events = ReplicatedStorage:WaitForChild("Events", 9e9)
        local reserved = events:WaitForChild("reserved", 9e9)
        reserved:InvokeServer(unpack(codeArgs))
    end)
    
    task.wait(1)
    
    local confirmArgs = { [1] = "true" }
    
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 9e9)
    local chooseType = playerGui:WaitForChild("chooseType", 9e9)
    local frame = chooseType:WaitForChild("Frame", 9e9)
    local remoteEvent = frame:WaitForChild("RemoteEvent", 9e9)
    
    remoteEvent:FireServer(unpack(confirmArgs))
    print("[Logic] Sequence complete. Teleporting...")

else
    
    -- PATH B: We are in the Private Server.
    print("[Logic] In Private Server. Loading Auto-Farm...")

    task.wait(30)
    
    -- Load the Controller script here!
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Controller.lua"))()
    
end