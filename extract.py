import codecs

with open('joinersystem.lua', 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

def get_block(name):
    start = text.find(name)
    if start == -1: return ''
    
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
    return ''

out = get_block('Tabs.Autofarm:AddToggle("T_CyborgAuto"') + '\n\n'

with open('extracted_blocks.txt', 'w', encoding='utf-8') as f:
    f.write(out)
