-- ======================================================================
-- CraftAllLegends.lua
-- Standalone macro to craft ALL Legendary Fish in your inventory into Baits.
-- ======================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Wait for character
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Dependencies
local questEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Quest", 9e9)
local craftingRemote = ReplicatedStorage:WaitForChild("CraftingRemote", 9e9)
local statsFolder = ReplicatedStorage:WaitForChild("Stats" .. LocalPlayer.Name, 9e9)
local inventoryObj = statsFolder:WaitForChild("Inventory", 9e9):WaitForChild("Inventory", 9e9)

local LEGENDARY_FISHES = { "Anglerfish", "Golden Ribbon Angelfish", "Golden Polka Puffer", "Golden Tigerfin" }

print("[CraftAllLegends] Reading inventory...")
local ok, inventoryData = pcall(function() return HttpService:JSONDecode(inventoryObj.Value) end)
if not ok or not inventoryData then
    warn("[CraftAllLegends] Failed to parse inventory!")
    return
end

local craftQueue = {}
for _, fishName in ipairs(LEGENDARY_FISHES) do
    local amount = inventoryData[fishName] or 0
    if amount > 0 then
        table.insert(craftQueue, { Name = fishName, Batches = amount })
    end
end

if #craftQueue == 0 then
    warn("[CraftAllLegends] You have 0 Legendary Fishes in your inventory.")
    return
end

print("[CraftAllLegends] Found legendary fishes! Starting autonomous sequence...")
local originalPos = hrp.Position
local targetPos = Vector3.new(162.85, originalPos.Y, -55.34)

local function FlyTo(target)
    local bv = hrp:FindFirstChild("CraftGravity") or Instance.new("BodyVelocity")
    bv.Name = "CraftGravity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not hrp then conn:Disconnect() return end
        local dist = (hrp.Position - target).Magnitude
        if dist > 1 then
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(target) * hrp.CFrame.Rotation, math.clamp((30 * dt) / dist, 0, 1))
        else
            conn:Disconnect()
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    
    while conn.Connected do task.wait(0.1) end
    if bv then bv:Destroy() end
end

print("[CraftAllLegends] Flying to Blacksmith...")
FlyTo(targetPos)
task.wait(0.5)

print("[CraftAllLegends] Initiating Ghost Conversation...")
pcall(function() questEvent:InvokeServer({ [1] = "npcChat", [2] = true }) end)
task.wait(0.5)

for _, craftItem in ipairs(craftQueue) do
    print("[CraftAllLegends] Crafting " .. craftItem.Batches .. " batches of " .. craftItem.Name .. "...")
    for i = 1, craftItem.Batches do
        pcall(function()
            craftingRemote:InvokeServer({ 
                Count = 40, 
                ExtraData = { ["Legendary Fish"] = craftItem.Name }, 
                Method = "Craft", 
                BlueprintItem = "Legendary Fish Bait" 
            })
        end)
        task.wait(0.5)
    end
end

print("[CraftAllLegends] Closing Conversation...")
pcall(function() questEvent:InvokeServer({ [1] = "npcChat", [2] = false }) end)
task.wait(0.5)

print("[CraftAllLegends] Returning to original position...")
FlyTo(originalPos)

print("[CraftAllLegends] Sequence Complete! You are fully stocked.")
