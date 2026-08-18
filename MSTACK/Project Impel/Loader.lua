-- ==========================================
-- PROJECT IMPEL LOADER
-- ==========================================
local TARGET_STAGE = 1

pcall(function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    
    -- Floor 2 is located much higher in the world
    if root.Position.Y > 2300 then
        TARGET_STAGE = 2
    end
end)

print("[Impel Loader] Auto-detected Stage " .. TARGET_STAGE .. "...")

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
