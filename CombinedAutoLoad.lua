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
-- -- ========================================== --
-- PART 2: SMART AUTOLOAD & JOIN
-- ========================================== --

-- 1. WAIT FOR THE GAME TO ACTUALLY START
-- We wait until your character exists, which ONLY happens after you click 'Play'
print("[Autoload] Waiting for character to spawn...")
local LocalPlayer = Players.LocalPlayer
repeat task.wait(1) until LocalPlayer.Character ~= nil
print("[Autoload] Character spawned! Proceeding to join server...")

-- 2. Send the private server code
task.spawn(function()
    local codeArgs = { [1] = "qj1ttW4JG1" }
    pcall(function()
        ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("reserved", 9e9):InvokeServer(unpack(codeArgs))
        print("[Autoload] Private server code sent.")
    end)
end)

-- 3. Confirmation
task.wait(3)
print("[Autoload] Confirming team selection...")
local confirmArgs = { [1] = true }
pcall(function()
    -- I added an extra check here to make sure the GUI is actually there
    LocalPlayer:WaitForChild("PlayerGui", 9e9):WaitForChild("chooseType", 9e9):WaitForChild("Frame", 9e9):WaitForChild("RemoteEvent", 9e9):FireServer(unpack(confirmArgs))
    print("[Autoload] Team selection confirmed.")
end)

-- 4. Load Controller
task.wait(3)
print("[Autoload] Launching Controller.lua...")
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Controller.lua"))()
end)