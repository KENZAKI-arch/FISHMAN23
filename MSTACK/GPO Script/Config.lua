-- Config & State Setup
getgenv().FishmanState = getgenv().FishmanState or {}
-- Version 3.9
-- ======================================================================
-- 🛑 GLOBAL SETUP & DUPLICATE PREVENTION
-- ======================================================================
local env = getgenv and getgenv() or shared
if env.Fishman_StopPrevious then
    pcall(env.Fishman_StopPrevious)
end
if env.Fishman_DestroyUI then
    pcall(env.Fishman_DestroyUI)
end

env.FishmanScriptServer = game.JobId

getgenv().FishmanState._running = true
getgenv().FishmanState._connections = {}


getgenv().FishmanState.addConn = function(conn)
    table.insert(getgenv().FishmanState._connections, conn)
    return conn
end

getgenv().FishmanState.disconnectAll = function()
    for _, c in ipairs(getgenv().FishmanState._connections) do
        if c and c.Connected then c:Disconnect() end
    end
    table.clear(getgenv().FishmanState._connections)
end

print("--- [Fishman] Unified Script Starting ---")
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do 
    task.wait(1)
    LocalPlayer = Players.LocalPlayer 
end

getgenv().FishmanState.TriggerSafeguardShutdown = function(reason)
    warn("[Fishman] WIFI SAFEGUARD TRIGGERED: " .. tostring(reason))
    getgenv().FishmanState._running = false
    getgenv().FishmanState.disconnectAll()
    if env.Fishman_DestroyUI then pcall(env.Fishman_DestroyUI) end
end

-- Robust network/weak wifi safeguard: wait for essential player instances to fully replicate
print("[Fishman] Waiting for weak connection safeguard (Character & PlayerGui)...")
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
if not character:FindFirstChild("HumanoidRootPart") then
    local hrp = character:WaitForChild("HumanoidRootPart", 60)
    if not hrp then
        getgenv().FishmanState.TriggerSafeguardShutdown("HumanoidRootPart failed to load within 60 seconds.")
        return -- Exit main thread
    end
end
if not LocalPlayer:FindFirstChild("PlayerGui") then
    local gui = LocalPlayer:WaitForChild("PlayerGui", 60)
    if not gui then
        getgenv().FishmanState.TriggerSafeguardShutdown("PlayerGui failed to load within 60 seconds.")
        return -- Exit main thread
    end
end
task.wait(2) -- Additional buffer to ensure client is fully responsive
print("[Fishman] Game fully loaded!")

-- Active Ping Monitor (Shuts down script if wifi drops mid-game)
task.spawn(function()
    local Stats = game:GetService("Stats")
    local consecutiveHighPing = 0
    while getgenv().FishmanState._running and task.wait(5) do
        pcall(function()
            local pingStr = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
            local pingVal = tonumber(string.match(pingStr, "%d+%.?%d*"))
            if pingVal and pingVal > 4000 then -- 4 seconds behind
                consecutiveHighPing = consecutiveHighPing + 1
                if consecutiveHighPing >= 6 then -- 30 seconds of pure 4000+ ping
                    getgenv().FishmanState.TriggerSafeguardShutdown("Ping exceeded 4000ms for 30s. Connection lost.")
                end
            else
                consecutiveHighPing = 0
            end
        end)
    end
end)

local targetPlaceId = 1730877806
local isLobby = (game.PlaceId == targetPlaceId)
local GlobalMem = env

-- ======================================================================
-- ⚙️ CONFIGURATION SYSTEM
-- ======================================================================
local configFileName = "FishmanConfig_" .. tostring(LocalPlayer.UserId) .. ".json"

local isFreshStart = true
pcall(function()
    if isfile and readfile and isfile(configFileName) then
        local data = HttpService:JSONDecode(readfile(configFileName))
        if data and data.LastTeleportTime then
            if os.time() - data.LastTeleportTime < 180 then -- 3 minutes
                isFreshStart = false
            end
        end
    end
end)
if getgenv().FishmanQOT_Active then isFreshStart = false end

if isFreshStart then
    if getgenv().FishmanDefaultPSCode then GlobalMem.FishmanPSCode = getgenv().FishmanDefaultPSCode end
    if getgenv().FishmanDefaultDestination then GlobalMem.FishmanDestination = getgenv().FishmanDefaultDestination end
    if getgenv().FishmanAutoSpawnShip ~= nil then GlobalMem.FishmanAutoSpawnShip = getgenv().FishmanAutoSpawnShip end
    GlobalMem.FishmanAutoRouteLobby = true
end

pcall(function()
    if isfile and readfile and isfile(configFileName) then
        local data = HttpService:JSONDecode(readfile(configFileName))
        if data then
            if GlobalMem.FishmanPSCode == nil then GlobalMem.FishmanPSCode = data.FishmanPSCode end
            if GlobalMem.FishmanPSCodeHistory == nil then GlobalMem.FishmanPSCodeHistory = data.FishmanPSCodeHistory end
            if GlobalMem.FishmanDestination == nil then GlobalMem.FishmanDestination = data.FishmanDestination end
            if GlobalMem.FishmanAutoTeleport == nil then GlobalMem.FishmanAutoTeleport = data.FishmanAutoTeleport end
            if GlobalMem.FishmanAutoJoin == nil then GlobalMem.FishmanAutoJoin = data.FishmanAutoJoin end
            if GlobalMem.FishmanAutoReconnect == nil then GlobalMem.FishmanAutoReconnect = data.FishmanAutoReconnect end
            if GlobalMem.FishmanAutoRouteLobby == nil then GlobalMem.FishmanAutoRouteLobby = data.FishmanAutoRouteLobby end
            if GlobalMem.FishmanAutoSpawnShip == nil then GlobalMem.FishmanAutoSpawnShip = data.FishmanAutoSpawnShip end
            print("[Fishman] Loaded Config from file.")
        end
    end
end)

GlobalMem.FishmanPSCode = GlobalMem.FishmanPSCode or GlobalMem.FishmanDefaultPSCode or "qj1ttW4JG1"
if type(GlobalMem.FishmanPSCodeHistory) ~= "table" or #GlobalMem.FishmanPSCodeHistory == 0 then
    GlobalMem.FishmanPSCodeHistory = {GlobalMem.FishmanPSCode}
end
if not table.find(GlobalMem.FishmanPSCodeHistory, GlobalMem.FishmanPSCode) and GlobalMem.FishmanPSCode ~= "" then
    table.insert(GlobalMem.FishmanPSCodeHistory, 1, GlobalMem.FishmanPSCode)
end
GlobalMem.FishmanDestination = GlobalMem.FishmanDestination or GlobalMem.FishmanDefaultDestination or "tradeHub" 
GlobalMem.FishmanAutoTeleport = GlobalMem.FishmanAutoTeleport or false 
GlobalMem.FishmanAutoJoin = GlobalMem.FishmanAutoJoin or false
if GlobalMem.FishmanAutoReconnect == nil then GlobalMem.FishmanAutoReconnect = true end
if GlobalMem.FishmanAutoRouteLobby == nil then GlobalMem.FishmanAutoRouteLobby = true end

getgenv().FishmanState.SaveConfig = function()
    pcall(function()
        if writefile then
            local data = {
                FishmanPSCode = GlobalMem.FishmanPSCode,
                FishmanPSCodeHistory = GlobalMem.FishmanPSCodeHistory,
                FishmanDestination = GlobalMem.FishmanDestination,
                FishmanAutoTeleport = GlobalMem.FishmanAutoTeleport,
                FishmanAutoJoin = GlobalMem.FishmanAutoJoin,
                FishmanAutoReconnect = GlobalMem.FishmanAutoReconnect,
                FishmanAutoRouteLobby = GlobalMem.FishmanAutoRouteLobby,
                FishmanAutoSpawnShip = GlobalMem.FishmanAutoSpawnShip
            }
            writefile(configFileName, HttpService:JSONEncode(data))
        end
    end)
end
