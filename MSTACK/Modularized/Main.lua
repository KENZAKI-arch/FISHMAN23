-- Main Loader Orchestrator
print("[Fishman] Loading Modular Architecture...")

-- 🔄 Generation counter to cleanly terminate any zombie threads from previous executions
getgenv().FishmanSession = (getgenv().FishmanSession or 0) + 1

local repoURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Modularized/"

local modules = {
    "Config.lua",
    "TeleportEngine.lua",
    "FishingEngine.lua",
    "UI.lua"
}

-- ⚡ CONCURRENT DOWNLOADS (with automatic retry on network hiccup)
local scriptCache = {}
local threads = {}

for _, mod in ipairs(modules) do
    table.insert(threads, task.spawn(function()
        for attempt = 1, 3 do
            local success, result = pcall(function()
                return game:HttpGet(repoURL .. mod .. "?t=" .. tostring(tick()))
            end)
            if success and type(result) == "string" and #result > 0 then
                scriptCache[mod] = result
                return
            end
            warn(string.format("[Fishman] Download attempt %d/3 failed for %s: %s", attempt, mod, tostring(result)))
            if attempt < 3 then task.wait(0.5) end
        end
    end))
end

-- Wait for all downloads to finish
local waitStart = tick()
while (tick() - waitStart < 10) do
    local allDone = true
    for _, mod in ipairs(modules) do
        if not scriptCache[mod] then
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

-- 🧹 Free raw source strings from memory
table.clear(scriptCache)
table.clear(threads)

print("[Fishman] All required modules loaded successfully!")

