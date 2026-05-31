-- ========================================== --
-- DUPLICATE GUARD
-- ========================================== --
if getgenv().FishmanAutoFarmRunning then 
    warn("Script is already running! Preventing duplicate.")
    return 
end
getgenv().FishmanAutoFarmRunning = true

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for LocalPlayer to exist
repeat task.wait() until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

local targetPlaceId = 1730877806

-- ========================================== --
--(PLAYER PS CODE)
-- ========================================== --
local myPSCode = "qj1ttW4JG1"
    
-- ========================================== --
-- THE INFINITE LOOP (AUTO-LOAD)
-- ========================================== --
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Untitled-1.lua"
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
            
            -- Clear the flag BEFORE teleporting
            getgenv().FishmanAutoFarmRunning = false
            
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
    
    -- PATH A: We are in the public lobby.
    if myPSCode then
        print("[Logic] Code found for " .. LocalPlayer.Name .. "! Joining Private Server in 5 seconds...")
        task.wait(7)
        
        task.spawn(function()
            local codeArgs = { [1] = myPSCode }
            local events = ReplicatedStorage:WaitForChild("Events", 9e9)
            local reserved = events:WaitForChild("reserved", 9e9)
            reserved:InvokeServer(unpack(codeArgs))
        end)
        
        task.wait(4)
        
        -- Clear the flag BEFORE teleporting to PS
        getgenv().FishmanAutoFarmRunning = false
        
        -- YOUR NEW CHANGE IS HERE
        local confirmArgs = { [1] = "fishHub" }
        
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 9e9)
        local chooseType = playerGui:WaitForChild("chooseType", 9e9)
        local frame = chooseType:WaitForChild("Frame", 9e9)
        local remoteEvent = frame:WaitForChild("RemoteEvent", 9e9)
        
        remoteEvent:FireServer(unpack(confirmArgs))
        print("[Logic] Sequence complete. Teleporting...")
    else
        print("[Logic] No Private Server code assigned for " .. LocalPlayer.Name .. ". Staying in public server.")
    end

else
    
    -- PATH B: We are in the Private Server.
    print("[Logic] In Private Server. Loading scripts...")
    
    -- 1. Execute your first script (Auto-Farm)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/AF2/refs/heads/main/Controller.lua"))()
    
    -- 2. Wait 2 seconds so the first script can load properly
    task.wait(2)
    
    -- 3. Execute your second script (Joiner System)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/joinersystem.lua"))()
    
end