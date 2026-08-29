import re

with open('MSTACK/isolated_megstack.lua', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace Options table
old_options = """    Options = {
        T_MegStackLoc = { Value = false },
        T_ManualMegStackLoc = { Value = false },
        T_AutoSpawnShip = { Value = false },
        T_AutoReconnect = { Value = GlobalMem.FishmanAutoReconnect or false },
        T_AntiLag = { Value = false },
        S_FPSCap = { Value = 35 },
        T_AutoReturn = { Value = false },
        T_MegStack = { Value = false }
    },"""

new_options = """    Options = {
        T_MegStackLoc = { Value = false },
        T_ManualMegStackLoc = { Value = false },
        T_AutoSpawnShip = { Value = false },
        T_AutoReconnect = { Value = GlobalMem.FishmanAutoReconnect or false },
        T_AntiLag = { Value = false },
        S_FPSCap = { Value = 35 },
        T_AutoReturn = { Value = false },
        T_MegStack = { Value = false },
        T_DeepSea = { Value = false },
        T_AFK = { Value = false },
        T_Fish = { Value = false },
        T_Buy = { Value = false },
        T_AutoStoreFruit = { Value = false },
        T_CyborgAuto = { Value = false }
    },"""
text = text.replace(old_options, new_options)

# Update UI height
text = text.replace('mainFrame.Size = UDim2.new(0, 250, 0, 255)', 'mainFrame.Size = UDim2.new(0, 250, 0, 430)')
text = text.replace('mainFrame.Size = UDim2.new(0, 250, 0, 255)', 'mainFrame.Size = UDim2.new(0, 250, 0, 430)') # Replace in unminimize

# Append the new toggles right before T_MegStackLoc (which is order 2).
# Let's adjust layout orders.
# Old: T_MegStackLoc(2), T_ManualMegStackLoc(3), T_AutoSpawnShip(4), T_AntiLag(5), Potato(6)
# New: 
# T_Fish (2)
# T_AFK (3)
# T_DeepSea (4)
# T_MegStack (5)
# T_MegStackLoc (6)
# T_ManualMegStackLoc (7)
# T_AutoSpawnShip (8)
# T_AntiLag (9)
# Potato (10)

new_toggles = """createToggle("T_Fish", "🎣 Auto Fish", 2, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot fish in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_Fish:SetValue(false) end return end
    Model.State.isFishing = val 
end)

createToggle("T_AFK", "⏰ AFK Mode (Auto-start 10s)", 3, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "AFK Mode requires Fishing server!", Duration = 3 }); getgenv().Fluent.Options.T_AFK:SetValue(false) end return end
    isAFKModeActive = val; secondsSinceLastInput = 0 
end)

createToggle("T_DeepSea", "🐙 Deep Sea Catcher (Beasts)", 4, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot fish in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_DeepSea:SetValue(false) end return end
    task.spawn(function()
        if val then
            print("triggering title: \\"Skilled Fisherman\\"")
            local args = { "Skilled Fisherman" }
            pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args)) end)
        end
    end)
    Model.State.isDeepSeaCatcher = val 
end)

createToggle("T_MegStack", "🦈 Megalodon Stack", 5, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot stack in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_MegStack:SetValue(false) end return end
    Model.State.isMegStacking = val
    if val then
        if getgenv().Fluent.Options.T_DeepSea then getgenv().Fluent.Options.T_DeepSea:SetValue(true) end
        if getgenv().Fluent.Options.T_Buy then getgenv().Fluent.Options.T_Buy:SetValue(true) end
        if getgenv().Fluent.Options.T_MegStackLoc then getgenv().Fluent.Options.T_MegStackLoc:SetValue(true) end
        if getgenv().Fluent.Options.T_AutoStoreFruit then getgenv().Fluent.Options.T_AutoStoreFruit:SetValue(true) end
        if getgenv().Fluent.Options.T_AutoReturn then getgenv().Fluent.Options.T_AutoReturn:SetValue(true) end
        print("🌊 [MegStack] Meg stack starting now! Enabling deep sea catcher for 10 megalodons.")
        task.spawn(function()
            while Model.State.isMegStacking do
                local megCount = Model.countMegalodons and Model.countMegalodons() or 0
                if megCount >= 10 and not Model.State.isBuying and not Model.State.isAutoTraveling and not Model.State.isRefillingMegBait and not Model.State.isManualTraveling then
                    print("🔥 [MegStack] 10 Megalodons reached! Disabling fishing and automatically toggling Cyborg Autofarm ON...")
                    if getgenv().Fluent.Options.T_DeepSea.Value == true then getgenv().Fluent.Options.T_DeepSea:SetValue(false) end
                    if getgenv().Fluent.Options.T_CyborgAuto then getgenv().Fluent.Options.T_CyborgAuto:SetValue(true) end
                    
                    local waitTime = 0
                    local lastCount = Model.countMegalodons and Model.countMegalodons() or 0
                    while Model.countMegalodons and Model.countMegalodons() > 0 and Model.State.isMegStacking and waitTime < 180 do
                        task.wait(1)
                        waitTime = waitTime + 1
                        local curCount = Model.countMegalodons()
                        if curCount < lastCount then
                            waitTime = 0
                            lastCount = curCount
                        end
                    end
                    
                    print("✅ [MegStack] Stack cleared! Toggling Cyborg Autofarm OFF and resuming fishing...")
                    if getgenv().Fluent.Options.T_CyborgAuto then getgenv().Fluent.Options.T_CyborgAuto:SetValue(false) end
                    if Model.State.isMegStacking then getgenv().Fluent.Options.T_DeepSea:SetValue(true) end
                end
                task.wait(1)
            end
        end)
    else
        print("🛑 [MegStack] Stacking aborted. Shutting down deep sea catcher.")
        if getgenv().Fluent.Options.T_DeepSea and getgenv().Fluent.Options.T_DeepSea.Value == true then getgenv().Fluent.Options.T_DeepSea:SetValue(false) end
        if getgenv().Fluent.Options.T_AutoStoreFruit and getgenv().Fluent.Options.T_AutoStoreFruit.Value == true then getgenv().Fluent.Options.T_AutoStoreFruit:SetValue(false) end
        if getgenv().Fluent.Options.T_AutoReturn and getgenv().Fluent.Options.T_AutoReturn.Value == true then getgenv().Fluent.Options.T_AutoReturn:SetValue(false) end
    end
end)

"""

# Change layout orders of the existing toggles
text = text.replace('createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 2', 'createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 6')
text = text.replace('createToggle("T_ManualMegStackLoc", "🎣 Manual Meg Stack", 3', 'createToggle("T_ManualMegStackLoc", "🎣 Manual Meg Stack", 7')
text = text.replace('createToggle("T_AutoSpawnShip", "🛳️ Auto Spawn Ship", 4', 'createToggle("T_AutoSpawnShip", "🛳️ Auto Spawn Ship", 8')
text = text.replace('createToggle("T_AntiLag", "⚙️ Disable 3D (Anti-Lag)", 5', 'createToggle("T_AntiLag", "⚙️ Disable 3D (Anti-Lag)", 9')
text = text.replace('createButton("🥔 Potato Graphics", 6', 'createButton("🥔 Potato Graphics", 10')

# Insert the new toggles
insert_idx = text.find('createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 6')
if insert_idx != -1:
    text = text[:insert_idx] + new_toggles + text[insert_idx:]
else:
    print("Could not find insertion point!")
    exit(1)

with open('MSTACK/isolated_megstack.lua', 'w', encoding='utf-8') as f:
    f.write(text)

print("Successfully injected new toggles!")
