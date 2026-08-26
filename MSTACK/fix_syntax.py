import re

with open("GPO Script/FishingEngine.lua", "r", encoding="utf-8") as f:
    content = f.read()

# Fix syntax errors with function getgenv()...
content = re.sub(r"function\s+getgenv\(\)\.FishmanState\.Model\.([a-zA-Z0-9_]+)\s*\(", r"getgenv().FishmanState.Model.\1 = function(", content)

# Fix IsA("getgenv().FishmanState.Model")
content = re.sub(r'IsA\("getgenv\(\)\.FishmanState\.Model"\)', r'IsA("Model")', content)

with open("GPO Script/FishingEngine.lua", "w", encoding="utf-8") as f:
    f.write(content)

with open("GPO Script/UI.lua", "r", encoding="utf-8") as f:
    content = f.read()

content = re.sub(r'IsA\("getgenv\(\)\.FishmanState\.Model"\)', r'IsA("Model")', content)

with open("GPO Script/UI.lua", "w", encoding="utf-8") as f:
    f.write(content)

print("Syntax errors fixed!")
