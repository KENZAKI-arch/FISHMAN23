-- Main Loader Orchestrator
print("[Fishman] Loading Modular Architecture...")
local repoURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Modularized/"

local modules = {
    "Config.lua",
    "TeleportEngine.lua",
    "FishingEngine.lua",
    "UI.lua"
}

-- 🚀 LOBBY OPTIMIZATIONS 
local isLobby = (game.PlaceId == 1730877806)
if isLobby then
    print("[Fishman] In Lobby: Activating Ultra-Low Resource Mode (FPS Cap & 3D Off)")
    pcall(function() setfpscap(10) end)
    pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(false) end)
    
    getgenv().FishmanState = getgenv().FishmanState or {}
    getgenv().FishmanState.Model = { State = {} }
end

-- ⚡ CONCURRENT DOWNLOADS
local scriptCache = {}
local threads = {}

for _, mod in ipairs(modules) do
    if isLobby and mod == "FishingEngine.lua" then
        print("[Fishman] In Lobby: Skipping FishingEngine.lua to save RAM.")
        continue
    end
    
    table.insert(threads, task.spawn(function()
        local success, result = pcall(function()
            return game:HttpGet(repoURL .. mod .. "?t=" .. tostring(tick()))
        end)
        if success then
            scriptCache[mod] = result
        else
            warn("[Fishman] Failed to download " .. mod .. ": " .. tostring(result))
        end
    end))
end

-- Wait for all downloads to finish
local waitStart = tick()
while (tick() - waitStart < 10) do
    local allDone = true
    for _, mod in ipairs(modules) do
        if not (isLobby and mod == "FishingEngine.lua") and not scriptCache[mod] then
            allDone = false
            break
        end
    end
    if allDone then break end
    task.wait(0.1)
end

-- 📦 SEQUENTIAL EXECUTION (Order matters!)
for _, mod in ipairs(modules) do
    if scriptCache[mod] then
        local success, err = pcall(function()
            loadstring(scriptCache[mod])()
        end)
        if not success then
            warn("[Fishman] Failed to execute module " .. mod .. ": " .. tostring(err))
        end
    end
end

print("[Fishman] All required modules loaded successfully!")
