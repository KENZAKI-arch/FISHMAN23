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
-- PART 2: SMART AUTOLOAD & JOIN
-- ========================================== --
print("[Autoload] Waiting for game to load...")

if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(3) 

-- 1. Send the private server code
print("[Autoload] Attempting to send private server code...")
task.spawn(function()
    local codeArgs = { [1] = "qj1ttW4JG1" }
    pcall(function()
        ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("reserved", 9e9):InvokeServer(unpack(codeArgs))
        print("[Autoload] Private server code sent successfully.")
    end)
end)

task.wait(3)

-- 2. Send the confirmation (True)
print("[Autoload] Confirming team selection...")
local confirmArgs = { [1] = true }
pcall(function()
    LocalPlayer:WaitForChild("PlayerGui", 9e9):WaitForChild("chooseType", 9e9):WaitForChild("Frame", 9e9):WaitForChild("RemoteEvent", 9e9):FireServer(unpack(confirmArgs))
    print("[Autoload] Team selection confirmed.")
end)

task.wait(3)

-- 3. AUTOLOAD THE MAIN FARM SCRIPT
print("[Autoload] Launching main Controller.lua...")
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Controller.lua"))()
    print("[Autoload] Controller loaded successfully!")
end)