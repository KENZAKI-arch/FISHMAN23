local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local targetPlaceId = 1730877806

-- ========================================== --
-- THE VIP LIST (PLAYER PS CODES)
-- ========================================== --
-- Add the exact usernames on the left, and their PS codes on the right.
local playerCodes = {
    ["YourExactUsername"] = "qj1ttW4JG1",
    ["PlayerName2"]       = "AbCdEfGh12",
    ["PlayerName3"]       = "XyZ1234567"
}

-- Look up the code for whoever is currently running the script
local myPSCode = playerCodes[LocalPlayer.Name]

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
    
    -- PATH A: We are in the public lobby.
    -- First, check if this specific player has a PS code assigned to them!
    if myPSCode then
        print("[Logic] Code found for " .. LocalPlayer.Name .. "! Joining Private Server in 5 seconds...")
        task.wait(5)
        
        task.spawn(function()
            -- We inject their specific code here instead of the hardcoded one
            local codeArgs = { [1] = myPSCode }
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
        -- If they are NOT on the VIP list, the script just ignores the teleport.
        print("[Logic] No Private Server code assigned for " .. LocalPlayer.Name .. ". Staying in public server.")
    end

else
    
    -- PATH B: We are in the Private Server.
    print("[Logic] In Private Server. Loading Auto-Farm...")
    
    -- Load the Controller script to start the auto-farm!
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Controller.lua"))()
    
end