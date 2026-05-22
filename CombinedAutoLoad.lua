local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local targetPlaceId = 1730877806

-- ========================================== --
-- PART 1: THE DISCONNECT WATCHER
-- ========================================== --
task.spawn(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
    
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            print("[Watcher] Disconnected! Auto-rejoining in 5 seconds...")
            task.wait(5) 
            
            pcall(function()
                TeleportService:Teleport(targetPlaceId, LocalPlayer)
            end)
        end
    end)
end)

-- ========================================== --
-- PART 2: UI-DETECTION LOAD SYSTEM
-- ========================================== --

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("[Autoload] Waiting for 'Start' UI to appear...")

-- 1. WAIT FOR THE TRIGGER: The script sleeps until "Start" UI exists
repeat task.wait(0.5) until PlayerGui:FindFirstChild("Start")
print("[Autoload] 'Start' UI detected! Beginning server join...")

-- 2. Send the private server code
task.spawn(function()
    local codeArgs = { [1] = "qj1ttW4JG1" }
    pcall(function()
        ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("reserved", 9e9):InvokeServer(unpack(codeArgs))
        print("[Autoload] Private server code sent.")
    end)
end)

-- 3. WAIT FOR THE TELEPORT: We wait for the 'Start' UI to disappear
-- This proves we have left the lobby and are loading into the game
repeat task.wait(0.5) until not PlayerGui:FindFirstChild("Start")
print("[Autoload] 'Start' UI gone. Teleporting confirmed. Waiting for team menu...")

-- 4. Confirm Team Selection
-- Now we wait for the team selection menu to appear
repeat task.wait(1) until PlayerGui:FindFirstChild("chooseType")
local confirmArgs = { [1] = true }
pcall(function()
    PlayerGui:WaitForChild("chooseType", 9e9):WaitForChild("Frame", 9e9):WaitForChild("RemoteEvent", 9e9):FireServer(unpack(confirmArgs))
    print("[Autoload] Team selection confirmed.")
end)

-- 5. Load Controller
