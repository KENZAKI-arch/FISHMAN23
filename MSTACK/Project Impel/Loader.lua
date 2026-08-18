-- ==========================================
-- PROJECT IMPEL LOADER
-- ==========================================
local TARGET_STAGE = 1

pcall(function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    
    -- Robust Detection: Check if the character is physically near the Floor 2 Spawn area
    local islands = workspace:FindFirstChild("Islands")
    if islands then
        local f2 = islands:FindFirstChild("Impel Base - Floor 2")
        if f2 then
            local base = f2:FindFirstChild("Base")
            local spawnFloor = base and base:FindFirstChild("SpawnFloor")
            local spawnPart = spawnFloor and spawnFloor:FindFirstChild("Part") or spawnFloor
            
            if spawnPart and spawnPart:IsA("BasePart") then
                if (root.Position - spawnPart.Position).Magnitude < 500 then
                    TARGET_STAGE = 2
                end
            elseif spawnPart and spawnPart:IsA("Model") and spawnPart.PrimaryPart then
                if (root.Position - spawnPart.PrimaryPart.Position).Magnitude < 500 then
                    TARGET_STAGE = 2
                end
            end
        end
    end
    
    -- Fallback: If we are high up in the air (Floor 2 altitude), force Stage 2
    -- This prevents the Loader from accidentally loading Stage 1 if you execute it mid-way through Floor 2!
    if root.Position.Y > 2200 then
        TARGET_STAGE = 2
    end
end)

print("[Impel Loader] Auto-detected Stage " .. TARGET_STAGE .. "...")

if TARGET_STAGE == 1 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/Stage1.lua"))()
elseif TARGET_STAGE == 2 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/Stage2.lua"))()
elseif TARGET_STAGE == 3 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/Stage3.lua"))()
else
    warn("Invalid Stage Selected!")
    return
end

-- Load the Core Engine after the stage configuration is set
loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/CoreAutofarm.lua"))()

print("[Impel Loader] Core Autofarm Engine successfully loaded!")
