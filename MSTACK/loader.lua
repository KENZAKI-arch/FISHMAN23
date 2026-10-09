-- ==========================================
-- Fishman Hub Multi-Account Loader
-- ==========================================
if getgenv().FishmanLoaderLastExecuted and (tick() - getgenv().FishmanLoaderLastExecuted < 10) then
    warn("[Fishman Loader] Aborting duplicate execution (preventing autoexec/queue_on_teleport overlap)")
    return
end
if getgenv().FishmanLoaderLastExecuted then
    warn("[Fishman Loader] Reloading script with updated version...")
end
getgenv().FishmanLoaderLastExecuted = tick()

local Players = game:GetService("Players")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
    task.wait(1)
    LocalPlayer = Players.LocalPlayer
end
-- ==========================================
-- ANTI-AFK SYSTEM
-- ==========================================
local StarterGui = game:GetService("StarterGui")
task.spawn(function()
    task.wait(2)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Anti-AFK",
            Text = "Script successfully loaded and is running!",
            Duration = 5,
        })
    end)
end)

local VIM = cloneref and cloneref(game:GetService("VirtualInputManager")) or game:GetService("VirtualInputManager")

if getgenv().FishmanAntiAFKConnection then
    getgenv().FishmanAntiAFKConnection:Disconnect()
end

getgenv().FishmanAntiAFKConnection = LocalPlayer.Idled:Connect(function()
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Anti-AFK Triggered",
            Text = "Simulated movement to prevent disconnect.",
            Duration = 3,
        })
    end)
    VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
end)
-- ==========================================

-- ⚙️ GLOBAL SETTINGS
local DefaultPSCode = "qj1ttW4JG1"
local DefaultDestination = "tradeHub"

-- Apply Configuration
local playerName = LocalPlayer.Name
local chosenCode = DefaultPSCode
local chosenDest = DefaultDestination
if chosenDest == "Trade Hub" then chosenDest = "tradeHub" end

getgenv().FishmanDefaultPSCode = chosenCode
getgenv().FishmanDefaultDestination = chosenDest
-- The loader provides the 'Default' config to act as a starting location.

print("[Fishman Loader] Account detected: " .. playerName)
print("[Fishman Loader] Assigned PS Code: " .. chosenCode)

local scriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/MSTACK/Modularized/Main.lua?t=" .. tostring(tick())

print("[Fishman Loader] Loading modular Main.lua...")
local success, err = pcall(function()
    loadstring(game:HttpGet(scriptURL))()
end)

if not success then
    warn("[Fishman Loader] Failed to load joinersystem: " .. tostring(err))
end
