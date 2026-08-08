import re

ui_lib = open('ui_library.lua', 'r', encoding='utf-8').read()
mobile_file = 'MSTACK/joinersystem_mobile.lua'
content = open(mobile_file, 'r', encoding='utf-8').read()

target_str = 'local redzlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/tbao143/Library-ui/refs/heads/main/Redzhubui"))()'

if target_str in content:
    new_content = content.replace(target_str, ui_lib)
    open(mobile_file, 'w', encoding='utf-8').write(new_content)
    print('Successfully replaced redzlib!')
else:
    print('Failed to find target string.')
