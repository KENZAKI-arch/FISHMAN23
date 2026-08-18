-- ==========================================
-- PROJECT IMPEL LOADER
-- ==========================================
-- Set this to 1 for Maze, or 2 for Lever/Boss Room
local TARGET_STAGE = 1

print("[Impel Loader] Starting Stage " .. TARGET_STAGE .. "...")

if TARGET_STAGE == 1 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/Stage1.lua"))()
elseif TARGET_STAGE == 2 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/Stage2.lua"))()
else
    warn("Invalid Stage Selected!")
    return
end

-- Load the Core Engine after the stage configuration is set
loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/CoreAutofarm.lua"))()

print("[Impel Loader] Core Autofarm Engine successfully loaded!")
