-- ========================================== --
-- PERSISTENCE ENGINE: Survives Teleports
-- ========================================== --
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Prevent duplicate running
if _G.FishmanPersistent_Running then return end
_G.FishmanPersistent_Running = true

-- Create an "Orphaned" Folder in CoreGui to anchor the script
local MyPersistentContainer = CoreGui:FindFirstChild("MyPersistentContainer") or Instance.new("Folder")
MyPersistentContainer.Name = "MyPersistentContainer"
MyPersistentContainer.Parent = CoreGui

-- ========================================== --
-- PART 1: THE DISCONNECT WATCHER
-- ========================================== --
task.spawn(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            print("[Watcher] Disconnected! Rejoining in 5 seconds...")
            task.wait(5)
            TeleportService:Teleport(1730877806, LocalPlayer)
        end
    end)
end)

-- ========================================== --
-- PART 2: UI-DETECTION LOAD SYSTEM (Persistent)
-- ========================================== --
task.spawn(function()
    while true do
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        
        -- 1. WAIT FOR TRIGGER: "Set Sail" button
        local startButton = nil
        repeat 
            task.wait(1) 
            for _, v in pairs(PlayerGui:GetDescendants()) do
                if v:IsA("TextButton") and v.Text == "Set Sail" then
                    startButton = v
                    break
                end
            end
        until startButton ~= nil
        
        print("[Autoload] 'Set Sail' detected! Joining...")
        
        -- 2. Click button
        VirtualInputManager:SendMouseButtonEvent(startButton.AbsolutePosition.X + 5, startButton.AbsolutePosition.Y + 5, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(startButton.AbsolutePosition.X + 5, startButton.AbsolutePosition.Y + 5, 0, false, game, 1)
        
        -- 3. Send private server code
        task.spawn(function()
            pcall(function()
                ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("reserved", 9e9):InvokeServer("qj1ttW4JG1")
            end)
        end)
        
        -- 4. Confirm Team Selection
        repeat task.wait(0.5) until PlayerGui:FindFirstChild("chooseType")
        pcall(function()
            PlayerGui:WaitForChild("chooseType", 9e9):WaitForChild("Frame", 9e9):WaitForChild("RemoteEvent", 9e9):FireServer(true)
            print("[Autoload] Team selected.")
        end)
        
        -- Wait for teleport or reset
        task.wait(10)
    end
end)

-- Heartbeat monitoring to keep the script "alive" and checking connection
RunService.Heartbeat:Connect(function()
    -- Script stays attached to the game heartbeat here
end)