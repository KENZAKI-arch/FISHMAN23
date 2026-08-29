import re

with open('MSTACK/isolated_megstack.lua', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update SetValue to run callback
old_setvalue = """for k, v in pairs(getgenv().Fluent.Options) do
    v.SetValue = function(self, val)
        self.Value = val
        if getgenv().CustomUIToggles and getgenv().CustomUIToggles[k] then
            local data = getgenv().CustomUIToggles[k]
            local btn = data.Button
            if val then
                btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                btn.Text = data.CustomName .. " [ON]"
            else
                btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                btn.Text = data.CustomName .. " [OFF]"
            end
        end
    end
end"""

new_setvalue = """for k, v in pairs(getgenv().Fluent.Options) do
    v.SetValue = function(self, val)
        -- Only trigger callback if the value actually changed
        local changed = (self.Value ~= val)
        self.Value = val
        
        if getgenv().CustomUIToggles and getgenv().CustomUIToggles[k] then
            local data = getgenv().CustomUIToggles[k]
            local btn = data.Button
            if val then
                btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                btn.Text = data.CustomName .. " [ON]"
            else
                btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                btn.Text = data.CustomName .. " [OFF]"
            end
            
            if changed and data.Callback then
                task.spawn(data.Callback, val)
            end
        end
    end
end"""
text = text.replace(old_setvalue, new_setvalue)

# 2. Update createToggle to save Callback and remove redundant call
old_createtoggle = """    getgenv().CustomUIToggles[id] = { Button = btn, CustomName = name }
    
    btn.MouseButton1Click:Connect(function()
        local opt = getgenv().Fluent.Options[id]
        opt:SetValue(not opt.Value)
        if callback then
            task.spawn(callback, opt.Value)
        end
    end)
    
    getgenv().Fluent.Options[id]:SetValue(getgenv().Fluent.Options[id].Value)
    return btn"""

new_createtoggle = """    getgenv().CustomUIToggles[id] = { Button = btn, CustomName = name, Callback = callback }
    
    btn.MouseButton1Click:Connect(function()
        local opt = getgenv().Fluent.Options[id]
        opt:SetValue(not opt.Value)
    end)
    
    -- Sync initial value (this triggers the callback once during setup)
    getgenv().Fluent.Options[id]:SetValue(getgenv().Fluent.Options[id].Value)
    return btn"""
text = text.replace(old_createtoggle, new_createtoggle)


with open('MSTACK/isolated_megstack.lua', 'w', encoding='utf-8') as f:
    f.write(text)

print("Applied callback fixes!")
