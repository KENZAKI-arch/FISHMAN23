import re

with open('MSTACK/isolated_megstack.lua', 'r', encoding='utf-8') as f:
    text = f.read()

# Update UI height
text = text.replace('mainFrame.Size = UDim2.new(0, 250, 0, 430)', 'mainFrame.Size = UDim2.new(0, 250, 0, 475)')
text = text.replace('mainFrame.Size = UDim2.new(0, 250, 0, 430)', 'mainFrame.Size = UDim2.new(0, 250, 0, 475)')

new_toggle = """createToggle("T_CyborgAuto", "⚔️ Cyborg Autofarm", 5, function(val)
    if isLobby then 
        if val then 
            getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot farm in Lobby!", Duration = 3 }) 
            if getgenv().Fluent.Options.T_CyborgAuto then getgenv().Fluent.Options.T_CyborgAuto:SetValue(false) end 
        end 
        return 
    end

    if val then
        if getgenv().Fluent and getgenv().Fluent.Options and getgenv().Fluent.Options.T_AutoStoreFruit then
            getgenv()._wasAutoStoreFruitOn = getgenv().Fluent.Options.T_AutoStoreFruit.Value
            if getgenv()._wasAutoStoreFruitOn then
                getgenv().Fluent.Options.T_AutoStoreFruit:SetValue(false)
                getgenv().Fluent:Notify({ Title = "System", Content = "Auto Store Fruit paused during Cyborg Autofarm", Duration = 3 })
            end
        end
    else
        if getgenv()._wasAutoStoreFruitOn and getgenv().Fluent and getgenv().Fluent.Options and getgenv().Fluent.Options.T_AutoStoreFruit then
            getgenv().Fluent.Options.T_AutoStoreFruit:SetValue(true)
            getgenv()._wasAutoStoreFruitOn = false
            getgenv().Fluent:Notify({ Title = "System", Content = "Auto Store Fruit resumed", Duration = 3 })
        end
    end

    task.spawn(function()
        if val then
            print("triggering title: \\"Megalodon Slayer\\"")
            local args = { "Megalodon Slayer" }
            pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args)) end)
        end
    end)

    if val and not getgenv().ToggleCyborgAutofarm then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/protov4_nofactory.lua"))()
        end)
        task.wait(1)
    end
    if getgenv().ToggleCyborgAutofarm then
        getgenv().ToggleCyborgAutofarm(val)
    end
end)

"""

# Adjust layout orders
# Currently: MegStack is 5, MegStackLoc is 6, Manual is 7, AutoSpawn is 8, AntiLag is 9, Potato is 10.
# Let's make CyborgAuto 6, and shift others +1.
text = text.replace('createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 6', 'createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 7')
text = text.replace('createToggle("T_ManualMegStackLoc", "🎣 Manual Meg Stack", 7', 'createToggle("T_ManualMegStackLoc", "🎣 Manual Meg Stack", 8')
text = text.replace('createToggle("T_AutoSpawnShip", "🛳️ Auto Spawn Ship", 8', 'createToggle("T_AutoSpawnShip", "🛳️ Auto Spawn Ship", 9')
text = text.replace('createToggle("T_AntiLag", "⚙️ Disable 3D (Anti-Lag)", 9', 'createToggle("T_AntiLag", "⚙️ Disable 3D (Anti-Lag)", 10')
text = text.replace('createButton("🥔 Potato Graphics", 10', 'createButton("🥔 Potato Graphics", 11')

new_toggle = new_toggle.replace('5, function(val)', '6, function(val)')

# Insert new toggle right before T_MegStackLoc
insert_idx = text.find('createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 7')
if insert_idx != -1:
    text = text[:insert_idx] + new_toggle + text[insert_idx:]
else:
    print("Could not find insertion point!")
    exit(1)

with open('MSTACK/isolated_megstack.lua', 'w', encoding='utf-8') as f:
    f.write(text)

print("Successfully injected Cyborg Auto!")
