-- ======================================================================
-- CraftAllLegends.lua
-- Standalone macro to craft ALL Legendary Fish in your inventory into Baits.
-- ======================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Global Kill Switch
local isRunning = true
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CraftAllLegendsUI"
screenGui.ResetOnSpawn = false

local success = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not success then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 75)
frame.Position = UDim2.new(0.5, -80, 0.85, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -10, 0, 30)
stopBtn.Position = UDim2.new(0, 5, 0, 5)
stopBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
stopBtn.Text = "STOP CRAFTING"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 12
stopBtn.Parent = frame
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -10, 0, 25)
closeBtn.Position = UDim2.new(0, 5, 0, 42)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
closeBtn.Text = "CLOSE UI"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local stopConn
local function StopScript()
    isRunning = false
    stopBtn.Text = "STOPPED!"
    stopBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    warn("[CraftAllLegends] Script stopped. UI is kept open.")
end

local function CloseUI()
    if screenGui then screenGui:Destroy() end
    if stopConn then stopConn:Disconnect() end
end

stopBtn.MouseButton1Click:Connect(StopScript)
closeBtn.MouseButton1Click:Connect(CloseUI)

stopConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightBracket then
        StopScript()
    end
end)

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
    
    while conn.Connected and isRunning do task.wait(0.1) end
    if bv then bv:Destroy() end
    if not isRunning and conn.Connected then conn:Disconnect() end
end

print("[CraftAllLegends] Flying to Blacksmith...")
FlyTo(targetPos)
task.wait(0.5)
if not isRunning then return end

print("[CraftAllLegends] Initiating Ghost Conversation...")
pcall(function() questEvent:InvokeServer({ [1] = "npcChat", [2] = true }) end)
task.wait(0.5)

for _, craftItem in ipairs(craftQueue) do
    if not isRunning then break end
    print("[CraftAllLegends] Crafting " .. craftItem.Batches .. " batches of " .. craftItem.Name .. "...")
    for i = 1, craftItem.Batches do
        if not isRunning then break end
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
print("[CraftAllLegends] Sequence Complete! You are fully stocked.")
StopScript()
