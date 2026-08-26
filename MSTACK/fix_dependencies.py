import re
import os

def process_file(filepath, imports, exports, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Apply global replacements first
    for old, new in replacements:
        content = re.sub(old, new, content)

    # Insert imports into preamble
    if imports:
        import_str = "\n".join([f"local {v} = getgenv().FishmanState.{v}" for v in imports])
        # Find where to inject imports - right after the preamble 'Bind state variables locally'
        # The preamble ends with SaveConfig
        match = re.search(r"local SaveConfig = getgenv\(\)\.FishmanState\.SaveConfig\n", content)
        if match:
            content = content[:match.end()] + import_str + "\n\n" + content[match.end():]
        else:
            # If no preamble (like in Config.lua), just add it at the top
            content = import_str + "\n" + content

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# 1. Config.lua
# Replace definitions
config_replacements = [
    (r"local targetPlaceId =", r"getgenv().FishmanState.targetPlaceId ="),
    (r"local isLobby =", r"getgenv().FishmanState.isLobby ="),
    (r"local configFileName =", r"getgenv().FishmanState.configFileName ="),
    (r"local isFreshStart =", r"getgenv().FishmanState.isFreshStart =")
]
process_file("GPO Script/Config.lua", [], [], config_replacements)

# 2. TeleportEngine.lua
teleport_replacements = [
    (r"local function GetCurrentPSCode\b", r"getgenv().FishmanState.GetCurrentPSCode = function"),
    (r"local function TeleportToGame\b", r"getgenv().FishmanState.TeleportToGame = function"),
    (r"local function ActivatePotatoGraphics\b", r"getgenv().FishmanState.ActivatePotatoGraphics = function"),
    # Convert their internal usages to use the local vars we'll create or directly access them
    (r"(?<!getgenv\(\)\.FishmanState\.)\btargetPlaceId\b", r"getgenv().FishmanState.targetPlaceId"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bconfigFileName\b", r"getgenv().FishmanState.configFileName"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bisFreshStart\b", r"getgenv().FishmanState.isFreshStart"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bGetCurrentPSCode\b", r"getgenv().FishmanState.GetCurrentPSCode"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bTeleportToGame\b", r"getgenv().FishmanState.TeleportToGame"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bActivatePotatoGraphics\b", r"getgenv().FishmanState.ActivatePotatoGraphics")
]
process_file("GPO Script/TeleportEngine.lua", ["isLobby"], [], teleport_replacements)

# 3. FishingEngine.lua
fishing_replacements = [
    (r"local Model =", r"getgenv().FishmanState.Model ="),
    (r"local isAFKModeActive =", r"getgenv().FishmanState.isAFKModeActive ="),
    (r"local secondsSinceLastInput =", r"getgenv().FishmanState.secondsSinceLastInput ="),
    # Internal usages
    (r"(?<!getgenv\(\)\.FishmanState\.)\bModel\b", r"getgenv().FishmanState.Model"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bisAFKModeActive\b", r"getgenv().FishmanState.isAFKModeActive"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bsecondsSinceLastInput\b", r"getgenv().FishmanState.secondsSinceLastInput"),
]
process_file("GPO Script/FishingEngine.lua", ["isLobby"], [], fishing_replacements)

# 4. UI.lua
ui_replacements = [
    # Replace usages
    (r"(?<!getgenv\(\)\.FishmanState\.)\bModel\b", r"getgenv().FishmanState.Model"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bGetCurrentPSCode\b", r"getgenv().FishmanState.GetCurrentPSCode"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bTeleportToGame\b", r"getgenv().FishmanState.TeleportToGame"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bActivatePotatoGraphics\b", r"getgenv().FishmanState.ActivatePotatoGraphics"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bisAFKModeActive\b", r"getgenv().FishmanState.isAFKModeActive"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bsecondsSinceLastInput\b", r"getgenv().FishmanState.secondsSinceLastInput"),
]
process_file("GPO Script/UI.lua", ["isLobby"], [], ui_replacements)

print("Dependencies fixed!")
