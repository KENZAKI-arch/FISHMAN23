-- Main Loader Orchestrator
print("[Fishman] Loading Modular Architecture...")
local repoURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Modularized/"

local modules = {
    "Config.lua",
    "TeleportEngine.lua",
    "FishingEngine.lua",
    "UI.lua"
}

for _, mod in ipairs(modules) do
    local success, err = pcall(function()
        loadstring(game:HttpGet(repoURL .. mod))()
    end)
    if not success then
        warn("[Fishman] Failed to load module " .. mod .. ": " .. tostring(err))
    end
end
print("[Fishman] All modules loaded successfully!")
