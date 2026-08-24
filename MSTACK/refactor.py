import re
import os

with open("joinersystem.lua", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Transform global-locals to use getgenv().FishmanState
transforms = [
    (r"local _running", r"getgenv().FishmanState._running"),
    (r"local _connections", r"getgenv().FishmanState._connections"),
    (r"local Tabs", r"getgenv().FishmanState.Tabs"),
    (r"local Fluent", r"getgenv().FishmanState.Fluent"),
    (r"local function addConn", r"getgenv().FishmanState.addConn = function"),
    (r"local function disconnectAll", r"getgenv().FishmanState.disconnectAll = function"),
    (r"local function TriggerSafeguardShutdown", r"getgenv().FishmanState.TriggerSafeguardShutdown = function"),
    (r"local function SaveConfig", r"getgenv().FishmanState.SaveConfig = function"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\b_running\b", r"getgenv().FishmanState._running"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\b_connections\b", r"getgenv().FishmanState._connections"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bTabs\b", r"getgenv().FishmanState.Tabs"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bFluent\b", r"getgenv().FishmanState.Fluent"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\baddConn\b", r"getgenv().FishmanState.addConn"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bdisconnectAll\b", r"getgenv().FishmanState.disconnectAll"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bTriggerSafeguardShutdown\b", r"getgenv().FishmanState.TriggerSafeguardShutdown"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bSaveConfig\b", r"getgenv().FishmanState.SaveConfig"),
]

for pattern, repl in transforms:
    content = re.sub(pattern, repl, content)

# 2. Add preamble for standard game services to each file
preamble = """
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
local env = getgenv and getgenv() or shared
local GlobalMem = env

-- Bind state variables locally for ease of use in this file
local _running = getgenv().FishmanState._running
local _connections = getgenv().FishmanState._connections
local Tabs = getgenv().FishmanState.Tabs
local Fluent = getgenv().FishmanState.Fluent
local addConn = getgenv().FishmanState.addConn
local disconnectAll = getgenv().FishmanState.disconnectAll
local TriggerSafeguardShutdown = getgenv().FishmanState.TriggerSafeguardShutdown
local SaveConfig = getgenv().FishmanState.SaveConfig
"""

# Split points based on headers
lines = content.split('\n')

def find_idx(text):
    for i, l in enumerate(lines):
        if text in l:
            return i
    return len(lines)

teleport_idx = find_idx("TELEPORT MEMORY INJECTION") - 1
fishing_idx = find_idx("FISHING ENGINE CORE") - 1
ui_idx = find_idx("CUSTOM LIGHTWEIGHT UI INTEGRATION") - 1

if teleport_idx < 0: teleport_idx = len(lines)//4
if fishing_idx < 0: fishing_idx = len(lines)//2
if ui_idx < 0: ui_idx = len(lines) - 1000

part_state_config = lines[0:teleport_idx]
part_teleport = lines[teleport_idx:fishing_idx]
part_fishing = lines[fishing_idx:ui_idx]
part_ui = lines[ui_idx:]

os.makedirs("GPO Script", exist_ok=True)

with open("GPO Script/Config.lua", "w", encoding="utf-8") as f:
    f.write("-- Config & State Setup\n")
    f.write("getgenv().FishmanState = getgenv().FishmanState or {}\n")
    f.write('\n'.join(part_state_config))

with open("GPO Script/TeleportEngine.lua", "w", encoding="utf-8") as f:
    f.write("-- Teleport Engine\n")
    f.write(preamble + "\n")
    f.write('\n'.join(part_teleport))

with open("GPO Script/FishingEngine.lua", "w", encoding="utf-8") as f:
    f.write("-- Fishing Engine\n")
    f.write(preamble + "\n")
    f.write('\n'.join(part_fishing))

with open("GPO Script/UI.lua", "w", encoding="utf-8") as f:
    f.write("-- UI & Layout\n")
    f.write(preamble + "\n")
    f.write('\n'.join(part_ui))

with open("GPO Script/Main.lua", "w", encoding="utf-8") as f:
    f.write('''-- Main Loader Orchestrator
print("[Fishman] Loading Modular Architecture...")
local repoURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/MSTACK/GPO%20Script/"

local modules = {
    "Config.lua",
    "TeleportEngine.lua",
    "FishingEngine.lua",
    "UI.lua"
}

for _, mod in ipairs(modules) do
    local success, err = pcall(function()
        loadstring(game:HttpGet(repoURL .. mod))()
    end)
    if not success then
        warn("[Fishman] Failed to load module " .. mod .. ": " .. tostring(err))
    end
end
print("[Fishman] All modules loaded successfully!")
''')

print("Successfully split joinersystem.lua into GPO Script folder!")
