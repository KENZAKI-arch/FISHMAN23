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

-- ⚙️ ACCOUNT CONFIGURATION
-- Add your accounts and their corresponding private server codes here.
local AccountConfigs = {
    ["ReneButterbones"] = { code = "qj1ttW4JG1", dest = "Second Sea" },
    ["BarriacadedAlex"] = { code = "vcvq1Xp6GC", dest = "Second Sea" },
    ["pc_Romer900"] = { code = "dmNfaqsjjj", dest = "Second Sea" },
    ["LumpiangToge234"] = { code = "MCVwx2gvJv", dest = "Second Sea" },
    ["TuronLovers"] = { code = "tirAZ2rx2s", dest = "Second Sea" },
    ["SiomaiRice12369"] = { code = "dTuByY1k0O", dest = "Second Sea" },
    ["Haswell128"] = { code = "IxM1NarToN", dest = "Second Sea" },
    ["KamiSiRene"] = { code = "CnHpO5Kwa9", dest = "Second Sea" },
    ["LumpiangChina"] = { code = "gVKAsClzbt", dest = "Second Sea" },
    ["BeeswarmTensei"] = { code = "UO4gc2IyTY", dest = "Second Sea" }
}

-- ⚙️ GLOBAL SETTINGS
local DefaultPSCode = "qj1ttW4JG1"          -- Used if the account is not in AccountConfigs
local DefaultDestination = "Second Sea"

-- Apply Configuration
local playerName = LocalPlayer.Name
local chosenConfig = AccountConfigs[playerName]
local chosenCode = chosenConfig and chosenConfig.code or DefaultPSCode
local chosenDest = chosenConfig and chosenConfig.dest or DefaultDestination

getgenv().FishmanDefaultPSCode = chosenCode
getgenv().FishmanDefaultDestination = chosenDest
-- The loader provides the 'Default' config to act as a starting location.

if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end
task.wait(3)

local islands = workspace:WaitForChild("Islands", 5)
local isWholeCake = false
if islands then
    local wci = islands:FindFirstChild("Whole Cake Island")
    if wci then
        local wciInner = wci:FindFirstChild("WholeCakeIsland")
        if wciInner and wciInner:FindFirstChild("Terrain") then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local referencePart = wciInner:FindFirstChildWhichIsA("BasePart", true) or wci:FindFirstChildWhichIsA("BasePart", true)
            
            if hrp and referencePart then
                local dist = (hrp.Position - referencePart.Position).Magnitude
                if dist <= 3000 then
                    isWholeCake = true
                else
                    print("[Fishman Loader] Whole Cake Island detected, but you are " .. math.floor(dist) .. " studs away. (Needs to be < 3000)")
                end
            elseif hrp and not referencePart then
                -- Fallback if no specific parts are loaded yet but terrain exists
                isWholeCake = true
            end
        end
    end
end

local isInCorrectPS = false
pcall(function()
    local gui = LocalPlayer:WaitForChild("PlayerGui", 5)
    local settings = gui and gui:WaitForChild("Settings", 5)
    local main = settings and settings:WaitForChild("Main", 5)
    local codeLabel = main and main:WaitForChild("Code", 5)

    if codeLabel then
        for i = 1, 10 do
            if codeLabel.Text:find(chosenCode, 1, true) then
                isInCorrectPS = true
                break
            end
            task.wait(1)
        end
    end
end)

if isWholeCake and isInCorrectPS then
    getgenv().FishmanAutoSpawnShip = true
    print("[Fishman Loader] Whole Cake Island & Correct PS detected! Auto Spawn Ship enabled.")
else
    getgenv().FishmanAutoSpawnShip = false
    if game.PlaceId == 7369873099 then
        print("[Fishman Loader] In Trade Hub. Auto Spawn Ship disabled.")
    elseif game.PlaceId == 1730877806 or game.PlaceId == 2753915549 then
        print("[Fishman Loader] In Lobby. Auto Spawn Ship disabled.")
    elseif not isInCorrectPS then
        print("[Fishman Loader] Not in assigned PS (" .. chosenCode .. "). Auto Spawn Ship disabled.")
    else
        print("[Fishman Loader] Not at Whole Cake Island. Auto Spawn Ship disabled.")
    end
end

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
