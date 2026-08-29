with open('MSTACK/isolated_megstack.lua', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace CustomName assignments and usage
text = text.replace('local btn = getgenv().CustomUIToggles[k]', 'local data = getgenv().CustomUIToggles[k]\n            local btn = data.Button')
text = text.replace('btn.Text = btn.CustomName .. " [ON]"', 'btn.Text = data.CustomName .. " [ON]"')
text = text.replace('btn.Text = btn.CustomName .. " [OFF]"', 'btn.Text = data.CustomName .. " [OFF]"')

text = text.replace('btn.CustomName = name', '-- btn.CustomName = name')
text = text.replace('getgenv().CustomUIToggles[id] = btn', 'getgenv().CustomUIToggles[id] = { Button = btn, CustomName = name }')

with open('MSTACK/isolated_megstack.lua', 'w', encoding='utf-8') as f:
    f.write(text)

print('Fixed CustomName issue!')
