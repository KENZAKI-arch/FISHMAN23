import re

def process_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    for old, new in replacements:
        content = re.sub(old, new, content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

ui_replacements = [
    (r"(?<!getgenv\(\)\.FishmanState\.)\btargetPlaceId\b", r"getgenv().FishmanState.targetPlaceId")
]
process_file("GPO Script/UI.lua", ui_replacements)

print("Fixed targetPlaceId in UI.lua!")
