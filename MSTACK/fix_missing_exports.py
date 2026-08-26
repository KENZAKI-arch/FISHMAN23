import re

def process_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    for old, new in replacements:
        content = re.sub(old, new, content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# 1. TeleportEngine.lua
teleport_replacements = [
    (r"local UpdateTeleportMemory -- Forward declaration", r"getgenv().FishmanState.UpdateTeleportMemory = nil -- Forward declaration"),
    (r"function UpdateTeleportMemory\b", r"getgenv().FishmanState.UpdateTeleportMemory = function"),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bUpdateTeleportMemory\(", r"getgenv().FishmanState.UpdateTeleportMemory(")
]
process_file("GPO Script/TeleportEngine.lua", teleport_replacements)

# 2. FishingEngine.lua
fishing_replacements = [
    (r"local targetFruits = \{", r"getgenv().FishmanState.targetFruits = {"),
    (r"local function checkFruits\b", r"getgenv().FishmanState.checkFruits = function"),
    (r"local function isFruitAlreadyStored\b", r"getgenv().FishmanState.isFruitAlreadyStored = function"),
    (r"local function storeFruits\b", r"getgenv().FishmanState.storeFruits = function"),
    (r"local function dropFruits\b", r"getgenv().FishmanState.dropFruits = function"),
    (r"local function ShutdownEverything\b", r"getgenv().FishmanState.ShutdownEverything = function"),
    
    # Internal Usages
    (r"(?<!getgenv\(\)\.FishmanState\.)\bcheckFruits\(", r"getgenv().FishmanState.checkFruits("),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bisFruitAlreadyStored\(", r"getgenv().FishmanState.isFruitAlreadyStored("),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bstoreFruits\(", r"getgenv().FishmanState.storeFruits("),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bdropFruits\(", r"getgenv().FishmanState.dropFruits("),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bShutdownEverything\(", r"getgenv().FishmanState.ShutdownEverything(")
]
process_file("GPO Script/FishingEngine.lua", fishing_replacements)

# 3. UI.lua
ui_replacements = [
    (r"(?<!getgenv\(\)\.FishmanState\.)\bUpdateTeleportMemory\(", r"getgenv().FishmanState.UpdateTeleportMemory("),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bcheckFruits\(", r"getgenv().FishmanState.checkFruits("),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bstoreFruits\(", r"getgenv().FishmanState.storeFruits("),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bdropFruits\(", r"getgenv().FishmanState.dropFruits("),
    (r"(?<!getgenv\(\)\.FishmanState\.)\bShutdownEverything\(", r"getgenv().FishmanState.ShutdownEverything(")
]
process_file("GPO Script/UI.lua", ui_replacements)

print("Missing exports fixed!")
