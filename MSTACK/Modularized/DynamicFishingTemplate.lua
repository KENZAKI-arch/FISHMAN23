-- ======================================================================
-- 🎣 DYNAMIC FISHING ENGINE (BLANK CANVAS)
-- Purpose: Safely intercept dynamic SessionKeys/ActionKeys and automate fishing
-- ======================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local FishingEngine = {
    State = {
        IsFishing = false,
        CurrentSessionKey = nil,
        CurrentActionKey = nil,
        Connections = {}
    }
}

-- ======================================================================
-- 🛑 1. INTERCEPTING KEYS (The Bypass)
-- ======================================================================
-- There are two main ways games handle dynamic keys. You will need to 
-- uncomment the one that matches how your specific game works.

-- METHOD A: The server sends the keys to the client via a RemoteEvent
-- when a fish bites.
local function StartRemoteListener()
    -- Example path to the remote: ReplicatedStorage.Fishing.Remotes.BiteEvent
    local biteEvent = ReplicatedStorage:WaitForChild("Fishing"):WaitForChild("Remotes"):WaitForChild("BiteEvent")
    
    local conn = biteEvent.OnClientEvent:Connect(function(data)
        -- 'data' is whatever the server sent. It might be a table containing the keys.
        if type(data) == "table" and data.SessionKey then
            print("[FishingEngine] Intercepted keys from server!")
            FishingEngine.State.CurrentSessionKey = data.SessionKey
            FishingEngine.State.CurrentActionKey = data.ActionKey
            
            -- Now that we have the keys, we can automate the Reel!
            task.spawn(function()
                task.wait(math.random(0.2, 0.6)) -- Human-like delay
                FishingEngine.ReelFish()
            end)
        end
    end)
    table.insert(FishingEngine.State.Connections, conn)
end


-- METHOD B: The game's local script generates or holds the keys, and we 
-- need to intercept them right before the game tries to use them (Namecall Hook).
local function StartNamecallHook()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- If the game is trying to InvokeServer on the "Action" remote...
        if not checkcaller() and method == "InvokeServer" and self.Name == "Action" then
            -- Check if the arguments contain our fishing keys
            if type(args[1]) == "table" and args[1].Action == "Reel" then
                print("[FishingEngine] Intercepted keys via Namecall Hook!")
                
                -- We can steal the keys here just in case we need them
                FishingEngine.State.CurrentSessionKey = args[1].SessionKey
                FishingEngine.State.CurrentActionKey = args[1].ActionKey
            end
        end
        
        return oldNamecall(self, unpack(args))
    end)
end

-- ======================================================================
-- 🎣 2. AUTOMATION ACTIONS
-- ======================================================================

function FishingEngine.CastRod()
    if FishingEngine.State.IsFishing then return end
    print("[FishingEngine] Casting Rod...")
    
    -- NOTE: Add your rod casting logic here (e.g. firing the cast remote)
    -- local args = { [1] = { ["Action"] = "Cast", ... } }
    -- ReplicatedStorage.Fishing.Remotes.Action:InvokeServer(unpack(args))
    
    FishingEngine.State.IsFishing = true
end

function FishingEngine.ReelFish()
    if not FishingEngine.State.CurrentSessionKey then 
        warn("[FishingEngine] Cannot reel! We don't have a valid SessionKey yet.")
        return 
    end
    
    print("[FishingEngine] Reeling in fish with dynamic keys!")
    
    local args = {
        [1] = {
            ["ActionKey"] = FishingEngine.State.CurrentActionKey,
            ["Action"] = "Reel",
            ["SessionKey"] = FishingEngine.State.CurrentSessionKey,
        }
    }
    
    -- Execute the reel remote with our fresh keys
    local actionRemote = ReplicatedStorage:WaitForChild("Fishing"):WaitForChild("Remotes"):WaitForChild("Action")
    local success, result = pcall(function()
        return actionRemote:InvokeServer(unpack(args))
    end)
    
    if success then
        print("[FishingEngine] Successfully reeled! Result:", result)
        -- Reset state for the next cast
        FishingEngine.State.CurrentSessionKey = nil
        FishingEngine.State.CurrentActionKey = nil
        FishingEngine.State.IsFishing = false
        
        -- Auto recast after a short delay
        task.delay(1, FishingEngine.CastRod)
    else
        warn("[FishingEngine] Reel failed:", result)
    end
end

-- ======================================================================
-- 🚀 3. INITIALIZATION
-- ======================================================================

function FishingEngine.Start()
    print("[FishingEngine] Starting Dynamic Fishing Engine...")
    
    -- Initialize the interceptor (Choose A or B based on your game)
    -- StartRemoteListener() 
    -- StartNamecallHook()
    
    -- Start the first cast
    FishingEngine.CastRod()
end

function FishingEngine.Stop()
    print("[FishingEngine] Stopping...")
    for _, conn in ipairs(FishingEngine.State.Connections) do
        conn:Disconnect()
    end
    table.clear(FishingEngine.State.Connections)
    FishingEngine.State.IsFishing = false
end

-- Return the engine so Main.lua can require/use it
return FishingEngine
