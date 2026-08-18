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
    
    -- Stage 3 Detection: Check proximity to Stage 3 Spawn
    local stage3Spawn = Vector3.new(4960, 2308, -20604)
    if (root.Position - stage3Spawn).Magnitude < 500 then
        TARGET_STAGE = 3
    end
    
    -- Fallback: If we execute mid-way through a stage, use coordinates to detect!
    if TARGET_STAGE == 1 and root.Position.Y > 2200 then
        if root.Position.X > 4000 then
            TARGET_STAGE = 3 -- Stage 3 is far along the X axis
        else
            TARGET_STAGE = 2 -- Stage 2 is around X=3000
        end
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
