import re

with open('MSTACK/isolated_megstack.lua', 'r', encoding='utf-8') as f:
    text = f.read()

# Find the start of the UI section
ui_start_match = re.search(r'-- =+[\r\n]+-- 🎨 FLUENT UI INTEGRATION[\r\n]+-- =+', text)
if not ui_start_match:
    print("Could not find start of Fluent UI section")
    exit(1)
start_idx = ui_start_match.start()

# Find the end of the UI section
ui_end_match = re.search(r'Fluent:Notify\(\{ Title = "Fishman Unified", Content = "Script loaded successfully!", Duration = 5 \}\)[\r\n]+', text[start_idx:])
if not ui_end_match:
    print("Could not find end of Fluent UI section")
    exit(1)
end_idx = start_idx + ui_end_match.end()

custom_ui_code = """-- ======================================================================
-- 🎨 CUSTOM LIGHTWEIGHT UI INTEGRATION
-- ======================================================================
getgenv().Fluent = {
    Options = {
        T_MegStackLoc = { Value = false },
        T_ManualMegStackLoc = { Value = false },
        T_AutoSpawnShip = { Value = false },
        T_AutoReconnect = { Value = GlobalMem.FishmanAutoReconnect or false },
        T_AntiLag = { Value = false },
        S_FPSCap = { Value = 35 },
        T_AutoReturn = { Value = false },
        T_MegStack = { Value = false }
    },
    Notify = function(self, args)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = args.Title or "Notification",
                Text = args.Content or "",
                Duration = args.Duration or 5
            })
        end)
    end
}

for k, v in pairs(getgenv().Fluent.Options) do
    v.SetValue = function(self, val)
        self.Value = val
        if getgenv().CustomUIToggles and getgenv().CustomUIToggles[k] then
            local btn = getgenv().CustomUIToggles[k]
            if val then
                btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                btn.Text = btn.CustomName .. " [ON]"
            else
                btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                btn.Text = btn.CustomName .. " [OFF]"
            end
        end
    end
end

local CoreGui = game:GetService("CoreGui")
local uiName = "FishmanCustomUI"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = uiName
sg.ResetOnSpawn = false
sg.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 255)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "🐟 Fishman Meg Stack"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.LayoutOrder = 1
title.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = mainFrame

getgenv().CustomUIToggles = {}

local function createToggle(id, name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 230, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    btn.Text = name .. " [OFF]"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.LayoutOrder = order
    btn.CustomName = name
    btn.Parent = mainFrame
    
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 6)
    c2.Parent = btn
    
    getgenv().CustomUIToggles[id] = btn
    
    btn.MouseButton1Click:Connect(function()
        local opt = getgenv().Fluent.Options[id]
        opt:SetValue(not opt.Value)
        if callback then
            task.spawn(callback, opt.Value)
        end
    end)
    
    getgenv().Fluent.Options[id]:SetValue(getgenv().Fluent.Options[id].Value)
    return btn
end

local function createButton(name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 230, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.LayoutOrder = order
    btn.Parent = mainFrame
    
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 6)
    c2.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        if callback then
            task.spawn(callback)
        end
    end)
    return btn
end

createToggle("T_MegStackLoc", "🎣 Auto Refill Meg Stack", 2, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot use in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_MegStackLoc:SetValue(false) end return end
    Model.State.isMegStackLoc = val
end)

createToggle("T_ManualMegStackLoc", "🎣 Manual Meg Stack", 3, function(val)
    if isLobby then if val then getgenv().Fluent:Notify({ Title = "Error", Content = "Cannot use in Lobby!", Duration = 3 }); getgenv().Fluent.Options.T_ManualMegStackLoc:SetValue(false) end return end
    
    if val then
        if getgenv().Fluent and getgenv().Fluent.Options and getgenv().Fluent.Options.T_AutoReturn and getgenv().Fluent.Options.T_AutoReturn.Value then
            getgenv().Fluent.Options.T_AutoReturn:SetValue(false)
            getgenv().Fluent:Notify({ Title = "System", Content = "Auto Return Hoverboard turned OFF for Manual Travel", Duration = 3 })
        end

        manualTravelInitialized = true
        task.spawn(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then getgenv().CachedOriginalPos = hrp.Position end
            
            Model.State.isAutoTraveling = false
            if Model.DisableFlight then Model.DisableFlight() end
            if Model.UnequipRod then Model.UnequipRod() end
            task.wait(1)
            
            if not getgenv().Fluent.Options.T_ManualMegStackLoc.Value then return end
            
            Model.State.isManualTraveling = true
            if Model.EnableFlight then Model.EnableFlight() end
            getgenv().Fluent:Notify({ Title = "Manual Travel", Content = "Flying to Meg Stack Island...", Duration = 3 })
            if Model.CraftFlyPath then Model.CraftFlyPath({ Vector3.new(-6760, 27, 9191) }) end
            
            if Model.State.isManualTraveling then
                Model.State.isManualTraveling = false
                if Model.DisableFlight then Model.DisableFlight() end
                getgenv().Fluent:Notify({ Title = "Manual Travel", Content = "Arrived at Meg Stack Island!", Duration = 3 })
            end
        end)
    else
        Model.State.isManualTraveling = false
    end
end)

createToggle("T_AutoSpawnShip", "🛳️ Auto Spawn Ship", 4, function(val)
    if val then
        if EnsureHoverboardLoaded then EnsureHoverboardLoaded() end
        if getgenv().HoverboardController and getgenv().HoverboardController.AutoSpawn then
            getgenv().HoverboardController.AutoSpawn(function()
                if getgenv().Fluent and getgenv().Fluent.Options and getgenv().Fluent.Options.T_MegStack then
                    getgenv().Fluent.Options.T_MegStack:SetValue(true)
                end
            end)
        end
    else
        if getgenv().HoverboardController then
            getgenv().HoverboardController.CancelAutoSpawn = true
        end
        if Model and Model.DisableFlight then pcall(Model.DisableFlight) end
        if getgenv().HoverboardController and getgenv().HoverboardController.Reset then
            getgenv().HoverboardController.Reset()
        end
    end
end)

createToggle("T_AntiLag", "⚙️ Disable 3D (Anti-Lag)", 5, function(val)
    RunService:Set3dRenderingEnabled(not val)
end)

createButton("🥔 Potato Graphics", 6, function()
    if ActivatePotatoGraphics then ActivatePotatoGraphics() end
end)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -35, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
minBtn.Text = "X"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = mainFrame

local minc = Instance.new("UICorner")
minc.CornerRadius = UDim.new(0, 15)
minc.Parent = minBtn

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 250, 0, 40)
        for _, child in pairs(mainFrame:GetChildren()) do
            if child:IsA("TextButton") and child ~= minBtn then
                child.Visible = false
            end
        end
        minBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        minBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 250, 0, 255)
        for _, child in pairs(mainFrame:GetChildren()) do
            if child:IsA("TextButton") and child ~= minBtn then
                child.Visible = true
            end
        end
        minBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        minBtn.Text = "X"
    end
end)

getgenv().Fishman_DestroyUI = function()
    if sg then sg:Destroy() end
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
end

getgenv().Fluent:Notify({ Title = "Fishman Custom UI", Content = "Loaded Lightweight UI!", Duration = 5 })
"""

new_text = text[:start_idx] + custom_ui_code + text[end_idx:]

with open('MSTACK/isolated_megstack.lua', 'w', encoding='utf-8') as f:
    f.write(new_text)

print("Successfully injected custom UI!")
