-- ==========================================
-- Fishman Hub Multi-Account Loader
-- ==========================================
local Players = game:GetService("Players")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
    task.wait(1)
    LocalPlayer = Players.LocalPlayer
end

-- ⚙️ ACCOUNT CONFIGURATION
-- Add your accounts and their corresponding private server codes here.
local AccountConfigs = {
    ["MKRBarbershop"] = "vcvq1Xp6GC",
    ["KevinSanjaya230"] = "dmNfaqsjjj",
    ["KimchiHwarang"] = "MCVwx2gvJv",
    ["KimGuk4ap"] = "tirAZ2rx2s",
    ["EUNHAMARKET"] = "dTuByY1k0O",
    ["VoicesOfTheChord0"] = "IxM1NarToN",
    ["ReneAckerman0"] = "CnHpO5Kwa9",
    ["ReneButterbones"] = "qj1ttW4JG1",
    ["JackButterbones"] = "PRriWnrVWW",
    ["NinelieJohnmark"] = "UO4gc2IyTY",
    ["KingOfAOC"] = "D7YApdhRP1",
    ["ChristianExpress"] = "HiBe6mk1H7",
    ["ButterbonesClan"] = "KY4ilrrIXX"
}

-- ⚙️ GLOBAL SETTINGS
local DefaultPSCode = "qj1ttW4JG1"          -- Used if the account is not in AccountConfigs

-- Apply Configuration
local playerName = LocalPlayer.Name
local chosenCode = AccountConfigs[playerName] or DefaultPSCode

getgenv().FishmanDefaultPSCode = chosenCode
getgenv().FishmanDefaultDestination = "Second Sea"
-- The loader provides the 'Default' config to act as a starting location.

local NoAutoSpawnAccounts = {
    ["NinelieJohnmark"] = true,
    ["KingOfAOC"] = true,
    ["ChristianExpress"] = true,
    ["ButterbonesClan"] = true
}

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
            isWholeCake = true
        end
    end
end

if isWholeCake and not NoAutoSpawnAccounts[playerName] then
    getgenv().FishmanAutoSpawnShip = true
    print("[Fishman Loader] Whole Cake Island detected! Auto Spawn Ship enabled.")
else
    getgenv().FishmanAutoSpawnShip = false
    if game.PlaceId == 7369873099 then
        print("[Fishman Loader] In Trade Hub. Auto Spawn Ship disabled.")
    elseif game.PlaceId == 1730877806 or game.PlaceId == 2753915549 then
        print("[Fishman Loader] In Lobby. Auto Spawn Ship disabled.")
    else
        print("[Fishman Loader] Not at Whole Cake Island. Auto Spawn Ship disabled.")
    end
end

print("[Fishman Loader] Account detected: " .. playerName)
print("[Fishman Loader] Assigned PS Code: " .. chosenCode)

-- Execute Main Script
local scriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/MSTACK/joinersystem.lua?t=" .. tostring(tick())

print("[Fishman Loader] Loading joinersystem...")
local success, err = pcall(function()
    loadstring(game:HttpGet(scriptURL))()
end)

if not success then
    warn("[Fishman Loader] Failed to load joinersystem: " .. tostring(err))
end
