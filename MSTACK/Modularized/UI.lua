-- UI & Layout

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or shared
local GlobalMem = env

-- Bind state variables locally for ease of use in this file
local _running = getgenv().FishmanState._running
local _connections = getgenv().FishmanState._connections
local Tabs = getgenv().FishmanState.Tabs
local Fluent = getgenv().FishmanState.Fluent
local addConn = getgenv().FishmanState.addConn
local disconnectAll = getgenv().FishmanState.disconnectAll
local TriggerSafeguardShutdown = getgenv().FishmanState.TriggerSafeguardShutdown
local SaveConfig = getgenv().FishmanState.SaveConfig
local isLobby = getgenv().FishmanState.isLobby


-- ======================================================================
-- 🎨 CUSTOM LIGHTWEIGHT UI INTEGRATION
-- ======================================================================
Fluent = { Options = {} }
getgenv().FishmanState.Fluent = Fluent

function Fluent:Notify(options)
    task.spawn(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "FishmanNotify"
        sg.Parent = game:GetService("CoreGui")
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 200, 0, 50)
        frame.Position = UDim2.new(1, -210, 1, -60)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
        frame.Parent = sg
        
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, -10, 1, -10)
        txt.Position = UDim2.new(0, 5, 0, 5)
        txt.BackgroundTransparency = 1
        txt.Text = (options.Title or "") .. "\n" .. (options.Content or "")
        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.TextYAlignment = Enum.TextYAlignment.Top
        txt.Font = Enum.Font.Code
        txt.TextSize = 12
        txt.TextWrapped = true
        txt.Parent = frame
        
        task.wait(options.Duration or 3)
        sg:Destroy()
    end)
end

function Fluent:CreateWindow(options)
    local FakeWindow = {}
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "FishmanHubCustom"
    sg.Parent = game:GetService("CoreGui")
    
    FakeWindow.Destroy = function(self) sg:Destroy() end
    env.Fishman_DestroyUI = function() pcall(function() FakeWindow:Destroy() end) end
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
    mainFrame.Active = true
    mainFrame.Parent = sg
    
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 25)
    topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 5, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = (options.Title or "Hub") .. " | " .. (options.SubTitle or "")
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.Code
    titleLabel.TextSize = 12
    titleLabel.Parent = topBar
    
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 25, 0, 25)
    minBtn.Position = UDim2.new(1, -50, 0, 0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minBtn.Font = Enum.Font.Code
    minBtn.TextSize = 14
    minBtn.Parent = topBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -25, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
    closeBtn.Font = Enum.Font.Code
    closeBtn.TextSize = 14
    closeBtn.Parent = topBar
    
    local isMinimized = false
    local function toggleMinimize()
        isMinimized = not isMinimized
        mainFrame.Size = UDim2.new(0, 500, 0, isMinimized and 25 or 350)
        for _, c in ipairs(mainFrame:GetChildren()) do
            if c ~= topBar and c.Name ~= "UICorner" then c.Visible = not isMinimized end
        end
    end
    minBtn.MouseButton1Click:Connect(toggleMinimize)
    closeBtn.MouseButton1Click:Connect(function() FakeWindow:Destroy() end)
    
    if options.MinimizeKey then
        game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == options.MinimizeKey then
                toggleMinimize()
            end
        end)
    end
    
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = mainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(0, 120, 1, -25)
    tabContainer.Position = UDim2.new(0, 0, 0, 25)
    tabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 2
    tabContainer.Parent = mainFrame
    local tabLayout = Instance.new("UIListLayout", tabContainer)
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() tabContainer.CanvasSize = UDim2.new(0,0,0,tabLayout.AbsoluteContentSize.Y) end)

    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -120, 1, -25)
    contentContainer.Position = UDim2.new(0, 120, 0, 25)
    contentContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame

    local tabsList = {}
    local activeTabBtn, activeContent = nil, nil

    function FakeWindow:AddTab(tabArgs)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 25)
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tabBtn.BorderSizePixel = 1
        tabBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
        tabBtn.Text = tabArgs.Title
        tabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        tabBtn.Font = Enum.Font.Code
        tabBtn.TextSize = 12
        tabBtn.Parent = tabContainer
        
        local contentScroll = Instance.new("ScrollingFrame")
        contentScroll.Size = UDim2.new(1, -10, 1, -10)
        contentScroll.Position = UDim2.new(0, 5, 0, 5)
        contentScroll.BackgroundTransparency = 1
        contentScroll.BorderSizePixel = 0
        contentScroll.ScrollBarThickness = 2
        contentScroll.Visible = false
        contentScroll.Parent = contentContainer
        local contentLayout = Instance.new("UIListLayout", contentScroll)
        contentLayout.Padding = UDim.new(0, 2)
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() contentScroll.CanvasSize = UDim2.new(0,0,0,contentLayout.AbsoluteContentSize.Y) end)
        
        tabBtn.MouseButton1Click:Connect(function()
            if activeTabBtn then activeTabBtn.TextColor3 = Color3.fromRGB(150, 150, 150); activeContent.Visible = false end
            activeTabBtn = tabBtn; activeContent = contentScroll
            tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            contentScroll.Visible = true
        end)
        if not activeTabBtn then tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255); activeTabBtn = tabBtn; activeContent = contentScroll; contentScroll.Visible = true end
        
        local FakeTab = {}
        table.insert(tabsList, { Btn = tabBtn, Content = contentScroll })
        
        function FakeTab:AddToggle(id, tArgs)
            local isTable = type(id) == "table"; if isTable then tArgs = id; id = nil end
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            btn.BorderSizePixel = 0
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = Enum.Font.Code
            btn.TextSize = 12
            btn.Parent = contentScroll
            
            local FakeToggle = { Value = tArgs.Default or false }
            local function update()
                btn.Text = " " .. (FakeToggle.Value and "[ON] " or "[OFF] ") .. tArgs.Title
                btn.TextColor3 = FakeToggle.Value and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 100, 100)
                if tArgs.Callback then task.spawn(tArgs.Callback, FakeToggle.Value) end
            end
            btn.MouseButton1Click:Connect(function() FakeToggle.Value = not FakeToggle.Value; update() end)
            FakeToggle.SetValue = function(self, val) self.Value = val; update() end
            if not isTable and id then getgenv().FishmanState.Fluent.Options[id] = FakeToggle end
            update(); return FakeToggle
        end
        
        function FakeTab:AddButton(bArgs)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            btn.BorderSizePixel = 0
            btn.Text = " > " .. bArgs.Title
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = Enum.Font.Code
            btn.TextSize = 12
            btn.Parent = contentScroll
            btn.MouseButton1Click:Connect(function() if bArgs.Callback then task.spawn(bArgs.Callback) end end)
        end
        
        function FakeTab:AddSlider(id, sArgs)
            local isTable = type(id) == "table"; if isTable then sArgs = id; id = nil end
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 32)
            frame.BackgroundTransparency = 1
            frame.Parent = contentScroll
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -5, 0, 16)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Font = Enum.Font.Code
            lbl.TextSize = 12
            lbl.Parent = frame
            local bg = Instance.new("TextButton")
            bg.Size = UDim2.new(1, -10, 0, 10)
            bg.Position = UDim2.new(0, 5, 0, 18)
            bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            bg.Text = ""; bg.AutoButtonColor = false
            bg.Parent = frame
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            fill.BorderSizePixel = 0
            fill.Parent = bg
            
            local FakeSlider = { Value = sArgs.Default or sArgs.Min }
            local function update(val)
                val = math.clamp(val, sArgs.Min, sArgs.Max)
                FakeSlider.Value = val
                lbl.Text = " " .. sArgs.Title .. ": " .. tostring(val)
                fill.Size = UDim2.new((val - sArgs.Min) / (sArgs.Max - sArgs.Min), 0, 1, 0)
                if sArgs.Callback then task.spawn(sArgs.Callback, val) end
            end
            local dragging = false
            bg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
            game:GetService("UserInputService").InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
            game:GetService("UserInputService").InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local pct = math.clamp(input.Position.X - bg.AbsolutePosition.X, 0, bg.AbsoluteSize.X) / bg.AbsoluteSize.X
                    local step = sArgs.Rounding and (10 ^ -sArgs.Rounding) or 1
                    update(math.floor((sArgs.Min + (sArgs.Max - sArgs.Min) * pct) / step + 0.5) * step)
                end
            end)
            FakeSlider.SetValue = function(self, val) update(val) end
            if not isTable and id then getgenv().FishmanState.Fluent.Options[id] = FakeSlider end
            update(FakeSlider.Value); return FakeSlider
        end
        
        function FakeTab:AddDropdown(id, dArgs)
            local isTable = type(id) == "table"; if isTable then dArgs = id; id = nil end
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 22)
            frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            frame.BorderSizePixel = 0
            frame.ClipsDescendants = true
            frame.Parent = contentScroll
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundTransparency = 1
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = Enum.Font.Code
            btn.TextSize = 12
            btn.Parent = frame
            local list = Instance.new("ScrollingFrame")
            list.Size = UDim2.new(1, 0, 0, 80)
            list.Position = UDim2.new(0, 0, 0, 22)
            list.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            list.BorderSizePixel = 0
            list.ScrollBarThickness = 2
            list.Parent = frame
            local listLayout = Instance.new("UIListLayout", list)
            
            local isOpen = false
            btn.MouseButton1Click:Connect(function() isOpen = not isOpen; frame.Size = UDim2.new(1, 0, 0, isOpen and 102 or 22) end)
            
            local initVal = dArgs.Default
            if type(initVal) == "number" and not dArgs.Multi and dArgs.Values and dArgs.Values[initVal] then
                initVal = dArgs.Values[initVal]
            end
            local FakeDrop = { Value = initVal or (dArgs.Multi and {} or "") }
            local function populate(vals)
                for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _, v in ipairs(vals) do
                    local opt = Instance.new("TextButton")
                    opt.Size = UDim2.new(1, 0, 0, 20)
                    opt.BackgroundTransparency = 1
                    opt.Text = "  " .. tostring(v)
                    opt.TextColor3 = Color3.fromRGB(150, 150, 150)
                    opt.TextXAlignment = Enum.TextXAlignment.Left
                    opt.Font = Enum.Font.Code
                    opt.TextSize = 11
                    opt.Parent = list
                    local function updateVis()
                        if dArgs.Multi then
                            local f = false; for _, sv in ipairs(FakeDrop.Value) do if sv == v then f = true break end end
                            opt.TextColor3 = f and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 150)
                        else
                            opt.TextColor3 = (FakeDrop.Value == v) and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 150)
                        end
                    end
                    opt.MouseButton1Click:Connect(function()
                        if dArgs.Multi then
                            local fIdx = nil; for i, sv in ipairs(FakeDrop.Value) do if sv == v then fIdx = i break end end
                            if fIdx then table.remove(FakeDrop.Value, fIdx) else table.insert(FakeDrop.Value, v) end
                        else
                            FakeDrop.Value = v; isOpen = false; frame.Size = UDim2.new(1, 0, 0, 22)
                        end
                        btn.Text = " ▼ " .. dArgs.Title .. ": " .. (dArgs.Multi and #FakeDrop.Value .. " selected" or tostring(FakeDrop.Value))
                        for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c.TextColor3 = Color3.fromRGB(150, 150, 150) end end
                        updateVis()
                        if dArgs.Callback then task.spawn(dArgs.Callback, FakeDrop.Value) end
                    end)
                    updateVis()
                end
                list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
            end
            FakeDrop.SetValues = function(self, vals) populate(vals) end
            FakeDrop.SetValue = function(self, val)
                self.Value = val
                btn.Text = " ▼ " .. dArgs.Title .. ": " .. (dArgs.Multi and type(self.Value) == "table" and #self.Value .. " selected" or tostring(self.Value))
                if dArgs.Callback then task.spawn(dArgs.Callback, self.Value) end
            end
            if not isTable and id then getgenv().FishmanState.Fluent.Options[id] = FakeDrop end
            populate(dArgs.Values or {})
            btn.Text = " ▼ " .. dArgs.Title .. ": " .. (dArgs.Multi and type(FakeDrop.Value) == "table" and #FakeDrop.Value .. " selected" or tostring(FakeDrop.Value))
            if initVal and dArgs.Callback then task.spawn(dArgs.Callback, initVal) end
            return FakeDrop
        end
        
        function FakeTab:AddParagraph(id, pArgs)
            local isTable = type(id) == "table"; if isTable then pArgs = id; id = nil end
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 30)
            lbl.BackgroundTransparency = 1
            lbl.Text = " " .. (pArgs.Title or "") .. "\n " .. (pArgs.Content or "")
            lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextYAlignment = Enum.TextYAlignment.Top
            lbl.Font = Enum.Font.Code
            lbl.TextSize = 11
            lbl.TextWrapped = true
            lbl.Parent = contentScroll
            local FakePara = {}
            function FakePara:SetDesc(txt) lbl.Text = " " .. (pArgs.Title or "") .. "\n " .. txt end
            return FakePara
        end
        
        function FakeTab:AddInput(id, iArgs)
            local isTable = type(id) == "table"; if isTable then iArgs = id; id = nil end
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 22)
            frame.BackgroundTransparency = 1
            frame.Parent = contentScroll
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = " " .. iArgs.Title
            lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Font = Enum.Font.Code
            lbl.TextSize = 12
            lbl.Parent = frame
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0.5, -5, 1, 0)
            box.Position = UDim2.new(0.5, 0, 0, 0)
            box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            box.BorderSizePixel = 1
            box.BorderColor3 = Color3.fromRGB(50, 50, 50)
            box.Text = iArgs.Default or ""
            box.TextColor3 = Color3.fromRGB(255, 255, 255)
            box.Font = Enum.Font.Code
            box.TextSize = 12
            box.Parent = frame
            
            local FakeInput = { Value = iArgs.Default or "" }
            box.FocusLost:Connect(function() FakeInput.Value = box.Text; if iArgs.Callback then task.spawn(iArgs.Callback, box.Text) end end)
            FakeInput.SetValue = function(self, val) self.Value = val; box.Text = val; if iArgs.Callback then task.spawn(iArgs.Callback, val) end end
            if not isTable and id then getgenv().FishmanState.Fluent.Options[id] = FakeInput end
            return FakeInput
        end
        
        return FakeTab
    end
    
    function FakeWindow:SelectTab(idx)
        local target = tabsList[idx]
        if target then
            if activeTabBtn then activeTabBtn.TextColor3 = Color3.fromRGB(150, 150, 150); activeContent.Visible = false end
            activeTabBtn = target.Btn; activeContent = target.Content
            activeTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            activeContent.Visible = true
        end
    end
    
    return FakeWindow
end

local Window = getgenv().FishmanState.Fluent:CreateWindow({
    Title = "🐟 Fishman Hub",
    SubTitle = "Unified Auto-Fisher 1.0.3 v4.2",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Prevent game from detecting UI actions or internal UI errors (Anti-Cheat bypass)
pcall(function()
    if getconnections then
        for _, conn in pairs(getconnections(game:GetService("UserInputService").WindowFocusReleased)) do
            conn:Disable()
        end
        for _, conn in pairs(getconnections(game:GetService("LogService").MessageOut)) do
            conn:Disable()
        end
        for _, conn in pairs(getconnections(game:GetService("ScriptContext").Error)) do
            conn:Disable()
        end
    end
    game:GetService("ContextActionService"):UnbindAction("FluentMinimize")
end)

Tabs = {
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "plane" }),
    Navigation = Window:AddTab({ Title = "Navigation", Icon = "map" }),
    Fishing = Window:AddTab({ Title = "Fishing", Icon = "anchor" }),
    Autofarm = Window:AddTab({ Title = "Autofarm", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
getgenv().FishmanState.Tabs = Tabs

-- ======================================================================
-- 🗺️ TELEPORT TAB UI
-- ======================================================================
    local UI_Loaded = false
    getgenv().FishmanState.Tabs.Teleport:AddInput("Input", {
        Title = "Private Server Code",
        Default = GlobalMem.FishmanPSCode,
        Placeholder = "Enter PS Code",
        Numeric = false,
        Finished = false,
        Callback = function(Value)
            GlobalMem.FishmanPSCode = Value
            if Value and Value ~= "" and not table.find(GlobalMem.FishmanPSCodeHistory, Value) then
                table.insert(GlobalMem.FishmanPSCodeHistory, 1, Value)
                while #GlobalMem.FishmanPSCodeHistory > 10 do
                    table.remove(GlobalMem.FishmanPSCodeHistory, #GlobalMem.FishmanPSCodeHistory)
                end
                if getgenv().FishmanState.Fluent.Options.D_PSCodeHistory then
                    getgenv().FishmanState.Fluent.Options.D_PSCodeHistory:SetValues(GlobalMem.FishmanPSCodeHistory)
                end
            end
            if UI_Loaded then
                GlobalMem.FishmanAutoRouteLobby = false
                if getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby then getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby:SetValue(false) end
            end
            getgenv().FishmanState.SaveConfig()
        end
    })

    getgenv().FishmanState.Tabs.Teleport:AddDropdown("D_PSCodeHistory", {
        Title = "PS Code History",
        Description = "Click to select a saved PS code",
        Values = GlobalMem.FishmanPSCodeHistory,
        Multi = false,
        Default = GlobalMem.FishmanPSCode,
        Callback = function(Value)
            if Value and Value ~= "" then
                GlobalMem.FishmanPSCode = Value
                if UI_Loaded then
                    GlobalMem.FishmanAutoRouteLobby = false
                    if getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby then getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby:SetValue(false) end
                end
                getgenv().FishmanState.SaveConfig()
                if getgenv().FishmanState.Fluent.Options.Input and getgenv().FishmanState.Fluent.Options.Input.Value ~= Value then
                    getgenv().FishmanState.Fluent.Options.Input:SetValue(Value)
                end
            end
        end
    })

    getgenv().FishmanState.Tabs.Teleport:AddDropdown("Dropdown", {
        Title = "Destination",
        Values = {"fishHub", "tradeHub", "First Sea", "Second Sea", "Lobby"},
        Multi = false,
        Default = (table.find({"fishHub", "tradeHub", "First Sea", "Second Sea", "Lobby"}, GlobalMem.FishmanDestination) or 2),
        Callback = function(Value)
            GlobalMem.FishmanDestination = Value
            if UI_Loaded then
                GlobalMem.FishmanAutoRouteLobby = false
                if getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby then getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby:SetValue(false) end
            end
            getgenv().FishmanState.SaveConfig()
        end
    })

    getgenv().FishmanState.Tabs.Teleport:AddToggle("T_AutoRouteLobby", {
        Title = "Auto-Route from Lobby on Join",
        Description = "Automatically teleport to your chosen Destination & PS Code when entering Lobby",
        Default = GlobalMem.FishmanAutoRouteLobby,
        Callback = function(Value)
            GlobalMem.FishmanAutoRouteLobby = Value
            getgenv().FishmanState.SaveConfig()
        end
    })

    local function ExecuteTeleport(destination, psCode)
        if getgenv().FishmanState.UpdateTeleportMemory then getgenv().FishmanState.UpdateTeleportMemory(GlobalMem.FishmanAutoTeleport) end
        if isLobby then
            if destination == "Lobby" then
                getgenv().FishmanState.Fluent:Notify({ Title = "Lobby", Content = "You are already in the Lobby!", Duration = 3 })
                return
            end
            if psCode and psCode ~= "" and game.PrivateServerId == "" then
                task.spawn(function()
                    local events = ReplicatedStorage:WaitForChild("Events", 9e9)
                    local reserved = events:WaitForChild("reserved", 9e9)
                    pcall(function() reserved:InvokeServer(psCode) end)
                end)
                task.wait(5) 
            end
            
            local confirmArgs = { [1] = destination }
            pcall(function()
                if destination == "Lobby" then
                    TeleportService:Teleport(getgenv().FishmanState.targetPlaceId, LocalPlayer)
                else
                    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 20)
                    local chooseType = playerGui:WaitForChild("chooseType", 20)
                    local frame = chooseType:WaitForChild("Frame", 20)
                    local remoteEvent = frame:WaitForChild("RemoteEvent", 20)
                    
                    if destination == "Second Sea" or destination == "First Sea" then
                        print("Teleporting to " .. destination .. "...")
                        if not game:IsLoaded() then
                            game.Loaded:Wait()
                        end

                        -- Step 1: Open sea selection menu
                        local args1 = {
                            [1] = true;
                        }
                        remoteEvent:FireServer(unpack(args1))

                        task.wait(0.5)

                        -- Step 2: Confirm on ConfirmationPrompt
                        local args2 = {
                            [1] = destination;
                        }
                        local confirmationPrompt = LocalPlayer:WaitForChild("PlayerGui", 9e9):WaitForChild("ConfirmationPrompt", 9e9)
                        confirmationPrompt:WaitForChild("RemoteEvent", 9e9):FireServer(unpack(args2))
                    else
                        remoteEvent:FireServer(unpack(confirmArgs))
                    end
                end
            end)
        else
            TeleportService:Teleport(getgenv().FishmanState.targetPlaceId, LocalPlayer)
        end
    end

    getgenv().FishmanState.Tabs.Teleport:AddButton({
        Title = "🚀 Teleport Now!",
        Description = "Teleports you to the selected destination.",
        Callback = function()
            if GlobalMem.FishmanPSCode and GlobalMem.FishmanPSCode ~= "" then
                if not table.find(GlobalMem.FishmanPSCodeHistory, GlobalMem.FishmanPSCode) then
                    table.insert(GlobalMem.FishmanPSCodeHistory, 1, GlobalMem.FishmanPSCode)
                    while #GlobalMem.FishmanPSCodeHistory > 10 do
                        table.remove(GlobalMem.FishmanPSCodeHistory, #GlobalMem.FishmanPSCodeHistory)
                    end
                    if getgenv().FishmanState.Fluent.Options.D_PSCodeHistory then
                        getgenv().FishmanState.Fluent.Options.D_PSCodeHistory:SetValues(GlobalMem.FishmanPSCodeHistory)
                    end
                end
            end
            GlobalMem.FishmanAutoTeleport = true
            GlobalMem.FishmanAutoRouteLobby = false
            if getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby then getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby:SetValue(false) end
            getgenv().FishmanState.SaveConfig()
            ExecuteTeleport(GlobalMem.FishmanDestination, GlobalMem.FishmanPSCode)
        end
    })

    getgenv().FishmanState.Tabs.Teleport:AddButton({
        Title = "🏠 Return to Default Config",
        Description = "Instantly teleports you to your loader's starting PS Code and Destination.",
        Callback = function()
            local defaultPS = GlobalMem.FishmanDefaultPSCode or "qj1ttW4JG1"
            local defaultDest = GlobalMem.FishmanDefaultDestination or "Second Sea"
            
            GlobalMem.FishmanPSCode = defaultPS
            GlobalMem.FishmanDestination = defaultDest
            GlobalMem.FishmanAutoTeleport = true
            GlobalMem.FishmanAutoRouteLobby = false
            if getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby then getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby:SetValue(false) end
            getgenv().FishmanState.SaveConfig()
            
            if getgenv().FishmanState.Fluent.Options.Input then getgenv().FishmanState.Fluent.Options.Input:SetValue(defaultPS) end
            if getgenv().FishmanState.Fluent.Options.Dropdown then getgenv().FishmanState.Fluent.Options.Dropdown:SetValue(defaultDest) end
            
            getgenv().FishmanState.Fluent:Notify({ Title = "Routing to Default", Content = "Initiating warp to " .. tostring(defaultDest) .. "...", Duration = 3 })
            
            ExecuteTeleport(defaultDest, defaultPS)
        end
    })

    getgenv().FishmanState.Tabs.Teleport:AddButton({
        Title = "📈 Trade Hub",
        Description = "Instantly teleports you to tradeHub in private server qj1ttW4JG1.",
        Callback = function()
            GlobalMem.FishmanPSCode = "qj1ttW4JG1"
            GlobalMem.FishmanDestination = "tradeHub"
            GlobalMem.FishmanAutoTeleport = true
            GlobalMem.FishmanAutoRouteLobby = false
            if getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby then getgenv().FishmanState.Fluent.Options.T_AutoRouteLobby:SetValue(false) end
            getgenv().FishmanState.SaveConfig()
            
            if getgenv().FishmanState.Fluent.Options.Input then getgenv().FishmanState.Fluent.Options.Input:SetValue("qj1ttW4JG1") end
            if getgenv().FishmanState.Fluent.Options.Dropdown then getgenv().FishmanState.Fluent.Options.Dropdown:SetValue("tradeHub") end

            getgenv().FishmanState.Fluent:Notify({ Title = "Trade Hub", Content = "Initiating warp to Trade Hub (qj1ttW4JG1)...", Duration = 3 })
            
            ExecuteTeleport("tradeHub", "qj1ttW4JG1")
        end
    })

    UI_Loaded = true

    -- Check if we should automatically route
    if isLobby then
        local destCode = GlobalMem.FishmanPSCode
        local destPlace = GlobalMem.FishmanDestination
        local shouldTeleport = false
        
        local isContinuingTeleport = GlobalMem.FishmanAutoTeleport
        if GlobalMem.FishmanAutoTeleport then
            GlobalMem.FishmanAutoTeleport = false
            getgenv().FishmanState.SaveConfig()
            if destPlace == "Lobby" then
                getgenv().FishmanState.Fluent:Notify({ Title = "Arrived at Lobby", Content = "You have arrived at the Lobby.", Duration = 3 })
                isContinuingTeleport = false
            else
                getgenv().FishmanState.Fluent:Notify({ Title = "Auto-Teleporting", Content = "Routing to chosen destination in 3s...", Duration = 3 })
                shouldTeleport = true
            end
        elseif GlobalMem.FishmanAutoRouteLobby then
            if destPlace == "Lobby" then
                getgenv().FishmanState.Fluent:Notify({ Title = "Lobby", Content = "Destination is set to Lobby. Staying here.", Duration = 3 })
            else
                getgenv().FishmanState.Fluent:Notify({ Title = "Auto-Route", Content = "Routing to " .. tostring(destPlace) .. " in 3s...", Duration = 3 })
                shouldTeleport = true
            end
        else
            getgenv().FishmanState.Fluent:Notify({ Title = "Lobby", Content = "Auto-Route is OFF. Staying in Lobby.", Duration = 3 })
        end
        
        if shouldTeleport then
            task.spawn(function()
                task.wait(3)
                if isContinuingTeleport or GlobalMem.FishmanAutoTeleport or GlobalMem.FishmanAutoRouteLobby then
                    ExecuteTeleport(GlobalMem.FishmanDestination, GlobalMem.FishmanPSCode)
                else
                    getgenv().FishmanState.Fluent:Notify({ Title = "Auto-Route Cancelled", Content = "Manual interaction detected. Auto-Route aborted.", Duration = 3 })
                end
            end)
        end
    end

-- ======================================================================
-- 🚀 HOVERBOARD UI
-- ======================================================================

getgenv().FishmanState.Tabs.Teleport:AddInput("I_HoverHeight", {
    Title = "Flight Altitude",
    Default = "440",
    Placeholder = "Enter Altitude...",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local height = tonumber(Value) or 440
        getgenv().HoverboardTargetHeight = height
        if getgenv().HoverboardController and getgenv().HoverboardController.SetHeightValue then
            getgenv().HoverboardController.SetHeightValue(height)
        end
    end
})

local function EnsureHoverboardLoaded()
    if not getgenv().HoverboardController then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/hoverboardfloat.lua?t="..tostring(tick())))()
        end)
        task.wait(1)
        if getgenv().HoverboardController and getgenv().HoverboardTargetHeight then
            getgenv().HoverboardController.SetHeightValue(getgenv().HoverboardTargetHeight)
        end
    end
end

getgenv().FishmanState.Tabs.Teleport:AddButton({
    Title = "🚀 Set Flight Height",
    Description = "Lifts your hoverboard to the target altitude.",
    Callback = function()
        print("[Hub] 'Set Flight Height' clicked!")
        EnsureHoverboardLoaded()
        if getgenv().HoverboardController and getgenv().HoverboardController.SetHeight then
            print("[Hub] Calling HoverboardController.SetHeight()...")
            getgenv().HoverboardController.SetHeight()
        else
            print("[Hub] ERROR: HoverboardController.SetHeight not found!")
        end
    end
})

local function isAtWholeCakeIsland()
    local result = false
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local wci = workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild("Whole Cake Island")
        if hrp and wci then
            local part = wci:IsA("Model") and wci.PrimaryPart or wci:FindFirstChildWhichIsA("BasePart", true)
            if part and (hrp.Position - part.Position).Magnitude < 4000 then
                result = true
            end
        end
    end)
    return result
end

getgenv().FishmanState.Tabs.Teleport:AddToggle("T_AutoSpawnShip", {
    Title = "🛳️ Auto Spawn Ship",
    Description = "Flies to spawn, spawns hoverboard, and sets flight height.",
    Default = (GlobalMem.FishmanAutoSpawnShip == true),
    Callback = function(Value)
        GlobalMem.FishmanAutoSpawnShip = Value
        getgenv().FishmanState.SaveConfig()
        print("[Hub] 'Auto Spawn Ship' toggled " .. tostring(Value))
        if Value then
            EnsureHoverboardLoaded()
            if getgenv().HoverboardController and getgenv().HoverboardController.AutoSpawn then
                print("[Hub] Calling HoverboardController.AutoSpawn()...")
                getgenv().HoverboardController.AutoSpawn(function()
                    if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_MegStack then
                        print("[Hub] Automatically enabling Megalodon Stack after final move...")
                        getgenv().FishmanState.Fluent.Options.T_MegStack:SetValue(true)
                    end
                end)
            else
                print("[Hub] ERROR: HoverboardController.AutoSpawn not found!")
            end
        else
            if getgenv().HoverboardController then
                getgenv().HoverboardController.CancelAutoSpawn = true
            end
            if getgenv().FishmanState.Model and getgenv().FishmanState.Model.DisableFlight then
                pcall(getgenv().FishmanState.Model.DisableFlight)
            end
            if getgenv().HoverboardController and getgenv().HoverboardController.Reset then
                print("[Hub] Calling HoverboardController.Reset() to drop...")
                getgenv().HoverboardController.Reset()
            end
        end
    end
})

getgenv().FishmanState.Tabs.Teleport:AddButton({
    Title = "⬇️ Reset to Normal",
    Description = "Restores normal hoverboard physics.",
    Callback = function()
        print("[Hub] 'Reset to Normal' clicked!")
        EnsureHoverboardLoaded()
        if getgenv().HoverboardController and getgenv().HoverboardController.Reset then
            print("[Hub] Calling HoverboardController.Reset()...")
            getgenv().HoverboardController.Reset()
        else
            print("[Hub] ERROR: HoverboardController.Reset not found!")
        end
    end
})

-- ======================================================================
-- 🗺️ NAVIGATION TAB UI
-- ======================================================================

    local islandNames = {}
    local islandPositions = {}
    
    local function refreshIslands()
        table.clear(islandNames)
        table.clear(islandPositions)
        local guider = game.ReplicatedStorage:FindFirstChild("CompassGuider")
        if guider then
            for _, island in ipairs(guider:GetChildren()) do
                table.insert(islandNames, island.Name)
                islandPositions[island.Name] = island.Value
            end
        end
        if #islandNames == 0 then table.insert(islandNames, "None") end
    end
    refreshIslands()

    local selectedIslandPos = nil

    local D_Island = getgenv().FishmanState.Tabs.Navigation:AddDropdown("D_Island", {
        Title = "Select Island",
        Values = islandNames,
        Multi = false,
        Default = islandNames[1],
        Callback = function(Value)
            selectedIslandPos = islandPositions[Value]
        end
    })
    
    getgenv().FishmanState.Tabs.Navigation:AddButton({
        Title = "🔄 Refresh Islands",
        Description = "Refreshes the island list if CompassGuider was slow to load.",
        Callback = function()
            refreshIslands()
            D_Island:SetValues(islandNames)
            getgenv().FishmanState.Fluent:Notify({ Title = "Refreshed", Content = "Island list updated.", Duration = 3 })
        end
    })

    -- ======================================================================
    -- 👥 PLAYER TELEPORTER
    -- ======================================================================
    local playerNames = {}
    if getgenv().FishmanState.AccountConfigs then
        for pName, _ in pairs(getgenv().FishmanState.AccountConfigs) do
            if pName ~= LocalPlayer.Name then
                table.insert(playerNames, pName)
            end
        end
    end
    if #playerNames == 0 then table.insert(playerNames, "No other players") end

    local selectedTargetPlayer = nil

    local D_TargetPlayer = getgenv().FishmanState.Tabs.Navigation:AddDropdown("D_TargetPlayer", {
        Title = "Select Player to Join",
        Values = playerNames,
        Multi = false,
        Default = playerNames[1],
        Callback = function(Value)
            selectedTargetPlayer = Value
        end
    })

    local selectedTargetSea = "Second Sea" -- Default for Main Farming Sea

    local D_TargetSea = getgenv().FishmanState.Tabs.Navigation:AddDropdown("D_TargetSea", {
        Title = "Player's Current Sea",
        Values = {"fishHub", "tradeHub", "First Sea", "Second Sea"},
        Multi = false,
        Default = "Second Sea",
        Callback = function(Value)
            selectedTargetSea = Value
        end
    })

    getgenv().FishmanState.Tabs.Navigation:AddButton({
        Title = "🚀 Join Player's Server",
        Description = "Teleports you back to the Lobby and auto-joins the selected player's PS and Sea.",
        Callback = function()
            if not selectedTargetPlayer or selectedTargetPlayer == "No other players" then
                getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "No valid player selected.", Duration = 3 })
                return
            end
            
            local config = getgenv().FishmanState.AccountConfigs and getgenv().FishmanState.AccountConfigs[selectedTargetPlayer]
            if config and config.code then
                local env = getgenv and getgenv() or shared
                env.FishmanPSCode = config.code
                env.FishmanDestination = selectedTargetSea
                
                -- Auto spawn ship on arrival
                env.FishmanAutoSpawnShip = true
                
                if getgenv().FishmanState.UpdateTeleportMemory then
                    getgenv().FishmanState.UpdateTeleportMemory(true)
                end
                getgenv().FishmanState.Fluent:Notify({ Title = "Teleporting", Content = "Routing to " .. selectedTargetPlayer .. " via Lobby...", Duration = 5 })
                task.wait(1.5)
                game:GetService("TeleportService"):Teleport(1730877806, LocalPlayer)
            else
                getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Configuration for " .. selectedTargetPlayer .. " is invalid.", Duration = 3 })
            end
        end
    })
    
    local flightStatus = getgenv().FishmanState.Tabs.Navigation:AddParagraph({ Title = "Flight Status", Content = "Idle" })
    
    getgenv().FishmanState.Tabs.Navigation:AddButton({
        Title = "🛫 Start Flight",
        Description = "Begins advanced auto-navigation to the selected island.",
        Callback = function()
            local character = LocalPlayer.Character
            if not character or not character.PrimaryPart then return end
            
            if getgenv().FishmanState.Model.State.activeNavigation and getgenv().FishmanState.Model.State.activeNavigation._isNavigating then
                getgenv().FishmanState.Fluent:Notify({ Title = "Already Flying", Content = "Cancel or Pause current flight first.", Duration = 3 })
                return
            end
            
            if not selectedIslandPos then
                getgenv().FishmanState.Fluent:Notify({ Title = "No Island", Content = "Please select a valid island first.", Duration = 3 })
                return
            end
            
            getgenv().FishmanState.Model.State.activeNavigation = getgenv().FishmanState.Model.NavigateTo(character, selectedIslandPos, 90, 20)
            
            task.spawn(function()
                while getgenv().FishmanState._running and getgenv().FishmanState.Model.State.activeNavigation and getgenv().FishmanState.Model.State.activeNavigation._isNavigating do
                    local nav = getgenv().FishmanState.Model.State.activeNavigation
                    if nav._isPaused then
                        flightStatus:SetDesc("Paused (" .. tostring(nav.Distance) .. " studs)")
                    elseif nav._roboTarget then
                        flightStatus:SetDesc("Lock: Robo! (" .. tostring(nav.Distance) .. " studs)")
                    else
                        flightStatus:SetDesc("Flying... (" .. tostring(nav.Distance) .. " studs)")
                    end
                    task.wait(0.1)
                end
                flightStatus:SetDesc("Idle")
            end)
        end
    })

    getgenv().FishmanState.Tabs.Navigation:AddButton({
        Title = "⏸️ Pause / Resume Flight",
        Description = "Toggles the current flight state.",
        Callback = function()
            if getgenv().FishmanState.Model.State.activeNavigation and getgenv().FishmanState.Model.State.activeNavigation._isNavigating then
                local isPaused = getgenv().FishmanState.Model.State.activeNavigation:TogglePause()
                if isPaused then
                    getgenv().FishmanState.Fluent:Notify({ Title = "Paused", Content = "Flight paused.", Duration = 3 })
                else
                    getgenv().FishmanState.Fluent:Notify({ Title = "Resumed", Content = "Flight resumed.", Duration = 3 })
                end
            end
        end
    })

    getgenv().FishmanState.Tabs.Navigation:AddButton({
        Title = "🛑 Cancel Flight",
        Description = "Immediately stops the current flight.",
        Callback = function()
            if getgenv().FishmanState.Model.State.activeNavigation and getgenv().FishmanState.Model.State.activeNavigation._isNavigating then
                getgenv().FishmanState.Model.State.activeNavigation:Cancel()
                getgenv().FishmanState.Model.State.activeNavigation = nil
                flightStatus:SetDesc("Idle")
                getgenv().FishmanState.Fluent:Notify({ Title = "Cancelled", Content = "Flight cancelled.", Duration = 3 })
            end
        end
    })

    getgenv().FishmanState.Tabs.Navigation:AddToggle("T_IslandESP", { Title = "Islands ESP", Default = false, Callback = function(Value) 
        getgenv().FishmanState.Model.State.isIslandESP = Value
        if Value then
            task.spawn(function()
                while getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isIslandESP do
                    local islandsFolder = workspace:FindFirstChild("Islands")
                    if islandsFolder then
                        for _, island in ipairs(islandsFolder:GetChildren()) do
                            if island:IsA("Model") or island:IsA("BasePart") then
                                local rootPart = island:IsA("Model") and (island.PrimaryPart or island:FindFirstChildWhichIsA("BasePart")) or island
                                if rootPart then
                                    local espName = "IslandESP_" .. island.Name
                                    if not rootPart:FindFirstChild(espName) then
                                        local bgui = Instance.new("BillboardGui")
                                        bgui.Name = espName
                                        bgui.AlwaysOnTop = true
                                        bgui.Size = UDim2.new(0, 100, 0, 50)
                                        bgui.StudsOffset = Vector3.new(0, 50, 0)
                                        
                                        local txt = Instance.new("TextLabel")
                                        txt.Size = UDim2.new(1, 0, 1, 0)
                                        txt.BackgroundTransparency = 1
                                        txt.Text = island.Name
                                        txt.TextColor3 = Color3.fromRGB(0, 255, 255)
                                        txt.TextStrokeTransparency = 0
                                        txt.TextScaled = true
                                        txt.Parent = bgui
                                        
                                        bgui.Parent = rootPart
                                        
                                        if not island:FindFirstChild("IslandESP_HL") then
                                            local hl = Instance.new("Highlight")
                                            hl.Name = "IslandESP_HL"
                                            hl.FillColor = Color3.fromRGB(0, 255, 255)
                                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                            hl.FillTransparency = 0.5
                                            hl.Parent = island
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(2)
                end
                
                local islandsFolder = workspace:FindFirstChild("Islands")
                if islandsFolder then
                    for _, island in ipairs(islandsFolder:GetChildren()) do
                        local rootPart = island:IsA("Model") and (island.PrimaryPart or island:FindFirstChildWhichIsA("BasePart")) or island
                        if rootPart then
                            local bgui = rootPart:FindFirstChild("IslandESP_" .. island.Name)
                            if bgui then bgui:Destroy() end
                        end
                        local hl = island:FindFirstChild("IslandESP_HL")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        else
            local islandsFolder = workspace:FindFirstChild("Islands")
            if islandsFolder then
                for _, island in ipairs(islandsFolder:GetChildren()) do
                    local rootPart = island:IsA("Model") and (island.PrimaryPart or island:FindFirstChildWhichIsA("BasePart")) or island
                    if rootPart then
                        local bgui = rootPart:FindFirstChild("IslandESP_" .. island.Name)
                        if bgui then bgui:Destroy() end
                    end
                    local hl = island:FindFirstChild("IslandESP_HL")
                    if hl then hl:Destroy() end
                end
            end
        end
    end })

    getgenv().FishmanState.Tabs.Navigation:AddToggle("T_FruitESP", { Title = "Fruit ESP", Default = false, Callback = function(Value) 
        getgenv().FishmanState.Model.State.isFruitESP = Value
        local targetFruits = {
            "Dragon", "Venom", "Mochi", "Soul", "Pika", "Buddha", "Magu", "Goro", "Goru",
            "Hie", "Kage", "Mera", "Tori", "Pteranodon", "Smoke", "Yami", "Suna", "Yuki", "Ope", "Zushi", "Ito", "Paw"
        }
        
        local function isTarget(objName)
            local lowerName = string.lower(objName)
            for _, fName in ipairs(targetFruits) do
                if string.find(lowerName, string.lower(fName)) then
                    return true
                end
            end
            return false
        end

        if Value then
            task.spawn(function()
                while getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isFruitESP do
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if (obj:IsA("Tool") or obj:IsA("Model")) and isTarget(obj.Name) then
                            local rootPart = (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or (obj:IsA("Tool") and obj:FindFirstChild("Handle"))
                            if rootPart then
                                local espName = "FruitESP_" .. obj.Name
                                if not rootPart:FindFirstChild(espName) then
                                    local bgui = Instance.new("BillboardGui")
                                    bgui.Name = espName
                                    bgui.AlwaysOnTop = true
                                    bgui.Size = UDim2.new(0, 100, 0, 50)
                                    bgui.StudsOffset = Vector3.new(0, 5, 0)
                                    
                                    local txt = Instance.new("TextLabel")
                                    txt.Size = UDim2.new(1, 0, 1, 0)
                                    txt.BackgroundTransparency = 1
                                    txt.Text = obj.Name
                                    txt.TextColor3 = Color3.fromRGB(255, 0, 255)
                                    txt.TextStrokeTransparency = 0
                                    txt.TextScaled = true
                                    txt.Parent = bgui
                                    
                                    bgui.Parent = rootPart
                                    
                                    if not obj:FindFirstChild("FruitESP_HL") then
                                        local hl = Instance.new("Highlight")
                                        hl.Name = "FruitESP_HL"
                                        hl.FillColor = Color3.fromRGB(255, 0, 255)
                                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                        hl.FillTransparency = 0.5
                                        hl.Parent = obj
                                    end
                                end
                            end
                        end
                    end
                    task.wait(2)
                end
                
                for _, obj in ipairs(workspace:GetChildren()) do
                    if (obj:IsA("Tool") or obj:IsA("Model")) and isTarget(obj.Name) then
                        local rootPart = (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or (obj:IsA("Tool") and obj:FindFirstChild("Handle"))
                        if rootPart then
                            local bgui = rootPart:FindFirstChild("FruitESP_" .. obj.Name)
                            if bgui then bgui:Destroy() end
                        end
                        local hl = obj:FindFirstChild("FruitESP_HL")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        else
            for _, obj in ipairs(workspace:GetChildren()) do
                if (obj:IsA("Tool") or obj:IsA("Model")) and isTarget(obj.Name) then
                    local rootPart = (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or (obj:IsA("Tool") and obj:FindFirstChild("Handle"))
                    if rootPart then
                        local bgui = rootPart:FindFirstChild("FruitESP_" .. obj.Name)
                        if bgui then bgui:Destroy() end
                    end
                    local hl = obj:FindFirstChild("FruitESP_HL")
                    if hl then hl:Destroy() end
                end
            end
        end
    end })

-- ======================================================================
-- 🎣 FISHING TAB UI
-- ======================================================================
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_Fish", { Title = "Auto Fish", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot fish in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(false) end return end
        getgenv().FishmanState.Model.State.isFishing = Value 
    end })
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_DeepSea", { Title = "Deep Sea Catcher (ONLY Beasts)", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot fish in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(false) end return end
        task.spawn(function()
            if Value then
                print("triggering title: \"Skilled Fisherman\"")
                local args = {
                    "Skilled Fisherman"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args))
            end
        end)
        getgenv().FishmanState.Model.State.isDeepSeaCatcher = Value 
    end })
    
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_MegStack", { Title = "Megalodon Stack (Wait 10, Kill)", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot stack in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_MegStack:SetValue(false) end return end
        getgenv().FishmanState.Model.State.isMegStacking = Value
        if Value then
            if getgenv().FishmanState.Fluent.Options.T_DeepSea then getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(true) end
            if getgenv().FishmanState.Fluent.Options.T_Buy then getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(true) end
            if getgenv().FishmanState.Fluent.Options.T_MegStackLoc then getgenv().FishmanState.Fluent.Options.T_MegStackLoc:SetValue(true) end
            if getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit then getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit:SetValue(true) end
            if getgenv().FishmanState.Fluent.Options.T_AutoReturn then getgenv().FishmanState.Fluent.Options.T_AutoReturn:SetValue(true) end
            print("🌊 [MegStack] Meg stack starting now! Enabling deep sea catcher for 10 megalodons.")
            task.spawn(function()
                while getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isMegStacking do
                    local char = game:GetService("Players").LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp:FindFirstChild("AntiGravity") or hrp:FindFirstChildOfClass("BodyVelocity")) and not getgenv().FishmanState.Model.State.isRefillingMegBait and not getgenv().FishmanState.Model.State.isAutoTraveling then
                        print("⚠️ [MegStack] Safeguard triggered: In Air / AntiGravity detected. Disabling MegStack!")
                        if getgenv().FishmanState.Fluent.Options.T_MegStack then getgenv().FishmanState.Fluent.Options.T_MegStack:SetValue(false) end
                        break
                    end
                    local megCount = getgenv().FishmanState.Model.countMegalodons()
                    if megCount >= 10 and not getgenv().FishmanState.Model.State.isBuying and not getgenv().FishmanState.Model.State.isAutoTraveling and not getgenv().FishmanState.Model.State.isRefillingMegBait and not getgenv().FishmanState.Model.State.isManualTraveling then
                        print("🔥 [MegStack] 10 Megalodons reached! Disabling fishing and automatically toggling Cyborg Autofarm ON...")
                        if getgenv().FishmanState.Fluent.Options.T_DeepSea.Value == true then
                            getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(false)
                        end
                        if getgenv().FishmanState.Fluent.Options.T_Fish.Value == true then
                            getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(false)
                        end
                        -- Unequip Fishing Rod and Equip Cyborg Weapon so skills can fire instantly!
                        local char = game:GetService("Players").LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid:UnequipTools()
                            task.wait(0.2)
                            local backpack = game:GetService("Players").LocalPlayer:FindFirstChild("Backpack")
                            if backpack then
                                local cyborgWeapon = backpack:FindFirstChild("Cyborg")
                                if cyborgWeapon then
                                    char.Humanoid:EquipTool(cyborgWeapon)
                                end
                            end
                        end
                        task.wait(0.5)
                        
                        if getgenv().FishmanState.Fluent.Options.T_CyborgAuto then
                            getgenv()._MegStackTriggeredCyborg = true
                            getgenv().FishmanState.Fluent.Options.T_CyborgAuto:SetValue(true)
                            getgenv()._MegStackTriggeredCyborg = false
                        end
                        
                        local waitTime = 0
                        local lastCount = getgenv().FishmanState.Model.countMegalodons()
                        while getgenv().FishmanState._running and getgenv().FishmanState.Model.countMegalodons() > 0 and getgenv().FishmanState.Model.State.isMegStacking and waitTime < 180 do
                            task.wait(1)
                            waitTime = waitTime + 1
                            local curCount = getgenv().FishmanState.Model.countMegalodons()
                            if curCount < lastCount then
                                waitTime = 0
                                lastCount = curCount
                            end
                        end
                        
                        print("✅ [MegStack] Stack cleared! Toggling Cyborg Autofarm OFF and resuming fishing...")
                        
                        if getgenv().FishmanState.Fluent.Options.T_CyborgAuto then
                            getgenv().FishmanState.Fluent.Options.T_CyborgAuto:SetValue(false)
                        end
                        
                        if getgenv().FishmanState.Model.State.isMegStacking then
                            getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(true)
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            print("🛑 [MegStack] Stacking aborted. Shutting down deep sea catcher.")
            if getgenv().FishmanState.Fluent.Options.T_DeepSea and getgenv().FishmanState.Fluent.Options.T_DeepSea.Value == true then
                getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(false)
            end
            if getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit and getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit.Value == true then
                getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit:SetValue(false)
            end
            if getgenv().FishmanState.Fluent.Options.T_AutoReturn and getgenv().FishmanState.Fluent.Options.T_AutoReturn.Value == true then
                getgenv().FishmanState.Fluent.Options.T_AutoReturn:SetValue(false)
            end
        end
    end })
    
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_MegStackPassive", { Title = "Megalodon Stack (Wait 10, Wait for Kill)", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot stack in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_MegStackPassive:SetValue(false) end return end
        getgenv().FishmanState.Model.State.isMegStackPassive = Value
        if Value then
            if getgenv().FishmanState.Fluent.Options.T_DeepSea then getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(true) end
            if getgenv().FishmanState.Fluent.Options.T_Buy then getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(true) end
            if getgenv().FishmanState.Fluent.Options.T_MegStackLoc then getgenv().FishmanState.Fluent.Options.T_MegStackLoc:SetValue(true) end
            if getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit then getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit:SetValue(true) end
            if getgenv().FishmanState.Fluent.Options.T_AutoReturn then getgenv().FishmanState.Fluent.Options.T_AutoReturn:SetValue(true) end
            print("🌊 [MegStackPassive] Meg stack starting now! Enabling deep sea catcher for 10 megalodons.")
            task.spawn(function()
                while getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isMegStackPassive do
                    local char = game:GetService("Players").LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp:FindFirstChild("AntiGravity") or hrp:FindFirstChildOfClass("BodyVelocity")) and not getgenv().FishmanState.Model.State.isRefillingMegBait and not getgenv().FishmanState.Model.State.isAutoTraveling then
                        print("⚠️ [MegStackPassive] Safeguard triggered: In Air / AntiGravity detected. Disabling MegStack!")
                        if getgenv().FishmanState.Fluent.Options.T_MegStackPassive then getgenv().FishmanState.Fluent.Options.T_MegStackPassive:SetValue(false) end
                        break
                    end
                    local megCount = getgenv().FishmanState.Model.countMegalodons()
                    if megCount >= 10 and not getgenv().FishmanState.Model.State.isBuying and not getgenv().FishmanState.Model.State.isAutoTraveling and not getgenv().FishmanState.Model.State.isRefillingMegBait and not getgenv().FishmanState.Model.State.isManualTraveling then
                        print("🔥 [MegStackPassive] 10 Megalodons reached! Disabling fishing and waiting for kill...")
                        if getgenv().FishmanState.Fluent.Options.T_DeepSea.Value == true then
                            getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(false)
                        end
                        
                        local waitTime = 0
                        local lastCount = getgenv().FishmanState.Model.countMegalodons()
                        while getgenv().FishmanState._running and getgenv().FishmanState.Model.countMegalodons() > 0 and getgenv().FishmanState.Model.State.isMegStackPassive and waitTime < 180 do
                            task.wait(1)
                            waitTime = waitTime + 1
                            local curCount = getgenv().FishmanState.Model.countMegalodons()
                            if curCount < lastCount then
                                waitTime = 0
                                lastCount = curCount
                            end
                        end
                        
                        print("✅ [MegStackPassive] Stack cleared! Resuming fishing...")
                        
                        if getgenv().FishmanState.Model.State.isMegStackPassive then
                            getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(true)
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            print("🛑 [MegStackPassive] Stacking aborted. Shutting down deep sea catcher.")
            if getgenv().FishmanState.Fluent.Options.T_DeepSea and getgenv().FishmanState.Fluent.Options.T_DeepSea.Value == true then
                getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(false)
            end
            if getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit and getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit.Value == true then
                getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit:SetValue(false)
            end
            if getgenv().FishmanState.Fluent.Options.T_AutoReturn and getgenv().FishmanState.Fluent.Options.T_AutoReturn.Value == true then
                getgenv().FishmanState.Fluent.Options.T_AutoReturn:SetValue(false)
            end
        end
    end })
    
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_MegStackLoc", { Title = "Meg Stack Location (Auto Refill)", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot use in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_MegStackLoc:SetValue(false) end return end
        getgenv().FishmanState.Model.State.isMegStackLoc = Value 
    end })
    
    local manualTravelInitialized = false
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_ManualMegStackLoc", { Title = "Manual Meg Stack Island", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot use in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_ManualMegStackLoc:SetValue(false) end return end
        
        if Value then
            -- Turn off Auto Return to Hoverboard so it doesn't fly us back after arriving at Meg Stack Island
            if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_AutoReturn and getgenv().FishmanState.Fluent.Options.T_AutoReturn.Value then
                getgenv().FishmanState.Fluent.Options.T_AutoReturn:SetValue(false)
                getgenv().FishmanState.Fluent:Notify({ Title = "System", Content = "Auto Return Hoverboard turned OFF for Manual Travel", Duration = 3 })
            end

            manualTravelInitialized = true
            task.spawn(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then getgenv().CachedOriginalPos = hrp.Position end
                
                getgenv().FishmanState.Model.State.isAutoTraveling = false
                getgenv().FishmanState.Model.DisableFlight()
                if getgenv().FishmanState.Model.UnequipRod then getgenv().FishmanState.Model.UnequipRod() end
                task.wait(1)
                
                if not getgenv().FishmanState.Fluent.Options.T_ManualMegStackLoc.Value then return end
                
                getgenv().FishmanState.Model.State.isManualTraveling = true
                getgenv().FishmanState.Model.EnableFlight()
                getgenv().FishmanState.Fluent:Notify({ Title = "Manual Travel", Content = "Flying to Meg Stack Island...", Duration = 3 })
                getgenv().FishmanState.Model.CraftFlyPath({ Vector3.new(-6760, 27, 9191) })
                
                if getgenv().FishmanState.Model.State.isManualTraveling then
                    getgenv().FishmanState.Model.State.isManualTraveling = false
                    getgenv().FishmanState.Model.DisableFlight()
                    getgenv().FishmanState.Fluent:Notify({ Title = "Manual Travel", Content = "Arrived at Meg Stack Island!", Duration = 3 })
                    if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_ManualMegStackLoc then
                        getgenv().FishmanState.Fluent.Options.T_ManualMegStackLoc:SetValue(false)
                    end
                end
            end)
        else
            if not manualTravelInitialized then return end
            
            if getgenv().FishmanState.Model.State.isManualTraveling then
                getgenv().FishmanState.Model.State.isManualTraveling = false
                getgenv().FishmanState.Model.State.isRefillingMegBait = false
                getgenv().FishmanState.Model.State.isCraftFlying = false
                getgenv().FishmanState.Model.DisableFlight()
                if getgenv().FishmanState.Model.EquipRod then getgenv().FishmanState.Model.EquipRod() end
                getgenv().FishmanState.Fluent:Notify({ Title = "Manual Travel", Content = "Travel paused - flight disabled.", Duration = 3 })
            end
        end
    end })
    
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_HoverboardESP", { Title = "Ship ESP", Default = false, Callback = function(Value) 
        getgenv().FishmanState.Model.State.isHoverboardESP = Value 
        if Value then
            task.spawn(function()
                while getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isHoverboardESP do
                    local shipsFolder = workspace:FindFirstChild("Ships")
                    if shipsFolder then
                        local myShip = shipsFolder:FindFirstChild(LocalPlayer.Name .. "Ship")
                        if myShip and myShip:IsA("Model") then
                            if not myShip:FindFirstChild("HoverESP_Highlight") then
                                local hl = Instance.new("Highlight")
                                hl.Name = "HoverESP_Highlight"
                                hl.FillColor = Color3.fromRGB(0, 255, 0)
                                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                hl.FillTransparency = 0.5
                                hl.Parent = myShip
                            end
                        end
                    end
                    task.wait(1)
                end
                local shipsFolder = workspace:FindFirstChild("Ships")
                if shipsFolder then
                    local myShip = shipsFolder:FindFirstChild(LocalPlayer.Name .. "Ship")
                    if myShip then
                        local hl = myShip:FindFirstChild("HoverESP_Highlight")
                        if hl then hl:Destroy() end
                    end
                end
            end)
        else
            local shipsFolder = workspace:FindFirstChild("Ships")
            if shipsFolder then
                local myShip = shipsFolder:FindFirstChild(LocalPlayer.Name .. "Ship")
                if myShip then
                    local hl = myShip:FindFirstChild("HoverESP_Highlight")
                    if hl then hl:Destroy() end
                end
            end
        end
    end })
    
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_MegESP", { Title = "Megalodon ESP", Default = false, Callback = function(Value) 
        getgenv().FishmanState.Model.State.isMegESP = Value 
        if Value then
            task.spawn(function()
                while getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isMegESP do
                    local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Env")}
                    for _, folder in ipairs(folders) do
                        if folder then
                            for _, child in ipairs(folder:GetChildren()) do
                                if child.Name == "Megalodon" and child:FindFirstChild("HumanoidRootPart") then
                                    if not child:FindFirstChild("MegESP_Highlight") then
                                        local hl = Instance.new("Highlight")
                                        hl.Name = "MegESP_Highlight"
                                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                        hl.FillTransparency = 0.5
                                        hl.Parent = child
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
                local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Env")}
                for _, folder in ipairs(folders) do
                    if folder then
                        for _, child in ipairs(folder:GetChildren()) do
                            if child.Name == "Megalodon" then
                                local hl = child:FindFirstChild("MegESP_Highlight")
                                if hl then hl:Destroy() end
                            end
                        end
                    end
                end
            end)
        else
            local folders = {workspace:FindFirstChild("NPCs"), workspace:FindFirstChild("Env")}
            for _, folder in ipairs(folders) do
                if folder then
                    for _, child in ipairs(folder:GetChildren()) do
                        if child.Name == "Megalodon" then
                            local hl = child:FindFirstChild("MegESP_Highlight")
                            if hl then hl:Destroy() end
                        end
                    end
                end
            end
        end
    end })
    
    getgenv().FishmanState.Tabs.Fishing:AddButton({
        Title = "Return to Hoverboard",
        Description = "Uses Geppo + BV to manually fly back to your hoverboard",
        Callback = function()
            if isLobby then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot travel in Lobby!", Duration = 3 }); return end
            task.spawn(function()
                local success = getgenv().FishmanState.Model.ReturnToShip()
                if success then
                    print("🚀 [ReturnToShip] Successfully arrived at hoverboard!")
                else
                    getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "No Hoverboard detected in workspace!", Duration = 3 })
                end
            end)
        end
    })

    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_AutoReturn", { 
        Title = "Auto Return to Hoverboard", 
        Description = "Automatically flies back to your hoverboard if you fall off.",
        Default = false, 
        Callback = function(Value) 
            getgenv().FishmanState.Model.State.autoReturn = Value 
        end 
    })

    getgenv().FishmanState.Tabs.Fishing:AddSlider("S_ShipSpeed", {
        Title = "Return To Ship Speed",
        Description = "Adjusts flight speed (300 is recommended)",
        Default = 90,
        Min = 50,
        Max = 1000,
        Rounding = 0,
        Callback = function(Value)
            getgenv().FishmanState.Model.State.shipSpeed = Value
        end
    })

    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_StrictReel", { Title = "Only Reel > 1.0 Multiplier", Default = false, Callback = function(Value) 
        getgenv().FishmanState.Model.State.strictReel = Value 
    end })
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_Buy", { Title = "Auto Buy Bait", Default = not isLobby, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot buy in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(false) end return end
        getgenv().FishmanState.Model.State.autoBuy = Value; if Value then getgenv().FishmanState.Model.CheckInventory() end 
    end })
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_Sell", { Title = "Auto Sell Fish", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot sell in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_Sell:SetValue(false) end return end
        getgenv().FishmanState.Model.State.autoSell = Value; if Value then getgenv().FishmanState.Model.CheckInventory() end 
    end })
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_Travel", { Title = "Travel to Bait", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot travel in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_Travel:SetValue(false) end return end
        if Value then getgenv().FishmanState.Model.StartTraveling() else getgenv().FishmanState.Model.State.isAutoTraveling = false; if getgenv().FishmanState.Model.DisableFlight then getgenv().FishmanState.Model.DisableFlight() end; getgenv().FishmanState.Model.State.travelMessage = "" end 
    end })
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_Craft", { Title = "Auto Craft Legendary Bait", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot craft in Lobby!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_Craft:SetValue(false) end return end
        getgenv().FishmanState.Model.State.autoCraft = Value 
    end })
    getgenv().FishmanState.Tabs.Fishing:AddButton({
        Title = "🔨 Craft All Legendary Fish Now",
        Description = "Instantly crafts all legendary fishes in your inventory into bait.",
        Callback = function()
            if isLobby then
                getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot craft in Lobby!", Duration = 3 })
                return
            end
            task.spawn(getgenv().FishmanState.Model.ForceCraftAll)
        end
    })
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_AFK", { Title = "AFK Mode (Auto-start after 10s)", Default = false, Callback = function(Value) 
        if isLobby then if Value then getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "AFK Mode requires Fishing server!", Duration = 3 }); getgenv().FishmanState.Fluent.Options.T_AFK:SetValue(false) end return end
        getgenv().FishmanState.isAFKModeActive = Value; getgenv().FishmanState.secondsSinceLastInput = 0 
    end })

    getgenv().FishmanState.Tabs.Fishing:AddButton({
        Title = "Check Fruits",
        Description = "Check your inventory for target fruits.",
        Callback = function() getgenv().FishmanState.checkFruits(getgenv().FishmanState.targetFruits) end
    })
    
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_StoreFruitsManual", {
        Title = "Store Fruits",
        Description = "Store target fruits (keeps in inventory if full).",
        Default = false,
        Callback = function(Value)
            if Value then
                if getgenv().FishmanState.Fluent.Options.T_DropFruitsManual and getgenv().FishmanState.Fluent.Options.T_DropFruitsManual.Value then
                    getgenv().FishmanState.Fluent:Notify({ Title = "Action Prevented", Content = "Cannot store fruits while dropping is active!", Duration = 3 })
                    task.spawn(function() getgenv().FishmanState.Fluent.Options.T_StoreFruitsManual:SetValue(false) end)
                    return
                end
                getgenv()._cancelStoreFruits = false
                task.spawn(function()
                    getgenv().FishmanState.storeFruits(getgenv().FishmanState.targetFruits)
                    if getgenv().FishmanState.Fluent.Options.T_StoreFruitsManual and getgenv().FishmanState.Fluent.Options.T_StoreFruitsManual.Value then
                        getgenv().FishmanState.Fluent.Options.T_StoreFruitsManual:SetValue(false)
                    end
                end)
            else
                getgenv()._cancelStoreFruits = true
            end
        end
    })
    
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_DropFruitsManual", {
        Title = "Drop Fruits",
        Description = "Force drop all target fruits.",
        Default = false,
        Callback = function(Value)
            if Value then
                if getgenv().FishmanState.Fluent.Options.T_StoreFruitsManual and getgenv().FishmanState.Fluent.Options.T_StoreFruitsManual.Value then
                    getgenv().FishmanState.Fluent:Notify({ Title = "Action Prevented", Content = "Cannot drop fruits while manual storing is active!", Duration = 3 })
                    task.spawn(function() getgenv().FishmanState.Fluent.Options.T_DropFruitsManual:SetValue(false) end)
                    return
                end
                if getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit and getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit.Value then
                    getgenv().FishmanState.Fluent:Notify({ Title = "Action Prevented", Content = "Please turn off Auto Store Fruit before dropping!", Duration = 3 })
                    task.spawn(function() getgenv().FishmanState.Fluent.Options.T_DropFruitsManual:SetValue(false) end)
                    return
                end
                getgenv()._cancelDropFruits = false
                task.spawn(function()
                    getgenv().FishmanState.dropFruits(getgenv().FishmanState.targetFruits)
                    if getgenv().FishmanState.Fluent.Options.T_DropFruitsManual and getgenv().FishmanState.Fluent.Options.T_DropFruitsManual.Value then
                        getgenv().FishmanState.Fluent.Options.T_DropFruitsManual:SetValue(false)
                    end
                end)
            else
                getgenv()._cancelDropFruits = true
            end
        end
    })
    
    local autoStoreEnabled = false
    local backpackConn = nil
    local charConn = nil

    local function setupFruitListener()
        if backpackConn then backpackConn:Disconnect(); backpackConn = nil end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            backpackConn = backpack.ChildAdded:Connect(function(child)
                if autoStoreEnabled and child:IsA("Tool") then
                    -- Slight delay to ensure tool attributes load
                    task.delay(0.5, function()
                        if autoStoreEnabled then
                            getgenv()._cancelStoreFruits = false
                            getgenv().FishmanState.storeFruits(getgenv().FishmanState.targetFruits)
                        end
                    end)
                end
            end)
            getgenv().FishmanState.addConn(backpackConn)
        end
    end

    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_AutoStoreFruit", { 
        Title = "Auto Store Fruit (Instantly)", 
        Default = false, 
        Callback = function(Value)
            autoStoreEnabled = Value
            if autoStoreEnabled then
                if getgenv().FishmanState.Fluent.Options.T_DropFruitsManual and getgenv().FishmanState.Fluent.Options.T_DropFruitsManual.Value then
                    getgenv().FishmanState.Fluent:Notify({ Title = "Action Prevented", Content = "Cannot enable Auto Store while dropping!", Duration = 3 })
                    task.spawn(function() getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit:SetValue(false) end)
                    return
                end
                
                -- Check immediately upon turning it on
                task.spawn(function()
                    getgenv()._cancelStoreFruits = false
                    getgenv().FishmanState.storeFruits(getgenv().FishmanState.targetFruits)
                end)
                
                -- Setup listeners for future fruits
                setupFruitListener()
                if not charConn then
                    charConn = LocalPlayer.CharacterAdded:Connect(function()
                        task.wait(1)
                        setupFruitListener()
                    end)
                    getgenv().FishmanState.addConn(charConn)
                end
            else
                if backpackConn then 
                    backpackConn:Disconnect()
                    backpackConn = nil 
                end
            end
        end 
    })

    -- Status Monitor
    local StatusPara = getgenv().FishmanState.Tabs.Fishing:AddParagraph({ Title = "Status", Content = "Idle" })
    local statusParts = {}
    task.spawn(function()
        while getgenv().FishmanState._running and task.wait(1) do
            table.clear(statusParts)
            if getgenv().FishmanState.Model.State.isFishing then table.insert(statusParts, "Fishing") end
            if getgenv().FishmanState.Model.State.autoBuy then table.insert(statusParts, "Buying") end
            if getgenv().FishmanState.Model.State.autoSell then table.insert(statusParts, "Selling") end
            if getgenv().FishmanState.Model.State.autoCraft then table.insert(statusParts,  getgenv().FishmanState.Model.State.isCurrentlyCrafting and "Crafting" or "Craft ON") end
            if getgenv().FishmanState.isAFKModeActive then table.insert(statusParts, "[AFK ON]") end

            if getgenv().FishmanState.Model.State.isAutoTraveling or getgenv().FishmanState.Model.State.travelMessage ~= "" then
                StatusPara:SetDesc("Status: " .. getgenv().FishmanState.Model.State.travelMessage)
                if getgenv().FishmanState.Model.State.travelMessage == "Arrived at Bait" and getgenv().FishmanState.Model.State.waitingForArrivalToFish then
                    getgenv().FishmanState.Model.State.waitingForArrivalToFish = false
                    if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_Fish then getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(true) end -- Automatically turn on fishing toggle in UI
                end
            else
                StatusPara:SetDesc(#statusParts > 0 and ("Active: " .. table.concat(statusParts, " ")) or "Idle")
            end
        end
    end)
    
    if not isLobby and getgenv().FishmanState.GetCurrentPSCode() == GlobalMem.FishmanPSCode and GlobalMem.FishmanPSCode ~= "" then
        getgenv().FishmanState.Fluent:Notify({ Title = "Detection", Content = "Target Server " .. tostring(GlobalMem.FishmanPSCode) .. " Detected.", Duration = 5 })
    end

-- ======================================================================
-- 🤖 AUTOFARM TAB UI
-- ======================================================================
getgenv().FishmanState.Tabs.Autofarm:AddToggle("T_CyborgAuto", { 
    Title = "Toggle Cyborg Autofarm", 
    Default = false, 
    Callback = function(Value)
        if isLobby then 
            if Value then 
                getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot farm in Lobby!", Duration = 3 }) 
                if getgenv().FishmanState.Fluent.Options.T_CyborgAuto then getgenv().FishmanState.Fluent.Options.T_CyborgAuto:SetValue(false) end 
            end 
            return 
        end

        if Value then
            -- Temporarily turn off auto store fruit if it was on
            if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit then
                getgenv()._wasAutoStoreFruitOn = getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit.Value
                if getgenv()._wasAutoStoreFruitOn then
                    getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit:SetValue(false)
                    getgenv().FishmanState.Fluent:Notify({ Title = "System", Content = "Auto Store Fruit paused during Cyborg Autofarm", Duration = 3 })
                end
            end
            
            -- Turn off Meg Stack if turned on manually (not by Meg Stack itself)
            if not getgenv()._MegStackTriggeredCyborg then
                if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_MegStack then
                    if getgenv().FishmanState.Fluent.Options.T_MegStack.Value == true then
                        getgenv().FishmanState.Fluent.Options.T_MegStack:SetValue(false)
                        getgenv().FishmanState.Fluent:Notify({ Title = "System", Content = "Meg Stack turned off (manual override)", Duration = 3 })
                    end
                end
            end
        else
            -- Restore auto store fruit if it was previously on
            if getgenv()._wasAutoStoreFruitOn and getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit then
                getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit:SetValue(true)
                getgenv()._wasAutoStoreFruitOn = false
                getgenv().FishmanState.Fluent:Notify({ Title = "System", Content = "Auto Store Fruit resumed", Duration = 3 })
            end
        end

        task.spawn(function()
            if Value then
                print("triggering title: \"Megalodon Slayer\"")
                local args = {
                    "Megalodon Slayer"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args))
            end
        end)

        if Value and not getgenv().ToggleCyborgAutofarm then
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/protov4_nofactory.lua?t="..tostring(tick())))()
            end)
            task.wait(0.5)
        end
        if getgenv().ToggleCyborgAutofarm then
            getgenv().ToggleCyborgAutofarm(Value)
        end
    end 
})


getgenv().FishmanState.Tabs.Autofarm:AddButton({                   
    Title = "Load MeleeFactory",
    Description = "Executes the Melee Factory script.",
    Callback = function()
        local scriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/MSTACK/meleefactory.lua?t="..tostring(tick())
        loadstring(game:HttpGet(scriptURL))()
        getgenv().FishmanState.Fluent:Notify({ Title = "MeleeFactory Loaded", Content = "MeleeFactory script initialized.", Duration = 3 })
    end
})

getgenv().FishmanState.Tabs.Autofarm:AddButton({                   
    Title = "Auto Reroll Skypian",
    Description = "Executes the auto reroll skypian script.",
    Callback = function()
        local scriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/MSTACK/auto_reroll_skypian.lua?t="..tostring(tick())
        loadstring(game:HttpGet(scriptURL))()
        getgenv().FishmanState.Fluent:Notify({ Title = "Skypian Reroll Loaded", Content = "Auto reroll script initialized.", Duration = 3 })
    end
})

getgenv().FishmanState.Tabs.Autofarm:AddButton({                   
    Title = "Load CombinedAutoLoad (Autofarm)",
    Description = "Executes the script and queues it for future teleports.",
    Callback = function()
        getgenv().FishmanAllowAutoLoad = true
        local scriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/CombinedAutoLoad.lua"
        
        -- Execute the script. It will automatically queue itself for future teleports.
        loadstring(game:HttpGet(scriptURL))()
        
        getgenv().FishmanState.Fluent:Notify({ Title = "Autofarm Loaded", Content = "Auto-farm initialized and queued.", Duration = 3 })
    end
})

local selectedMerchantItems = {}
getgenv().FishmanState.Tabs.Autofarm:AddDropdown("D_MerchantItems", {
    Title = "Traveling Merchant Buy List",
    Description = "Select items to auto-buy from the Traveling Merchant.",
    Values = {"Dark Root", "Hoverboard", "Mythical Fruit Chest", "Fruit Bag", "Merchants Banana Rod"},
    Multi = true,
    Default = {},
    Callback = function(Value)
        selectedMerchantItems = Value 
    end
})

getgenv().FishmanState.Tabs.Autofarm:AddButton({
    Title = "Auto-Buy From Traveling Merchant",
    Description = "Opens shop and buys selected items if available.",
    Callback = function()
        task.spawn(function()
            print("[Logic] Searching for Merchant location...")
            local targetPos = nil
            
            local guider = game:GetService("ReplicatedStorage"):FindFirstChild("CompassGuider")
            if guider then
                for _, child in ipairs(guider:GetChildren()) do
                    if string.find(string.lower(child.Name), "merchant") then
                        if typeof(child.Value) == "Vector3" then
                            targetPos = child.Value
                            print("[Logic] Found Merchant in CompassGuider at: ", targetPos)
                            break
                        end
                    end
                end
            end
            
            if not targetPos then
                for _, obj in ipairs(game.Workspace:GetDescendants()) do
                    if obj:IsA("Model") and string.find(string.lower(obj.Name), "merchant") and obj:FindFirstChild("HumanoidRootPart") then
                        targetPos = obj.HumanoidRootPart.Position
                        print("[Logic] Found Merchant getgenv().FishmanState.Model in Workspace at: ", targetPos)
                        break
                    end
                end
            end
            
            if targetPos then
                if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Merchant Auto-Buy", Content = "Pathfinding to Merchant...", Duration = 3 }) end
                print("[Logic] Pathfinding to Merchant...")
                local hrp = game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local PathfindingService = game:GetService("PathfindingService")
                    local path = PathfindingService:CreatePath({
                        AgentRadius = 3,
                        AgentHeight = 5,
                        AgentCanJump = true,
                        WaypointSpacing = 4,
                        Costs = { Water = 20 }
                    })
                    
                    local success, err = pcall(function()
                        path:ComputeAsync(hrp.Position, targetPos)
                    end)
                    
                    if success and path.Status == Enum.PathStatus.Success then
                        local waypoints = path:GetWaypoints()
                        local bv = hrp:FindFirstChild("MerchantAntiGravity") or Instance.new("BodyVelocity")
                        bv.Name = "MerchantAntiGravity"
                        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                        bv.Velocity = Vector3.new(0, 0, 0)
                        bv.Parent = hrp
                        
                        for i, waypoint in ipairs(waypoints) do
                            if not getgenv().FishmanState._running then break end
                            local wpPos = waypoint.Position
                            wpPos = wpPos + Vector3.new(0, 5, 0)
                            
                            local stuckTimer = 0
                            local lastDist = (hrp.Position - wpPos).Magnitude
                            
                            while getgenv().FishmanState._running and hrp.Parent do
                                local dist = (hrp.Position - wpPos).Magnitude
                                if dist <= 3 then break end
                                
                                local dt = task.wait()
                                
                                if lastDist - dist < 0.1 then
                                    stuckTimer = stuckTimer + dt
                                else
                                    stuckTimer = 0
                                    lastDist = dist
                                end
                                
                                if stuckTimer > 0.5 then
                                    for _, part in ipairs(hrp.Parent:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                            part.CanCollide = false
                                        end
                                    end
                                end
                                
                                local flySpeed = 50
                                local lerpAlpha = math.clamp((flySpeed * dt) / dist, 0, 1)
                                
                                local lookAtCFrame
                                if dist > 0.1 then
                                    lookAtCFrame = CFrame.lookAt(hrp.Position, wpPos)
                                else
                                    lookAtCFrame = hrp.CFrame
                                end
                                
                                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(wpPos) * lookAtCFrame.Rotation, lerpAlpha)
                                hrp.Velocity = Vector3.new(0, 0, 0)
                                hrp.RotVelocity = Vector3.new(0, 0, 0)
                            end
                        end
                        if bv then bv:Destroy() end
                        print("[Logic] Arrived at Merchant!")
                    else
                        print("[Logic] Failed to compute path. Attempting fallback bypass...")
                    end
                end
            else
                print("[Logic] Could not locate Traveling Merchant. Trying remote anyway.")
            end

            print("[Logic] Opening Traveling Merchant Shop...")
            local openArgs = { [1] = "OpenShop" }
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Events", 5):WaitForChild("TravelingMerchentRemote", 5):InvokeServer(unpack(openArgs))
            end)
            
            task.wait(1)
            
            local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            local redeemables = playerGui:FindFirstChild("MerchentShop") and 
                                playerGui.MerchentShop:FindFirstChild("Main") and 
                                playerGui.MerchentShop.Main:FindFirstChild("List") and 
                                playerGui.MerchentShop.Main.List:FindFirstChild("Redeemables")

            for itemName, isSelected in pairs(selectedMerchantItems) do
                if isSelected then
                    local hasItem = true
                    if redeemables then
                        hasItem = redeemables:FindFirstChild(itemName) ~= nil
                    end
                    
                    if hasItem then
                        print("[Logic] Buying Item: " .. tostring(itemName))
                        local buyArgs = { itemName }
                        pcall(function()
                            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("TravelingMerchentRemote"):InvokeServer(unpack(buyArgs))
                        end)
                        task.wait(0.5)
                    else
                        print("[Logic] Item not found in shop: " .. tostring(itemName))
                    end
                end
            end
            if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Merchant Auto-Buy", Content = "Finished purchasing selected items.", Duration = 3 }) end
        end)
    end
})

getgenv().FishmanState.Tabs.Autofarm:AddButton({
    Title = "Stop & Clear Autofarm Queue",
    Description = "Tries to halt the autofarm and wipes the teleport queue.",
    Callback = function()
        getgenv().FishmanAutoFarmRunning = false
        
        -- Attempt to clear the exploit teleport queue so it stops following you
        local clear_queue = clear_teleport_queue or (syn and syn.clear_teleport_queue) or (fluxus and fluxus.clear_teleport_queue)
        if clear_queue then
            pcall(clear_queue)
        end
        
        -- Attempt to call any generic stop functions from Controller.lua if they exist
        if typeof(getgenv().StopAutofarm) == "function" then pcall(getgenv().StopAutofarm) end
        
        getgenv().FishmanState.Fluent:Notify({ Title = "Autofarm Halted", Content = "Queue cleared. If loops are still running, please manually rejoin.", Duration = 5 })
    end
})

-- ======================================================================
-- ⚙️ SETTINGS TAB UI
-- ======================================================================
getgenv().FishmanState.Tabs.Settings:AddToggle("T_AutoReconnect", { 
    Title = "Auto Reconnect on Disconnect", 
    Default = GlobalMem.FishmanAutoReconnect, 
    Callback = function(Value)
        GlobalMem.FishmanAutoReconnect = Value
        getgenv().FishmanState.SaveConfig()
    end 
})

getgenv().FishmanState.Tabs.Settings:AddToggle("T_AntiLag", { 
    Title = "Disable 3D Rendering (Anti-Lag)", 
    Default = false, 
    Callback = function(Value)
        RunService:Set3dRenderingEnabled(not Value)
    end 
})

getgenv().FishmanState.Tabs.Settings:AddSlider("S_FPSCap", {
    Title = "FPS Cap",
    Description = "Limits your FPS to reduce CPU/GPU usage when AFKing.",
    Default = 35,
    Min = 5,
    Max = 240,
    Rounding = 0,
    Callback = function(Value)
        if setfpscap then pcall(setfpscap, Value) end
    end
})

getgenv().FishmanState.Tabs.Settings:AddButton({
    Title = "🥔 Potato Graphics",
    Description = "Reduces all game graphics to the absolute minimum for maximum FPS.",
    Callback = function()
        getgenv().FishmanState.ActivatePotatoGraphics()
    end
})

getgenv().FishmanState.Tabs.Settings:AddButton({
    Title = "🔄 Update / Load Latest Version",
    Description = "Destroys the current UI and executes the latest joinersystem from GitHub.",
    Callback = function()
        getgenv().FishmanState.Fluent:Notify({ Title = "Updating", Content = "Fetching latest script from GitHub...", Duration = 3 })
        getgenv().FishmanState.ShutdownEverything()
        if Window and Window.Destroy then
            Window:Destroy()
        end
        task.wait(1)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/loader.lua?t="..tostring(tick())))()
    end
})

getgenv().FishmanState.Tabs.Settings:AddButton({
    Title = "Destroy UI & Shutdown",
    Description = "Cleans up all loops, unloads the UI, and stops the script safely.",
    Callback = function()
        getgenv().FishmanState.ShutdownEverything()
        if Window and Window.Destroy then
            Window:Destroy()
        end
    end
})

Window:SelectTab(isLobby and 1 or 2)
getgenv().FishmanState.Fluent:Notify({ Title = "Fishman Unified", Content = "Script loaded successfully!", Duration = 5 })

local isPaused = false
local savedState = {}

getgenv().FishmanState.addConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    getgenv().FishmanState.secondsSinceLastInput = 0
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        isPaused = not isPaused
        if isPaused then
            getgenv().FishmanState.Fluent:Notify({ Title = "🛑 Emergency Stop", Content = "Script paused! Press F again to resume.", Duration = 5 })
            
            -- Stop Auto Start state (AFK Mode)
            getgenv().FishmanState.isAFKModeActive = false
            if getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_AFK then
                getgenv().FishmanState.Fluent.Options.T_AFK:SetValue(false)
            end

            if getgenv().FishmanState.Model and getgenv().FishmanState.Model.State then
                -- Save current task states
                savedState = {
                    isFishing = getgenv().FishmanState.Model.State.isFishing,
                    autoBuy = getgenv().FishmanState.Model.State.autoBuy,
                    autoSell = getgenv().FishmanState.Model.State.autoSell,
                    isAutoTraveling = getgenv().FishmanState.Model.State.isAutoTraveling,
                    autoCraft = getgenv().FishmanState.Model.State.autoCraft,
                    isCurrentlyCrafting = getgenv().FishmanState.Model.State.isCurrentlyCrafting,
                    antiLag = (getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_AntiLag) and getgenv().FishmanState.Fluent.Options.T_AntiLag.Value or false,
                    deepSea = (getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_DeepSea) and getgenv().FishmanState.Fluent.Options.T_DeepSea.Value or false,
                    megStack = (getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_MegStack) and getgenv().FishmanState.Fluent.Options.T_MegStack.Value or false,
                    megStackLoc = (getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_MegStackLoc) and getgenv().FishmanState.Fluent.Options.T_MegStackLoc.Value or false
                }

                -- Force stop everything instantly
                getgenv().FishmanState.Model.State.isFishing = false
                -- getgenv().FishmanState.Model.State.autoBuy = false
                getgenv().FishmanState.Model.State.autoSell = false
                getgenv().FishmanState.Model.State.isAutoTraveling = false
                getgenv().FishmanState.Model.State.autoCraft = false
                getgenv().FishmanState.Model.State.isCurrentlyCrafting = false
                getgenv().FishmanState.Model.State.isCraftFlying = false
                getgenv().FishmanState.Model.State.isBuying = false
                
                -- Update UI toggles to visually show they are off
                if getgenv().FishmanState.Fluent.Options then
                    if getgenv().FishmanState.Fluent.Options.T_Fish then getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(false) end
                    -- if getgenv().FishmanState.Fluent.Options.T_Buy then getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(false) end
                    if getgenv().FishmanState.Fluent.Options.T_Sell then getgenv().FishmanState.Fluent.Options.T_Sell:SetValue(false) end
                    if getgenv().FishmanState.Fluent.Options.T_Travel then getgenv().FishmanState.Fluent.Options.T_Travel:SetValue(false) end
                    if getgenv().FishmanState.Fluent.Options.T_Craft then getgenv().FishmanState.Fluent.Options.T_Craft:SetValue(false) end
                    if getgenv().FishmanState.Fluent.Options.T_AntiLag then getgenv().FishmanState.Fluent.Options.T_AntiLag:SetValue(false) end
                    if getgenv().FishmanState.Fluent.Options.T_DeepSea then getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(false) end
                    if getgenv().FishmanState.Fluent.Options.T_MegStack then getgenv().FishmanState.Fluent.Options.T_MegStack:SetValue(false) end
                    if getgenv().FishmanState.Fluent.Options.T_MegStackLoc then getgenv().FishmanState.Fluent.Options.T_MegStackLoc:SetValue(false) end
                end

                -- Abort actions
                if getgenv().FishmanState.Model.DisableFlight then pcall(getgenv().FishmanState.Model.DisableFlight) end
                if getgenv().FishmanState.Model.UnequipRod then pcall(getgenv().FishmanState.Model.UnequipRod) end
                if getgenv().FishmanState.Model.State.activeNavigation and getgenv().FishmanState.Model.State.activeNavigation._isNavigating then
                    getgenv().FishmanState.Model.State.activeNavigation:Cancel()
                end

                -- Close any dialogue
                pcall(function()
                    local events = ReplicatedStorage:FindFirstChild("Events")
                    local quest = events and events:FindFirstChild("Quest")
                    if quest then quest:InvokeServer({ [1] = "npcChat", [2] = false }) end
                end)
            end
        else
            getgenv().FishmanState.Fluent:Notify({ Title = "▶️ Resumed", Content = "Script restored to previous tasks.", Duration = 5 })

            if getgenv().FishmanState.Model and getgenv().FishmanState.Model.State then
                -- Restore previously active tasks
                getgenv().FishmanState.Model.State.isFishing = savedState.isFishing or false
                getgenv().FishmanState.Model.State.autoBuy = savedState.autoBuy or false
                getgenv().FishmanState.Model.State.autoSell = savedState.autoSell or false
                getgenv().FishmanState.Model.State.isAutoTraveling = savedState.isAutoTraveling or false
                getgenv().FishmanState.Model.State.autoCraft = savedState.autoCraft or false
                
                -- Update UI toggles visually to match restored state
                if getgenv().FishmanState.Fluent.Options then
                    if getgenv().FishmanState.Fluent.Options.T_Fish then getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(getgenv().FishmanState.Model.State.isFishing) end
                    if getgenv().FishmanState.Fluent.Options.T_Buy then getgenv().FishmanState.Fluent.Options.T_Buy:SetValue(getgenv().FishmanState.Model.State.autoBuy) end
                    if getgenv().FishmanState.Fluent.Options.T_Sell then getgenv().FishmanState.Fluent.Options.T_Sell:SetValue(getgenv().FishmanState.Model.State.autoSell) end
                    if getgenv().FishmanState.Fluent.Options.T_Travel then getgenv().FishmanState.Fluent.Options.T_Travel:SetValue(getgenv().FishmanState.Model.State.isAutoTraveling) end
                    if getgenv().FishmanState.Fluent.Options.T_Craft then getgenv().FishmanState.Fluent.Options.T_Craft:SetValue(getgenv().FishmanState.Model.State.autoCraft) end
                    if getgenv().FishmanState.Fluent.Options.T_AntiLag and savedState.antiLag then getgenv().FishmanState.Fluent.Options.T_AntiLag:SetValue(true) end
                    if getgenv().FishmanState.Fluent.Options.T_DeepSea then getgenv().FishmanState.Fluent.Options.T_DeepSea:SetValue(savedState.deepSea) end
                    if getgenv().FishmanState.Fluent.Options.T_MegStack then getgenv().FishmanState.Fluent.Options.T_MegStack:SetValue(savedState.megStack) end
                    if getgenv().FishmanState.Fluent.Options.T_MegStackLoc then getgenv().FishmanState.Fluent.Options.T_MegStackLoc:SetValue(savedState.megStackLoc) end
                end

                -- Resume traveling if needed
                if getgenv().FishmanState.Model.State.isAutoTraveling and getgenv().FishmanState.Model.StartTraveling then
                    getgenv().FishmanState.Model.StartTraveling()
                end
            end
        end
    end
end))
getgenv().FishmanState.addConn(UserInputService.InputChanged:Connect(function() getgenv().FishmanState.secondsSinceLastInput = 0 end))
