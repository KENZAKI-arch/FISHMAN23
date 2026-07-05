-- ==========================================
-- Auto Reroll Race Script (Skypian)
-- ==========================================
local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 10)

if not PlayerGui then
    warn("PlayerGui not found!")
    return
end

local Customization = PlayerGui:WaitForChild("Customization", 10)
if not Customization then
    warn("Customization UI not found!")
    return
end

local Main = Customization:WaitForChild("Main", 10)
local RaceTypeLabel = Main:WaitForChild("RaceType", 10)
local RaceRerolls = Main:WaitForChild("RaceRerolls", 10)
local RerollButton = RaceRerolls:WaitForChild("RaceRerollButton", 10)

if not (RaceTypeLabel and RerollButton) then
    warn("Could not find RaceTypeLabel or RerollButton!")
    return
end

-- Stop any previous running instances of this script
if getgenv().StopAutoReroll then
    getgenv().StopAutoReroll()
end

local isRunning = true
getgenv().StopAutoReroll = function()
    isRunning = false
    print("[Auto Reroll] Stopped manually.")
end

local DESIRED_RACE = "SKYPIAN"

print("[Auto Reroll] Starting... Looking for: " .. DESIRED_RACE)

task.spawn(function()
    while isRunning do
        -- Read the current race
        local currentText = RaceTypeLabel.Text -- e.g., "You are a HUMAN"
        
        -- Check if it matches SKYPIAN (case-insensitive check)
        if string.find(string.upper(currentText), string.upper(DESIRED_RACE)) then
            print("[Auto Reroll] Successfully rolled " .. DESIRED_RACE .. "! Stopping script.")
            isRunning = false
            break
        end
        
        -- If not Skypian, fire the Reroll RemoteEvent
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Events", 5):WaitForChild("reroll", 5):InvokeServer()
        end)
        
        -- Wait a moment before rerolling again to allow the server to process and UI to update
        task.wait(1.5)
    end
end)
