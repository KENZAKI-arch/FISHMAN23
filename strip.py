import re

def extract_block(text, search_str):
    start = text.find(search_str)
    if start == -1: return ""
    
    # We need to find the matching '})' for 'Tabs.something:AddToggle(..., {'
    # Actually, we can just find the matching '})' at the same indentation level, or use a bracket counter.
    bracket_count = 0
    in_string = False
    escape = False
    
    for i in range(start, len(text)):
        char = text[i]
        
        if escape:
            escape = False
            continue
            
        if char == '\\':
            escape = True
            continue
            
        if char == '"' or char == "'":
            if not in_string:
                in_string = char
            elif in_string == char:
                in_string = False
            continue
            
        if not in_string:
            if char == '(':
                bracket_count += 1
            elif char == ')':
                bracket_count -= 1
                if bracket_count == 0:
                    return text[start:i+1]
                    
    return ""

with open('joinersystem.lua', 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

def find_boundary(name):
    pattern = r'-- =+[\r\n]+-- .*?' + name + r'.*?[\r\n]+-- =+[\r\n]+'
    match = re.search(pattern, text)
    if match: return match.start(), match.end(), match.group(0)
    return -1, -1, ""

tele_start, tele_end, tele_hdr = find_boundary("TELEPORT TAB UI")
nav_start, nav_end, nav_hdr = find_boundary("NAVIGATION TAB UI")
fish_start, fish_end, fish_hdr = find_boundary("FISHING TAB UI")
farm_start, farm_end, farm_hdr = find_boundary("AUTOFARM TAB UI")
set_start, set_end, set_hdr = find_boundary("SETTINGS TAB UI")

pre_ui = text[:tele_start]
tele_block = text[tele_end:nav_start]
fish_block = text[fish_end:farm_start]
post_ui = text[set_start:]

# Remove unwanted tabs from Tabs = {}
pre_ui = re.sub(r'Navigation\s*=\s*Window:AddTab\(\{.*?\}\),?\s*', '', pre_ui)
pre_ui = re.sub(r'Autofarm\s*=\s*Window:AddTab\(\{.*?\}\),?\s*', '', pre_ui)

spawn_ship = extract_block(tele_block, 'Tabs.Teleport:AddToggle("T_AutoSpawnShip"')
meg_stack = extract_block(fish_block, 'Tabs.Fishing:AddToggle("T_MegStackLoc"')
manual_meg = extract_block(fish_block, 'Tabs.Fishing:AddToggle("T_ManualMegStackLoc"')

new_text = pre_ui
new_text += tele_hdr + spawn_ship + "\n\n"
new_text += fish_hdr + meg_stack + "\n\n" + manual_meg + "\n\n"
new_text += post_ui

with open('MSTACK/isolated_megstack.lua', 'w', encoding='utf-8') as f:
    f.write(new_text)

print("Successfully generated properly balanced isolated_megstack.lua!")
