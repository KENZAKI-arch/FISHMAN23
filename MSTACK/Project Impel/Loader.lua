-- ==========================================
-- PROJECT IMPEL LOADER
-- ==========================================

-- Clean up any existing stage script or autofarm running
if getgenv().StopAutofarm then
    pcall(function() getgenv().StopAutofarm() end)
    task.wait(0.2)
end

getgenv().CURRENT_STAGE = nil
getgenv().MACRO_WAYPOINTS = nil
getgenv().AUTO_START_ON_LOAD = true

local TARGET_STAGE = 1

pcall(function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    
    -- Stage 3 Detection: Check proximity to Stage 3 Spawn or coordinates
    local stage3Spawn = Vector3.new(4960, 2308, -20604)
    if (root.Position - stage3Spawn).Magnitude < 800 or (root.Position.X > 4200 and root.Position.Z < -20000) then
        TARGET_STAGE = 3
        return
    end

    -- Stage 2 Detection: Check if the character is near the Floor 2 area or coordinates
    local islands = workspace:FindFirstChild("Islands")
    if islands then
        local f2 = islands:FindFirstChild("Impel Base - Floor 2")
        if f2 then
            local base = f2:FindFirstChild("Base")
            local spawnFloor = base and base:FindFirstChild("SpawnFloor")
            local spawnPart = spawnFloor and (spawnFloor:FindFirstChild("Part") or spawnFloor)
            
            if spawnPart and spawnPart:IsA("BasePart") then
                if (root.Position - spawnPart.Position).Magnitude < 800 then
                    TARGET_STAGE = 2
                    return
                end
            elseif spawnPart and spawnPart:IsA("Model") and spawnPart.PrimaryPart then
                if (root.Position - spawnPart.PrimaryPart.Position).Magnitude < 800 then
                    TARGET_STAGE = 2
                    return
                end
            end
        end
    end
    
    -- Coordinate Detection: F2 and F3 are far along Z and at higher elevation
    if root.Position.Z < -18000 or root.Position.Y > 2200 then
        if root.Position.X > 4200 then
            TARGET_STAGE = 3 -- Stage 3 is further along X axis
        else
            TARGET_STAGE = 2 -- Stage 2 is around X=3100-3400
        end
    end
end)

local function safeLoad(url, name)
    local success, content = pcall(function() return game:HttpGet(url) end)
    if not success or not content then
        warn("[Impel Loader] Failed to download " .. name .. ": " .. tostring(content))
        return false
    end
    local fn, err = loadstring(content)
    if not fn then
        warn("[Impel Loader] Syntax error in " .. name .. ": " .. tostring(err))
        return false
    end
    local runSuccess, runErr = pcall(fn)
    if not runSuccess then
        warn("[Impel Loader] Runtime error in " .. name .. ": " .. tostring(runErr))
        return false
    end
    return true
end

print("[Impel Loader] Auto-detected Stage " .. TARGET_STAGE .. "...")

local stageUrl
if TARGET_STAGE == 1 then
    stageUrl = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/Stage1.lua"
elseif TARGET_STAGE == 2 then
    stageUrl = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/Stage2.lua"
elseif TARGET_STAGE == 3 then
    stageUrl = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/Stage3.lua"
else
    warn("Invalid Stage Selected!")
    return
end

if not safeLoad(stageUrl, "Stage " .. tostring(TARGET_STAGE)) then
    return
end

-- Load the Core Engine after the stage configuration is set
local coreUrl = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Project%20Impel/CoreAutofarm.lua"
if safeLoad(coreUrl, "CoreAutofarm") then
    print("[Impel Loader] Core Autofarm Engine successfully loaded for Stage " .. tostring(TARGET_STAGE) .. "!")
end
