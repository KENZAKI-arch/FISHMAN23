import re

with open('MSTACK/isolated_megstack.lua', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Remove T_AFK
afk_pattern = r'createToggle\("T_AFK", "⏰ AFK Mode \(Auto-start 10s\)", 3, function\(val\)\n    if isLobby then if val then getgenv\(\).Fluent:Notify\(\{ Title = "Error", Content = "AFK Mode requires Fishing server!", Duration = 3 \}\); getgenv\(\).Fluent.Options.T_AFK:SetValue\(false\) end return end\n    isAFKModeActive = val; secondsSinceLastInput = 0 \nend\)\n\n'
text = re.sub(afk_pattern, '', text)

# 2. Add T_Fish to MegStack toggle
old_megstack = """createToggle("T_MegStack", "🦈 Megalodon Stack", 5, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot stack in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_MegStack:SetValue(false) end return end
    Model.State.isMegStacking = val
    if val then
        if getgenv().Fluent.Options.T_DeepSea then getgenv().Fluent.Options.T_DeepSea:SetValue(true) end"""

new_megstack = """createToggle("T_MegStack", "🦈 Megalodon Stack", 5, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot stack in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_MegStack:SetValue(false) end return end
    Model.State.isMegStacking = val
    if val then
        if getgenv().Fluent.Options.T_DeepSea then getgenv().Fluent.Options.T_DeepSea:SetValue(true) end
        if getgenv().Fluent.Options.T_Fish then getgenv().Fluent.Options.T_Fish:SetValue(true) end"""

text = text.replace(old_megstack, new_megstack)

# Also turn off T_Fish when MegStack is disabled
old_megstack_false = """    else
        print("🛑 [MegStack] Stacking aborted. Shutting down deep sea catcher.")
        if getgenv().Fluent.Options.T_DeepSea and getgenv().Fluent.Options.T_DeepSea.Value == true then getgenv().Fluent.Options.T_DeepSea:SetValue(false) end"""

new_megstack_false = """    else
        print("🛑 [MegStack] Stacking aborted. Shutting down deep sea catcher.")
        if getgenv().Fluent.Options.T_DeepSea and getgenv().Fluent.Options.T_DeepSea.Value == true then getgenv().Fluent.Options.T_DeepSea:SetValue(false) end
        if getgenv().Fluent.Options.T_Fish and getgenv().Fluent.Options.T_Fish.Value == true then getgenv().Fluent.Options.T_Fish:SetValue(false) end"""

text = text.replace(old_megstack_false, new_megstack_false)

# 3. Fix Layout Orders since AFK was removed (3)
# DeepSea (4) -> (3)
text = text.replace('createToggle("T_DeepSea", "🐙 Deep Sea Catcher (Beasts)", 4', 'createToggle("T_DeepSea", "🐙 Deep Sea Catcher (Beasts)", 3')
# MegStack (5) -> (4)
text = text.replace('createToggle("T_MegStack", "🦈 Megalodon Stack", 5', 'createToggle("T_MegStack", "🦈 Megalodon Stack", 4')
# CyborgAuto (6) -> (5)
text = text.replace('createToggle("T_CyborgAuto", "⚔️ Cyborg Autofarm", 6', 'createToggle("T_CyborgAuto", "⚔️ Cyborg Autofarm", 5')
# MegStackLoc (7) -> (6)
text = text.replace('createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 7', 'createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 6')
# ManualMegStackLoc (8) -> (7)
text = text.replace('createToggle("T_ManualMegStackLoc", "🎣 Manual Meg Stack", 8', 'createToggle("T_ManualMegStackLoc", "🎣 Manual Meg Stack", 7')
# AutoSpawnShip (9) -> (8)
text = text.replace('createToggle("T_AutoSpawnShip", "🛳️ Auto Spawn Ship", 9', 'createToggle("T_AutoSpawnShip", "🛳️ Auto Spawn Ship", 8')
# AntiLag (10) -> (9)
text = text.replace('createToggle("T_AntiLag", "⚙️ Disable 3D (Anti-Lag)", 10', 'createToggle("T_AntiLag", "⚙️ Disable 3D (Anti-Lag)", 9')
# Potato Graphics (11) -> (10)
text = text.replace('createButton("🥔 Potato Graphics", 11', 'createButton("🥔 Potato Graphics", 10')

# Shrink the frame height a bit since we removed one toggle (475 -> 432)
text = text.replace('mainFrame.Size = UDim2.new(0, 250, 0, 475)', 'mainFrame.Size = UDim2.new(0, 250, 0, 432)')

with open('MSTACK/isolated_megstack.lua', 'w', encoding='utf-8') as f:
    f.write(text)

print("Applied fixes!")
