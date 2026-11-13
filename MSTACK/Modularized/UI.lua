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
local isLobby = getgenv().FishmanState.isLobby
local mySession = getgenv().FishmanSession or 0

-- ======================================================================
-- 🎨 CUSTOM LIGHTWEIGHT UI INTEGRATION
-- ======================================================================
local Fluent = { Options = {} }
getgenv().FishmanState.Fluent = Fluent

local THEME = {
    Bg        = Color3.fromRGB(16, 18, 24),
    Surface   = Color3.fromRGB(22, 25, 33),
    Card      = Color3.fromRGB(28, 32, 42),
    CardHover = Color3.fromRGB(36, 41, 54),
    Border    = Color3.fromRGB(48, 54, 68),
    Accent    = Color3.fromRGB(88, 166, 255),
    On        = Color3.fromRGB(72, 219, 132),
    Off       = Color3.fromRGB(235, 95, 105),
    Text      = Color3.fromRGB(235, 240, 248),
    Muted     = Color3.fromRGB(145, 154, 170),
    FontMain  = Enum.Font.GothamMedium,
    FontMono  = Enum.Font.Code,
}

local notifyGui, notifyContainer
local function getNotifyContainer()
    if notifyContainer and notifyContainer.Parent then return notifyContainer end
    local coreGui = game:GetService("CoreGui")
    local existing = coreGui:FindFirstChild("FishmanNotify")
    if existing then existing:Destroy() end

    notifyGui = Instance.new("ScreenGui")
    notifyGui.Name = "FishmanNotify"
    notifyGui.ResetOnSpawn = false
    notifyGui.Parent = coreGui

    notifyContainer = Instance.new("Frame")
    notifyContainer.Size = UDim2.new(0, 230, 1, -20)
    notifyContainer.Position = UDim2.new(1, -240, 0, 10)
    notifyContainer.BackgroundTransparency = 1
    notifyContainer.Parent = notifyGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 6)
    layout.Parent = notifyContainer

    return notifyContainer
end

function Fluent:Notify(options)
    local container = getNotifyContainer()

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = THEME.Surface
    frame.BorderSizePixel = 1
    frame.BorderColor3 = THEME.Border
    frame.Parent = container

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = THEME.Accent
    accent.BorderSizePixel = 0
    accent.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 9)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent = frame

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    txt.RichText = true
    txt.Text = string.format("<b>%s</b>\n<font color=\"rgb(175,184,200)\">%s</font>", tostring(options.Title or ""), tostring(options.Content or ""))
    txt.TextColor3 = THEME.Text
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextYAlignment = Enum.TextYAlignment.Top
    txt.Font = THEME.FontMain
    txt.TextSize = 11
    txt.TextWrapped = true
    txt.Parent = frame

    task.delay(options.Duration or 3, function()
        if frame and frame.Parent then frame:Destroy() end
    end)
end

function Fluent:CreateWindow(options)
    local FakeWindow = {}

    local sg = Instance.new("ScreenGui")
    sg.Name = "FishmanHubCustom"
    sg.ResetOnSpawn = false
    sg.Parent = game:GetService("CoreGui")

    FakeWindow.Destroy = function(self)
        sg:Destroy()
        if notifyGui and notifyGui.Parent then notifyGui:Destroy() end
    end
    env.Fishman_DestroyUI = function() pcall(function() FakeWindow:Destroy() end) end

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 520, 0, 360)
    mainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
    mainFrame.BackgroundColor3 = THEME.Bg
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = THEME.Border
    mainFrame.Active = true
    mainFrame.Parent = sg

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 28)
    topBar.BackgroundColor3 = THEME.Surface
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame

    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, 0, 0, 1)
    topDivider.Position = UDim2.new(0, 0, 1, -1)
    topDivider.BackgroundColor3 = THEME.Border
    topDivider.BorderSizePixel = 0
    topDivider.Parent = topBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -64, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.RichText = true
    titleLabel.Text = string.format("<b>%s</b>  <font color=\"rgb(135,145,165)\">|  %s</font>", tostring(options.Title or "Hub"), tostring(options.SubTitle or ""))
    titleLabel.TextColor3 = THEME.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Font = THEME.FontMain
    titleLabel.TextSize = 12
    titleLabel.Parent = topBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 27)
    minBtn.Position = UDim2.new(1, -56, 0, 0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "-"
    minBtn.TextColor3 = THEME.Muted
    minBtn.Font = THEME.FontMain
    minBtn.TextSize = 14
    minBtn.Parent = topBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 27)
    closeBtn.Position = UDim2.new(1, -28, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = THEME.Off
    closeBtn.Font = THEME.FontMain
    closeBtn.TextSize = 12
    closeBtn.Parent = topBar

    local isMinimized = false
    local preferredW, preferredH = 520, 360
    local currentW, currentH = 520, 360
    local function getViewportSize()
        local cam = workspace.CurrentCamera
        return (cam and cam.ViewportSize) or Vector2.new(1280, 720)
    end
    local function clampWindowPosition(x, y)
        local vp = getViewportSize()
        local h = isMinimized and 28 or currentH
        local maxX = math.max(0, math.floor(vp.X - currentW))
        local maxY = math.max(0, math.floor(vp.Y - h))
        return math.clamp(math.floor(x), 0, maxX), math.clamp(math.floor(y), 0, maxY)
    end

    local function toggleMinimize()
        isMinimized = not isMinimized
        mainFrame.Size = UDim2.fromOffset(currentW, isMinimized and 28 or currentH)
        for _, c in ipairs(mainFrame:GetChildren()) do
            if c ~= topBar and c.Name ~= "UICorner" then c.Visible = not isMinimized end
        end
        local cx, cy = clampWindowPosition(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset)
        mainFrame.Position = UDim2.fromOffset(cx, cy)
    end
    minBtn.MouseButton1Click:Connect(toggleMinimize)
    closeBtn.MouseButton1Click:Connect(function() FakeWindow:Destroy() end)

    if options.MinimizeKey then
        getgenv().FishmanState.addConn(UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == options.MinimizeKey then
                toggleMinimize()
            end
        end))
    end

    -- Single shared drag handler for whole-window dragging, corner resizing, and all sliders
    local activeDragUpdate = nil
    local draggingWindow, dragStart, startPos
    local resizingWindow, resizeStartPos, resizeStartW, resizeStartH = false, nil, 520, 360
    local applyResponsiveLayout
    local function attachWindowDrag(guiObj)
        guiObj.InputBegan:Connect(function(input)
            if not activeDragUpdate and not resizingWindow and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                draggingWindow = true
                dragStart = input.Position
                startPos = mainFrame.Position
            end
        end)
    end
    attachWindowDrag(mainFrame)
    attachWindowDrag(topBar)

    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.new(0, 16, 0, 16)
    resizeHandle.Position = UDim2.new(1, -16, 1, -16)
    resizeHandle.BackgroundTransparency = 1
    resizeHandle.Text = ""
    resizeHandle.AutoButtonColor = false
    resizeHandle.ZIndex = 10
    resizeHandle.Parent = mainFrame

    local grip1 = Instance.new("Frame")
    grip1.Size = UDim2.new(0, 10, 0, 2)
    grip1.Position = UDim2.new(1, -12, 1, -4)
    grip1.BackgroundColor3 = THEME.Muted
    grip1.BorderSizePixel = 0
    grip1.ZIndex = 11
    grip1.Parent = resizeHandle
    local grip2 = Instance.new("Frame")
    grip2.Size = UDim2.new(0, 2, 0, 10)
    grip2.Position = UDim2.new(1, -4, 1, -12)
    grip2.BackgroundColor3 = THEME.Muted
    grip2.BorderSizePixel = 0
    grip2.ZIndex = 11
    grip2.Parent = resizeHandle

    resizeHandle.MouseEnter:Connect(function()
        grip1.BackgroundColor3 = THEME.Accent
        grip2.BackgroundColor3 = THEME.Accent
    end)
    resizeHandle.MouseLeave:Connect(function()
        if not resizingWindow then
            grip1.BackgroundColor3 = THEME.Muted
            grip2.BackgroundColor3 = THEME.Muted
        end
    end)
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizingWindow = true
            draggingWindow = false
            resizeStartPos = input.Position
            resizeStartW = currentW
            resizeStartH = currentH
        end
    end)

    getgenv().FishmanState.addConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = false
            resizingWindow = false
            activeDragUpdate = nil
            grip1.BackgroundColor3 = THEME.Muted
            grip2.BackgroundColor3 = THEME.Muted
        end
    end))
    getgenv().FishmanState.addConn(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if activeDragUpdate then
                activeDragUpdate(input.Position.X)
            elseif resizingWindow then
                local vp = getViewportSize()
                local delta = input.Position - resizeStartPos
                local maxW = math.max(220, math.floor(vp.X - 8))
                local maxH = math.max(140, math.floor(vp.Y - 8))
                preferredW = math.clamp(math.floor(resizeStartW + delta.X), 220, maxW)
                preferredH = math.clamp(math.floor(resizeStartH + delta.Y), 140, maxH)
                if applyResponsiveLayout then applyResponsiveLayout(false) end
            elseif draggingWindow then
                local delta = input.Position - dragStart
                local cx, cy = clampWindowPosition(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
                mainFrame.Position = UDim2.fromOffset(cx, cy)
            end
        end
    end))

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(0, 124, 1, -28)
    tabContainer.Position = UDim2.new(0, 0, 0, 28)
    tabContainer.BackgroundColor3 = THEME.Surface
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 2
    tabContainer.ScrollBarImageColor3 = THEME.Border
    tabContainer.Parent = mainFrame

    local tabPad = Instance.new("UIPadding", tabContainer)
    tabPad.PaddingTop = UDim.new(0, 6)
    tabPad.PaddingLeft = UDim.new(0, 6)
    tabPad.PaddingRight = UDim.new(0, 6)
    local tabLayout = Instance.new("UIListLayout", tabContainer)
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 12)
    end)

    local sideDivider = Instance.new("Frame")
    sideDivider.Size = UDim2.new(0, 1, 1, -28)
    sideDivider.Position = UDim2.new(0, 124, 0, 28)
    sideDivider.BackgroundColor3 = THEME.Border
    sideDivider.BorderSizePixel = 0
    sideDivider.Parent = mainFrame

    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -125, 1, -28)
    contentContainer.Position = UDim2.new(0, 125, 0, 28)
    contentContainer.BackgroundColor3 = THEME.Bg
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainFrame

    attachWindowDrag(tabContainer)
    attachWindowDrag(contentContainer)

    applyResponsiveLayout = function(centerIfFirst)
        local vp = getViewportSize()
        local maxW = math.max(100, math.floor(vp.X - 8))
        local maxH = math.max(80, math.floor(vp.Y - 8))
        local newW = (vp.X <= 540) and maxW or math.min(preferredW, maxW)
        local newH = (vp.Y <= 380) and maxH or math.min(preferredH, maxH)

        currentW, currentH = newW, newH
        local sideW = (newW < 360) and math.max(76, math.floor(newW * 0.27)) or 124

        mainFrame.Size = UDim2.fromOffset(newW, isMinimized and 28 or newH)
        tabContainer.Size = UDim2.new(0, sideW, 1, -28)
        sideDivider.Position = UDim2.new(0, sideW, 0, 28)
        contentContainer.Size = UDim2.new(1, -(sideW + 1), 1, -28)
        contentContainer.Position = UDim2.new(0, sideW + 1, 0, 28)

        if centerIfFirst then
            local h = isMinimized and 28 or newH
            local cx = math.max(0, math.floor((vp.X - newW) * 0.15))
            local cy = math.max(0, math.floor((vp.Y - h) * 0.12))
            mainFrame.Position = UDim2.fromOffset(cx, cy)
        else
            local cx, cy = clampWindowPosition(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset)
            mainFrame.Position = UDim2.fromOffset(cx, cy)
        end
    end

    applyResponsiveLayout(true)
    local vpConn = nil
    local function hookCameraViewport()
        if vpConn then
            if getgenv().FishmanState.removeConn then
                getgenv().FishmanState.removeConn(vpConn)
            else
                pcall(function() vpConn:Disconnect() end)
            end
            vpConn = nil
        end
        local cam = workspace.CurrentCamera
        if cam then
            vpConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                applyResponsiveLayout(false)
            end)
            getgenv().FishmanState.addConn(vpConn)
        end
    end
    hookCameraViewport()
    getgenv().FishmanState.addConn(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        hookCameraViewport()
        applyResponsiveLayout(false)
    end))

    local tabsList = {}
    local activeTabBtn, activeTabBar, activeContent = nil, nil, nil

    local function setActiveTab(tabBtn, tabBar, contentScroll)
        if activeTabBtn then
            activeTabBtn.TextColor3 = THEME.Muted
            activeTabBtn.BackgroundColor3 = THEME.Surface
            if activeTabBar then activeTabBar.Visible = false end
            activeContent.Visible = false
        end
        activeTabBtn = tabBtn
        activeTabBar = tabBar
        activeContent = contentScroll
        tabBtn.TextColor3 = THEME.Text
        tabBtn.BackgroundColor3 = THEME.CardHover
        tabBar.Visible = true
        contentScroll.Visible = true
    end

    function FakeWindow:AddTab(tabArgs)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 26)
        tabBtn.BackgroundColor3 = THEME.Surface
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.Text = "  " .. tabArgs.Title
        tabBtn.TextColor3 = THEME.Muted
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Font = THEME.FontMain
        tabBtn.TextSize = 11
        tabBtn.Parent = tabContainer

        local tabBar = Instance.new("Frame")
        tabBar.Size = UDim2.new(0, 2, 1, -6)
        tabBar.Position = UDim2.new(0, 0, 0, 3)
        tabBar.BackgroundColor3 = THEME.Accent
        tabBar.BorderSizePixel = 0
        tabBar.Visible = false
        tabBar.Parent = tabBtn

        local contentScroll = Instance.new("ScrollingFrame")
        contentScroll.Size = UDim2.new(1, 0, 1, 0)
        contentScroll.BackgroundTransparency = 1
        contentScroll.BorderSizePixel = 0
        contentScroll.ScrollBarThickness = 3
        contentScroll.ScrollBarImageColor3 = THEME.Border
        contentScroll.Visible = false
        contentScroll.Parent = contentContainer
        attachWindowDrag(contentScroll)

        local contentPad = Instance.new("UIPadding", contentScroll)
        contentPad.PaddingTop = UDim.new(0, 6)
        contentPad.PaddingBottom = UDim.new(0, 6)
        contentPad.PaddingLeft = UDim.new(0, 8)
        contentPad.PaddingRight = UDim.new(0, 8)
        local contentLayout = Instance.new("UIListLayout", contentScroll)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 4)
        local itemOrder = 0
        local function nextOrder()
            itemOrder = itemOrder + 1
            return itemOrder
        end
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 12)
        end)

        tabBtn.MouseButton1Click:Connect(function()
            setActiveTab(tabBtn, tabBar, contentScroll)
        end)
        if not activeTabBtn then
            setActiveTab(tabBtn, tabBar, contentScroll)
        end

        local FakeTab = {}
        table.insert(tabsList, { Btn = tabBtn, Bar = tabBar, Content = contentScroll })

        function FakeTab:AddToggle(id, tArgs)
            local isTable = type(id) == "table"; if isTable then tArgs = id; id = nil end
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundColor3 = THEME.Card
            btn.BorderSizePixel = 1
            btn.BorderColor3 = THEME.Border
            btn.AutoButtonColor = false
            btn.RichText = true
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = THEME.FontMain
            btn.TextSize = 11
            btn.LayoutOrder = nextOrder()
            btn.Parent = contentScroll

            local FakeToggle = { Value = tArgs.Default or false }
            local function update(silent)
                if FakeToggle.Value then
                    btn.Text = string.format("  <font color=\"rgb(72,219,132)\"><b>[ON]</b></font>  %s", tArgs.Title)
                else
                    btn.Text = string.format("  <font color=\"rgb(235,95,105)\"><b>[OFF]</b></font> %s", tArgs.Title)
                end
                btn.TextColor3 = THEME.Text
                if not silent and tArgs.Callback then task.spawn(tArgs.Callback, FakeToggle.Value) end
            end
            btn.MouseButton1Click:Connect(function() FakeToggle.Value = not FakeToggle.Value; update(false) end)
            FakeToggle.SetValue = function(self, val, silent) self.Value = val; update(silent) end
            if not isTable and id then getgenv().FishmanState.Fluent.Options[id] = FakeToggle end
            update(); return FakeToggle
        end

        function FakeTab:AddButton(bArgs)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundColor3 = THEME.CardHover
            btn.BorderSizePixel = 1
            btn.BorderColor3 = THEME.Border
            btn.Text = "  ›  " .. bArgs.Title
            btn.TextColor3 = THEME.Text
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = THEME.FontMain
            btn.TextSize = 11
            btn.LayoutOrder = nextOrder()
            btn.Parent = contentScroll
            btn.MouseButton1Click:Connect(function() if bArgs.Callback then task.spawn(bArgs.Callback) end end)
        end

        function FakeTab:AddSlider(id, sArgs)
            local isTable = type(id) == "table"; if isTable then sArgs = id; id = nil end
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 34)
            frame.BackgroundColor3 = THEME.Card
            frame.BorderSizePixel = 1
            frame.BorderColor3 = THEME.Border
            frame.LayoutOrder = nextOrder()
            frame.Parent = contentScroll

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -12, 0, 16)
            lbl.Position = UDim2.new(0, 6, 0, 2)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = THEME.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Font = THEME.FontMain
            lbl.TextSize = 11
            lbl.Parent = frame

            local bg = Instance.new("TextButton")
            bg.Size = UDim2.new(1, -12, 0, 8)
            bg.Position = UDim2.new(0, 6, 0, 21)
            bg.BackgroundColor3 = THEME.Bg
            bg.BorderSizePixel = 0
            bg.Text = ""; bg.AutoButtonColor = false
            bg.Parent = frame

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = THEME.Accent
            fill.BorderSizePixel = 0
            fill.Parent = bg

            local FakeSlider = { Value = sArgs.Default or sArgs.Min }
            local range = math.max(1e-6, sArgs.Max - sArgs.Min)
            local step = sArgs.Rounding and (10 ^ -sArgs.Rounding) or 1
            local function update(val)
                val = math.clamp(val, sArgs.Min, sArgs.Max)
                FakeSlider.Value = val
                lbl.Text = sArgs.Title .. ": " .. tostring(val)
                fill.Size = UDim2.new((val - sArgs.Min) / range, 0, 1, 0)
                if sArgs.Callback then task.spawn(sArgs.Callback, val) end
            end
            local function updateFromX(mouseX)
                local width = math.max(1, bg.AbsoluteSize.X)
                local pct = math.clamp(mouseX - bg.AbsolutePosition.X, 0, width) / width
                update(math.floor((sArgs.Min + range * pct) / step + 0.5) * step)
            end
            bg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    activeDragUpdate = updateFromX
                    updateFromX(input.Position.X)
                end
            end)
            FakeSlider.SetValue = function(self, val) update(val) end
            if not isTable and id then getgenv().FishmanState.Fluent.Options[id] = FakeSlider end
            update(FakeSlider.Value); return FakeSlider
        end

        function FakeTab:AddDropdown(id, dArgs)
            local isTable = type(id) == "table"; if isTable then dArgs = id; id = nil end
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 24)
            frame.BackgroundColor3 = THEME.Card
            frame.BorderSizePixel = 1
            frame.BorderColor3 = THEME.Border
            frame.ClipsDescendants = true
            frame.LayoutOrder = nextOrder()
            frame.Parent = contentScroll

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundTransparency = 1
            btn.TextColor3 = THEME.Text
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = THEME.FontMain
            btn.TextSize = 11
            btn.Parent = frame

            local list = Instance.new("ScrollingFrame")
            list.Size = UDim2.new(1, 0, 0, 88)
            list.Position = UDim2.new(0, 0, 0, 24)
            list.BackgroundColor3 = THEME.Surface
            list.BorderSizePixel = 0
            list.ScrollBarThickness = 2
            list.ScrollBarImageColor3 = THEME.Border
            list.Parent = frame
            local listLayout = Instance.new("UIListLayout", list)

            local isOpen = false
            local FakeDrop = { Value = nil }
            local optionUpdaters = {}

            local function formatHeader()
                local label = (dArgs.Multi and type(FakeDrop.Value) == "table") and (#FakeDrop.Value .. " selected") or tostring(FakeDrop.Value)
                btn.Text = (isOpen and "  v " or "  > ") .. dArgs.Title .. ": " .. label
            end

            btn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                frame.Size = UDim2.new(1, 0, 0, isOpen and 112 or 24)
                formatHeader()
            end)

            local initVal = dArgs.Default
            if type(initVal) == "number" and not dArgs.Multi and dArgs.Values and dArgs.Values[initVal] then
                initVal = dArgs.Values[initVal]
            end
            FakeDrop.Value = initVal or (dArgs.Multi and {} or "")

            local function refreshAllVis()
                for _, fn in ipairs(optionUpdaters) do fn() end
            end

            local function populate(vals)
                table.clear(optionUpdaters)
                for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _, v in ipairs(vals) do
                    local opt = Instance.new("TextButton")
                    opt.Size = UDim2.new(1, 0, 0, 20)
                    opt.BackgroundTransparency = 1
                    opt.Text = "    " .. tostring(v)
                    opt.TextColor3 = THEME.Muted
                    opt.TextXAlignment = Enum.TextXAlignment.Left
                    opt.Font = THEME.FontMono
                    opt.TextSize = 11
                    opt.Parent = list

                    local function updateVis()
                        if dArgs.Multi then
                            local f = false; for _, sv in ipairs(FakeDrop.Value) do if sv == v then f = true break end end
                            opt.TextColor3 = f and THEME.On or THEME.Muted
                        else
                            opt.TextColor3 = (FakeDrop.Value == v) and THEME.On or THEME.Muted
                        end
                    end
                    table.insert(optionUpdaters, updateVis)

                    opt.MouseButton1Click:Connect(function()
                        if dArgs.Multi then
                            local fIdx = nil; for i, sv in ipairs(FakeDrop.Value) do if sv == v then fIdx = i break end end
                            if fIdx then table.remove(FakeDrop.Value, fIdx) else table.insert(FakeDrop.Value, v) end
                        else
                            FakeDrop.Value = v; isOpen = false; frame.Size = UDim2.new(1, 0, 0, 24)
                        end
                        formatHeader()
                        refreshAllVis()
                        if dArgs.Callback then task.spawn(dArgs.Callback, FakeDrop.Value) end
                    end)
                    updateVis()
                end
                list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
            end

            FakeDrop.SetValues = function(self, vals) populate(vals) end
            FakeDrop.SetValue = function(self, val)
                self.Value = val
                formatHeader()
                refreshAllVis()
                if dArgs.Callback then task.spawn(dArgs.Callback, self.Value) end
            end
            if not isTable and id then getgenv().FishmanState.Fluent.Options[id] = FakeDrop end
            populate(dArgs.Values or {})
            formatHeader()
            if initVal and dArgs.Callback then task.spawn(dArgs.Callback, initVal) end
            return FakeDrop
        end

        function FakeTab:AddParagraph(id, pArgs)
            local isTable = type(id) == "table"; if isTable then pArgs = id; id = nil end
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 0)
            card.AutomaticSize = Enum.AutomaticSize.Y
            card.BackgroundColor3 = THEME.Card
            card.BorderSizePixel = 1
            card.BorderColor3 = THEME.Border
            card.LayoutOrder = nextOrder()
            card.Parent = contentScroll

            local pad = Instance.new("UIPadding", card)
            pad.PaddingTop = UDim.new(0, 6)
            pad.PaddingBottom = UDim.new(0, 6)
            pad.PaddingLeft = UDim.new(0, 8)
            pad.PaddingRight = UDim.new(0, 8)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 0)
            lbl.AutomaticSize = Enum.AutomaticSize.Y
            lbl.BackgroundTransparency = 1
            lbl.Text = (pArgs.Title or "") .. "\n" .. (pArgs.Content or "")
            lbl.TextColor3 = THEME.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextYAlignment = Enum.TextYAlignment.Top
            lbl.Font = THEME.FontMono
            lbl.TextSize = 11
            lbl.TextWrapped = true
            lbl.Parent = card
            local FakePara = {}
            function FakePara:SetDesc(txt) lbl.Text = (pArgs.Title or "") .. "\n" .. txt end
            return FakePara
        end

        function FakeTab:AddInput(id, iArgs)
            local isTable = type(id) == "table"; if isTable then iArgs = id; id = nil end
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 24)
            frame.BackgroundColor3 = THEME.Card
            frame.BorderSizePixel = 1
            frame.BorderColor3 = THEME.Border
            frame.LayoutOrder = nextOrder()
            frame.Parent = contentScroll

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.45, -6, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = iArgs.Title or ""
            lbl.TextColor3 = THEME.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Font = THEME.FontMain
            lbl.TextSize = 11
            lbl.Parent = frame

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0.55, -6, 1, -4)
            box.Position = UDim2.new(0.45, 2, 0, 2)
            box.BackgroundColor3 = THEME.Bg
            box.BorderSizePixel = 1
            box.BorderColor3 = THEME.Border
            box.Text = iArgs.Default or ""
            box.PlaceholderText = iArgs.Placeholder or ""
            box.PlaceholderColor3 = THEME.Muted
            box.TextColor3 = THEME.Text
            box.Font = THEME.FontMono
            box.TextSize = 11
            box.ClearTextOnFocus = false
            box.Parent = frame

            local FakeInput = { Value = iArgs.Default or "" }
            box:GetPropertyChangedSignal("Text"):Connect(function()
                FakeInput.Value = box.Text
                if not iArgs.Finished and iArgs.Callback then
                    task.spawn(iArgs.Callback, box.Text)
                end
            end)
            box.FocusLost:Connect(function()
                FakeInput.Value = box.Text
                if iArgs.Callback then
                    task.spawn(iArgs.Callback, box.Text)
                end
            end)
            FakeInput.SetValue = function(self, val) self.Value = val; box.Text = val; if iArgs.Callback then task.spawn(iArgs.Callback, val) end end
            if not isTable and id then getgenv().FishmanState.Fluent.Options[id] = FakeInput end
            return FakeInput
        end

        return FakeTab
    end

    function FakeWindow:SelectTab(idx)
        local target = tabsList[idx]
        if target then
            setActiveTab(target.Btn, target.Bar, target.Content)
        end
    end

    return FakeWindow
end

local Window = getgenv().FishmanState.Fluent:CreateWindow({
    Title = "🐟 Fishman Hub",
    SubTitle = "Unified Auto-Fisher 1.0.3 v3.8",
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

local Tabs = {
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "plane" }),
    Navigation = Window:AddTab({ Title = "Navigation", Icon = "map" }),
    Fishing = Window:AddTab({ Title = "Fishing", Icon = "anchor" }),
    Autofarm = Window:AddTab({ Title = "Autofarm", Icon = "swords" }),
    Status = Window:AddTab({ Title = "Status", Icon = "bar-chart" }),
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
        getgenv().FishmanState.isScriptTeleporting = true
        if getgenv().FishmanState.Fluent then
            getgenv().FishmanState.Fluent:Notify({
                Title = "🚀 Teleport Sequence",
                Content = "Warping to " .. tostring(destination) .. "\nPS Code: " .. tostring(psCode or "None"),
                Duration = 5
            })
        end
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

    local selectedIslandPos = islandPositions[islandNames[1]]

    local function getFilteredIslands(query)
        query = string.lower(query or ""):gsub("^%s*(.-)%s*$", "%1")
        if query == "" then
            local list = {}
            for _, name in ipairs(islandNames) do
                table.insert(list, name)
            end
            return list
        end
        local filtered = {}
        for _, name in ipairs(islandNames) do
            if string.find(string.lower(name), query, 1, true) then
                table.insert(filtered, name)
            end
        end
        if #filtered == 0 then
            table.insert(filtered, "No matches found")
        end
        return filtered
    end

    local D_Island = nil

    local searchIslandInput = getgenv().FishmanState.Tabs.Navigation:AddInput("SearchIsland", {
        Title = "🔍 Search Island",
        Default = "",
        Placeholder = "Type island name (e.g. Zou)...",
        Numeric = false,
        Finished = false,
        Callback = function(Value)
            if not D_Island then return end
            local filtered = getFilteredIslands(Value)
            D_Island:SetValues(filtered)
            if Value and Value ~= "" and #filtered == 1 and filtered[1] ~= "No matches found" then
                D_Island:SetValue(filtered[1])
                selectedIslandPos = islandPositions[filtered[1]]
            end
        end
    })

    D_Island = getgenv().FishmanState.Tabs.Navigation:AddDropdown("D_Island", {
        Title = "Select Island",
        Values = islandNames,
        Multi = false,
        Default = islandNames[1],
        Callback = function(Value)
            if Value and Value ~= "No matches found" and Value ~= "None" then
                selectedIslandPos = islandPositions[Value]
            end
        end
    })
    
    getgenv().FishmanState.Tabs.Navigation:AddButton({
        Title = "🔄 Refresh Islands",
        Description = "Refreshes the island list if CompassGuider was slow to load.",
        Callback = function()
            refreshIslands()
            local query = searchIslandInput and searchIslandInput.Value or ""
            D_Island:SetValues(getFilteredIslands(query))
            getgenv().FishmanState.Fluent:Notify({ Title = "Refreshed", Content = "Island list updated.", Duration = 3 })
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
                while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and getgenv().FishmanState.Model.State.activeNavigation and getgenv().FishmanState.Model.State.activeNavigation._isNavigating do
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
                while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isIslandESP do
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
        local targetFruits = getgenv().FishmanState.targetFruits or {
            "Dragon", "Venom", "Mochi", "Soul", "Pika", "Buddha", "Magu", "Goro", "Goru", "Gura",
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
                while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isFruitESP do
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
        if Value then
            -- Clear any stuck lockouts so re-enabling is never blocked or ignored
            getgenv().FishmanState.Model.State.isCurrentlyCrafting = false
            getgenv().FishmanState.Model.State.isCraftFlying = false
            getgenv().FishmanState.Model.State.isBuying = false
            getgenv().FishmanLastCycleTime = os.clock()
            if getgenv().FishmanState.Model.EquipRod then
                pcall(getgenv().FishmanState.Model.EquipRod)
            end
        end
    end })
    getgenv().FishmanState.Tabs.Fishing:AddDropdown("D_BaitType", {
        Title = "Bait Type",
        Values = { "Common Fish Bait", "Legendary Fish Bait" },
        Default = GlobalMem.FishmanBaitType or "Common Fish Bait",
        Callback = function(Value)
            GlobalMem.FishmanBaitType = Value
            if getgenv().FishmanState.Model and getgenv().FishmanState.Model.State then
                getgenv().FishmanState.Model.State.selectedBait = Value
            end
            if getgenv().FishmanState.SaveConfig then
                getgenv().FishmanState.SaveConfig()
            end
        end
    })
    local legBaitInit = false
    local legBaitSeq = 0
    local function setLegBaitFeatures(opts, enabled)
        if opts.T_Fish and opts.T_Fish.Value ~= enabled then opts.T_Fish:SetValue(enabled) end
        if opts.T_StrictReel and opts.T_StrictReel.Value ~= enabled then opts.T_StrictReel:SetValue(enabled) end
        if opts.T_Buy and opts.T_Buy.Value ~= enabled then opts.T_Buy:SetValue(enabled) end
        if opts.T_Craft and opts.T_Craft.Value ~= enabled then opts.T_Craft:SetValue(enabled) end
        if opts.T_AntiLag then
            if opts.T_AntiLag.Value ~= enabled then opts.T_AntiLag:SetValue(enabled) end
        else
            pcall(function() RunService:Set3dRenderingEnabled(not enabled) end)
        end
        if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Notify then
            getgenv().FishmanState.Fluent:Notify({
                Title = "Auto Leg Bait",
                Content = enabled and "Turned ON: Auto Fish, Strict Reel, Auto Buy, Auto Craft, & Anti-Lag" or "Turned OFF: Auto Fish, Strict Reel, Auto Buy, Auto Craft, & Anti-Lag",
                Duration = 3
            })
        end
    end
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_AutoLegBait", {
        Title = "Auto Leg Bait (All-In-One)",
        Default = false,
        Callback = function(Value)
            if not legBaitInit then
                legBaitInit = true
                return
            end
            if isLobby then
                if Value and getgenv().FishmanState.Fluent then
                    getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot fish/craft in Lobby!", Duration = 3 })
                    if getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_AutoLegBait then
                        getgenv().FishmanState.Fluent.Options.T_AutoLegBait:SetValue(false)
                    end
                end
                return
            end
            local opts = getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options
            if not opts then return end

            legBaitSeq = legBaitSeq + 1
            local mySeq = legBaitSeq

            if not Value then
                if opts.T_MoveToFishingSpot and opts.T_MoveToFishingSpot.Value then
                    opts.T_MoveToFishingSpot:SetValue(false)
                end
                setLegBaitFeatures(opts, false)
                return
            end

            local spotPos = Vector3.new(104, 9, -56)
            if opts.T_MoveToFishingSpot then
                if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Notify then
                    getgenv().FishmanState.Fluent:Notify({
                        Title = "Auto Leg Bait",
                        Content = "Moving to Fishing Spot first...",
                        Duration = 3
                    })
                end
                if not opts.T_MoveToFishingSpot.Value then
                    opts.T_MoveToFishingSpot:SetValue(true)
                end
                task.spawn(function()
                    while legBaitSeq == mySeq
                        and getgenv().FishmanSession == mySession
                        and getgenv().FishmanState._running
                        and opts.T_AutoLegBait and opts.T_AutoLegBait.Value
                        and opts.T_MoveToFishingSpot and opts.T_MoveToFishingSpot.Value do
                        task.wait(0.25)
                    end
                    if legBaitSeq == mySeq
                        and getgenv().FishmanSession == mySession
                        and getgenv().FishmanState._running
                        and opts.T_AutoLegBait and opts.T_AutoLegBait.Value then
                        local c = LocalPlayer.Character
                        local root = c and c:FindFirstChild("HumanoidRootPart")
                        if root and (root.Position - spotPos).Magnitude <= 5 then
                            task.wait(1)
                            if legBaitSeq == mySeq
                                and getgenv().FishmanSession == mySession
                                and getgenv().FishmanState._running
                                and opts.T_AutoLegBait and opts.T_AutoLegBait.Value then
                                setLegBaitFeatures(opts, true)
                            end
                        end
                    end
                end)
            else
                setLegBaitFeatures(opts, true)
            end
        end
    })
    local moveSpotInit = false
    getgenv().FishmanState.Tabs.Fishing:AddToggle("T_MoveToFishingSpot", {
        Title = "Move to Fishing Spot",
        Default = false,
        Callback = function(Value)
            if not moveSpotInit then
                moveSpotInit = true
                return
            end
            if isLobby then
                if Value and getgenv().FishmanState.Fluent then
                    getgenv().FishmanState.Fluent:Notify({ Title = "Error", Content = "Cannot move in Lobby!", Duration = 3 })
                    if getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_MoveToFishingSpot then
                        getgenv().FishmanState.Fluent.Options.T_MoveToFishingSpot:SetValue(false)
                    end
                end
                return
            end
            if Value then
                if getgenv().FishmanState.Model and getgenv().FishmanState.Model.MoveToFishingSpot then
                    getgenv().FishmanState.Model.MoveToFishingSpot(Vector3.new(104, 9, -56))
                end
            else
                if getgenv().FishmanState.Model and getgenv().FishmanState.Model.StopMovingToFishingSpot then
                    getgenv().FishmanState.Model.StopMovingToFishingSpot()
                end
            end
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
    getgenv().FishmanState.Tabs.Fishing:AddSlider("S_ShipSpeed", {
        Title = "Return To Ship Speed",
        Description = "Adjusts flight speed (300 is recommended)",
        Default = 60,
        Min = 50,
        Max = 1000,
        Rounding = 0,
        Callback = function(Value)
            getgenv().FishmanState.Model.State.shipSpeed = Value
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
        if backpackConn then
            if getgenv().FishmanState.removeConn then
                getgenv().FishmanState.removeConn(backpackConn)
            else
                pcall(function() backpackConn:Disconnect() end)
            end
            backpackConn = nil
        end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack and autoStoreEnabled then
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
                        if autoStoreEnabled then
                            setupFruitListener()
                        end
                    end)
                    getgenv().FishmanState.addConn(charConn)
                end
            else
                if backpackConn then 
                    if getgenv().FishmanState.removeConn then
                        getgenv().FishmanState.removeConn(backpackConn)
                    else
                        pcall(function() backpackConn:Disconnect() end)
                    end
                    backpackConn = nil 
                end
                if charConn then
                    if getgenv().FishmanState.removeConn then
                        getgenv().FishmanState.removeConn(charConn)
                    else
                        pcall(function() charConn:Disconnect() end)
                    end
                    charConn = nil
                end
            end
        end 
    })

    -- Travel arrival watcher (auto-enables Auto Fish on arrival at bait)
    task.spawn(function()
        while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and task.wait(1) do
            if getgenv().FishmanState.Model.State.travelMessage == "Arrived at Bait" and getgenv().FishmanState.Model.State.waitingForArrivalToFish then
                getgenv().FishmanState.Model.State.waitingForArrivalToFish = false
                if getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_Fish then
                    getgenv().FishmanState.Fluent.Options.T_Fish:SetValue(true)
                end
            end
        end
    end)

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
                while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isMegStacking do
                    local char = game:GetService("Players").LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local isCyborgRunning = getgenv().FishmanState.Model and getgenv().FishmanState.Model.State and getgenv().FishmanState.Model.State.isAutoFarming
                    if hrp and hrp:FindFirstChild("AntiGravity") and not getgenv().FishmanState.Model.State.isRefillingMegBait and not getgenv().FishmanState.Model.State.isAutoTraveling and not isCyborgRunning then
                        task.wait(1)
                        isCyborgRunning = getgenv().FishmanState.Model and getgenv().FishmanState.Model.State and getgenv().FishmanState.Model.State.isAutoFarming
                        if hrp and hrp:FindFirstChild("AntiGravity") and not getgenv().FishmanState.Model.State.isRefillingMegBait and not getgenv().FishmanState.Model.State.isAutoTraveling and not isCyborgRunning then
                            print("⚠️ [MegStack] Safeguard triggered: In Air / AntiGravity detected. Disabling MegStack!")
                            if getgenv().FishmanState.Fluent.Options.T_MegStack then getgenv().FishmanState.Fluent.Options.T_MegStack:SetValue(false) end
                            break
                        end
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
                        
                        -- The Cyborg Autofarm will take over monitoring from here!
                        if getgenv().FishmanState.Fluent.Options.T_CyborgAuto then
                            getgenv().FishmanState.Fluent.Options.T_CyborgAuto:SetValue(true)
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
                while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isMegStackPassive do
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
                        while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and getgenv().FishmanState.Model.countMegalodons() > 0 and getgenv().FishmanState.Model.State.isMegStackPassive and waitTime < 180 do
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
                while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isHoverboardESP do
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
                while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and getgenv().FishmanState.Model.State.isMegESP do
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
            
            -- Unequip Fishing Rod and Equip Cyborg Weapon so skills can fire instantly!
            local char = game:GetService("Players").LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and tool.Name ~= "Cyborg" then
                    getgenv()._previousWeapon = tool.Name
                end
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
        else
            -- Restore auto store fruit if it was previously on
            if getgenv()._wasAutoStoreFruitOn and getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options and getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit then
                getgenv().FishmanState.Fluent.Options.T_AutoStoreFruit:SetValue(true)
                getgenv()._wasAutoStoreFruitOn = false
                getgenv().FishmanState.Fluent:Notify({ Title = "System", Content = "Auto Store Fruit resumed", Duration = 3 })
            end
            
            -- Re-equip the previous weapon if we saved one
            local char = game:GetService("Players").LocalPlayer.Character
            if char and getgenv()._previousWeapon then
                char.Humanoid:UnequipTools()
                task.wait(0.2)
                local backpack = game:GetService("Players").LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    local prevWeapon = backpack:FindFirstChild(getgenv()._previousWeapon)
                    if prevWeapon then
                        char.Humanoid:EquipTool(prevWeapon)
                        print("✅ [Cyborg Autofarm] Re-equipped previous weapon: " .. getgenv()._previousWeapon)
                    end
                end
                getgenv()._previousWeapon = nil
            end
        end

        task.spawn(function()
            if Value then
                print("triggering title: \"Megalodon Slayer\"")
                local args = { "Megalodon Slayer" }
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args))
                
                -- Megalodon Stack seamless toggle logic
                if getgenv().FishmanState.Fluent.Options.T_MegStack and getgenv().FishmanState.Fluent.Options.T_MegStack.Value == true then
                    getgenv()._CyborgPausedMegStack = true
                    getgenv().FishmanState.Fluent.Options.T_MegStack:SetValue(false)
                end
                
                -- Monitor kills if triggered by MegStack, turn off automatically when dead
                if getgenv()._CyborgPausedMegStack then
                    task.spawn(function()
                        local waitTime = 0
                        local lastCount = getgenv().FishmanState.Model.countMegalodons()
                        while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and getgenv().FishmanState.Fluent.Options.T_CyborgAuto.Value == true and getgenv().FishmanState.Model.countMegalodons() > 0 and waitTime < 180 do
                            task.wait(1)
                            waitTime = waitTime + 1
                            local curCount = getgenv().FishmanState.Model.countMegalodons()
                            if curCount < lastCount then
                                waitTime = 0
                                lastCount = curCount
                            end
                        end
                        if getgenv().FishmanState.Fluent.Options.T_CyborgAuto.Value == true then
                            getgenv().FishmanState.Fluent.Options.T_CyborgAuto:SetValue(false)
                        end
                    end)
                end
                
            else
                print("reverting title: \"Skilled Fisherman\"")
                local args = { "Skilled Fisherman" }
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args))
                
                -- Restore Megalodon Stack if it was paused by Cyborg Autofarm
                if getgenv()._CyborgPausedMegStack then
                    getgenv()._CyborgPausedMegStack = false
                    if getgenv().FishmanState.Fluent.Options.T_MegStack then
                        getgenv().FishmanState.Fluent.Options.T_MegStack:SetValue(true)
                    end
                end
            end
        end)

        if Value and not getgenv().ToggleCyborgAutofarm then
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/protov4_nofactory.lua"))()
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
        local scriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/CombinedAutoLoad.lua?t=" .. tostring(tick())
        
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
                local npcsFolder = workspace:FindFirstChild("NPCs")
                local searchScope = npcsFolder and npcsFolder:GetChildren() or workspace:GetDescendants()
                for _, obj in ipairs(searchScope) do
                    if obj:IsA("Model") and string.find(string.lower(obj.Name), "merchant") and obj:FindFirstChild("HumanoidRootPart") then
                        targetPos = obj.HumanoidRootPart.Position
                        print("[Logic] Found Merchant Model in Workspace at: ", targetPos)
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
                        
                        local merchantCharParts = {}
                        if hrp.Parent then
                            for _, part in ipairs(hrp.Parent:GetDescendants()) do
                                if part:IsA("BasePart") then table.insert(merchantCharParts, part) end
                            end
                        end

                        for i, waypoint in ipairs(waypoints) do
                            if not getgenv().FishmanState._running then break end
                            local wpPos = waypoint.Position
                            wpPos = wpPos + Vector3.new(0, 5, 0)
                            
                            local stuckTimer = 0
                            local lastDist = (hrp.Position - wpPos).Magnitude
                            
                            while getgenv().FishmanSession == mySession and getgenv().FishmanState._running and hrp.Parent do
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
                                    for _, part in ipairs(merchantCharParts) do
                                        if part.Parent and part.CanCollide then
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
-- 📊 STATUS TAB UI (Session Stats & Legendary Fish Tracker)
-- ======================================================================
local SessionSummaryPara = getgenv().FishmanState.Tabs.Status:AddParagraph({
    Title = "📊 Session Overview",
    Content = "Loading session stats..."
})

local LegendaryBreakdownPara = getgenv().FishmanState.Tabs.Status:AddParagraph({
    Title = "🐟 Legendary Fish Caught (This Session)",
    Content = "None caught yet."
})

local FruitCheckerPara = getgenv().FishmanState.Tabs.Status:AddParagraph({
    Title = "🍎 Fruits in Inventory",
    Content = "Checking fruits..."
})

getgenv().FishmanState.Tabs.Status:AddButton({
    Title = "🔄 Reset Session Stats",
    Description = "Resets session timer, cast counter, and legendary catch counts.",
    Callback = function()
        if getgenv().FishmanState.ResetSessionStats then
            getgenv().FishmanState.ResetSessionStats()
        end
        if getgenv().FishmanState.Fluent then
            getgenv().FishmanState.Fluent:Notify({ Title = "Session Stats", Content = "Session stats reset!", Duration = 3 })
        end
    end
})

task.spawn(function()
    local function formatDuration(secs)
        secs = math.max(0, math.floor(secs))
        local h = math.floor(secs / 3600)
        local m = math.floor((secs % 3600) / 60)
        local s = secs % 60
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    while getgenv().FishmanSession == mySession and getgenv().FishmanState._running do
        local stats = getgenv().FishmanState.SessionStats
        if stats then
            local elapsed = math.max(1, os.time() - (stats.startTime or os.time()))
            local totalLeg = stats.totalLegendaryCaught or 0
            local casts = stats.totalCasts or 0
            local perHour = (totalLeg / elapsed) * 3600

            local legBaitCount = 0
            local invData = nil
            if not isLobby and getgenv().FishmanState.Model and getgenv().FishmanState.Model.GetInventoryData then
                invData = getgenv().FishmanState.Model.GetInventoryData()
                if invData and getgenv().FishmanState.UpdateSessionStats then
                    getgenv().FishmanState.UpdateSessionStats(invData)
                    totalLeg = stats.totalLegendaryCaught or 0
                    perHour = (totalLeg / elapsed) * 3600
                end
                if getgenv().FishmanState.Model.GetLegendaryBaitCount then
                    legBaitCount = getgenv().FishmanState.Model.GetLegendaryBaitCount(invData)
                end
            end

            SessionSummaryPara:SetDesc(string.format(
                "Uptime: %s\nTotal Casts: %d\nLegendary Caught: %d (%.1f/hr)\nLegendary Bait: %d/300",
                formatDuration(elapsed), casts, totalLeg, perHour, legBaitCount
            ))

            local legList = getgenv().FishmanState.LEGENDARY_FISHES or {}
            local lines = {}
            for _, fishName in ipairs(legList) do
                local caught = (stats.legendaryByType and stats.legendaryByType[fishName]) or 0
                local inBag = invData and (tonumber(invData[fishName]) or 0) or 0
                table.insert(lines, string.format("- %s: %d caught (in bag: %d)", fishName, caught, inBag))
            end
            LegendaryBreakdownPara:SetDesc(#lines > 0 and table.concat(lines, "\n ") or "Waiting for data...")

            if FruitCheckerPara then
                if getgenv().FishmanState.getFruitStatus then
                    local fruitStatus = getgenv().FishmanState.getFruitStatus(getgenv().FishmanState.targetFruits, invData)
                    local bpLines = {}
                    for name, count in pairs(fruitStatus.backpack) do
                        table.insert(bpLines, string.format("- %dx %s", count, name))
                    end
                    table.sort(bpLines)

                    local bpText = (#bpLines > 0) and ("\n" .. table.concat(bpLines, "\n")) or " None"
                    local storedText = (#fruitStatus.stored > 0) and table.concat(fruitStatus.stored, ", ") or "None"
                    FruitCheckerPara:SetDesc(string.format("Backpack (Unstored):%s\nStored Inventory: %s", bpText, storedText))
                else
                    FruitCheckerPara:SetDesc("Fruit checker unavailable.")
                end
            end
        end
        task.wait(2)
    end
end)

-- ======================================================================
-- ⚙️ SETTINGS TAB UI
-- ======================================================================
getgenv().FishmanState.Tabs.Settings:AddToggle("T_CloseOnDisconnect", { 
    Title = "Safeguard: Close Roblox on Disconnect / Restart", 
    Description = "Automatically shuts down and closes the Roblox app if disconnected, kicked, or the server restarts.",
    Default = (GlobalMem.FishmanCloseOnDisconnect ~= nil) and GlobalMem.FishmanCloseOnDisconnect or true, 
    Callback = function(Value)
        GlobalMem.FishmanCloseOnDisconnect = Value
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
    Default = 18,
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
    Description = "Shuts down the current script and executes the latest version from GitHub.",
    Callback = function()
        task.spawn(function()
            if getgenv().FishmanState.Fluent then
                getgenv().FishmanState.Fluent:Notify({ Title = "Updating", Content = "Shutting down & fetching latest version...", Duration = 3 })
            end
            task.wait(0.5)

            if getgenv().FishmanState.ShutdownEverything then
                pcall(getgenv().FishmanState.ShutdownEverything)
            end
            if Window and Window.Destroy then
                pcall(function() Window:Destroy() end)
            end
            pcall(function()
                local coreGui = game:GetService("CoreGui")
                for _, gui in ipairs(coreGui:GetChildren()) do
                    if gui.Name == "FishmanHubCustom" or gui.Name == "FishmanNotify" then
                        gui:Destroy()
                    end
                end
            end)

            getgenv().FishmanLoaderLastExecuted = nil
            task.wait(0.3)

            local cacheBust = "?cb=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
            local loaderURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/loader.lua" .. cacheBust
            local ok, err = pcall(function()
                loadstring(game:HttpGet(loaderURL))()
            end)
            if not ok then
                warn("[Fishman Update] loader.lua failed (" .. tostring(err) .. "), falling back to Main.lua...")
                local mainURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/Modularized/Main.lua" .. cacheBust
                local okMain, errMain = pcall(function()
                    loadstring(game:HttpGet(mainURL))()
                end)
                if not okMain then
                    warn("[Fishman Update] Fallback Main.lua also failed: " .. tostring(errMain))
                end
            end
        end)
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
                local opts = getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options
                local function optVal(name)
                    return (opts and opts[name] and opts[name].Value) or false
                end
                -- Save current task states
                savedState = {
                    isFishing = getgenv().FishmanState.Model.State.isFishing,
                    autoBuy = getgenv().FishmanState.Model.State.autoBuy,
                    autoSell = getgenv().FishmanState.Model.State.autoSell,
                    isAutoTraveling = getgenv().FishmanState.Model.State.isAutoTraveling,
                    autoCraft = getgenv().FishmanState.Model.State.autoCraft,
                    isCurrentlyCrafting = getgenv().FishmanState.Model.State.isCurrentlyCrafting,
                    strictReel = optVal("T_StrictReel"),
                    autoLegBait = optVal("T_AutoLegBait"),
                    moveToSpot = optVal("T_MoveToFishingSpot"),
                    antiLag = optVal("T_AntiLag"),
                    deepSea = optVal("T_DeepSea"),
                    megStack = optVal("T_MegStack"),
                    megStackPassive = optVal("T_MegStackPassive"),
                    megStackLoc = optVal("T_MegStackLoc"),
                    autoReturn = optVal("T_AutoReturn"),
                    autoStoreFruit = optVal("T_AutoStoreFruit"),
                    cyborgAuto = optVal("T_CyborgAuto")
                }

                -- Force stop everything instantly
                getgenv().FishmanState.Model.State.isFishing = false
                getgenv().FishmanState.Model.State.autoBuy = false
                getgenv().FishmanState.Model.State.autoSell = false
                getgenv().FishmanState.Model.State.isAutoTraveling = false
                getgenv().FishmanState.Model.State.autoCraft = false
                getgenv().FishmanState.Model.State.isCurrentlyCrafting = false
                getgenv().FishmanState.Model.State.isCraftFlying = false
                getgenv().FishmanState.Model.State.isBuying = false
                getgenv().FishmanState.Model.State.strictReel = false
                
                -- Update UI toggles to visually show they are [OFF]
                if opts then
                    if opts.T_AutoLegBait then opts.T_AutoLegBait:SetValue(false, true) end
                    if opts.T_Fish then opts.T_Fish:SetValue(false) end
                    if opts.T_StrictReel then opts.T_StrictReel:SetValue(false) end
                    if opts.T_Buy then opts.T_Buy:SetValue(false) end
                    if opts.T_Sell then opts.T_Sell:SetValue(false) end
                    if opts.T_Travel then opts.T_Travel:SetValue(false) end
                    if opts.T_Craft then opts.T_Craft:SetValue(false) end
                    if opts.T_MoveToFishingSpot then opts.T_MoveToFishingSpot:SetValue(false) end
                    if opts.T_AntiLag then opts.T_AntiLag:SetValue(false) end
                    if opts.T_DeepSea then opts.T_DeepSea:SetValue(false) end
                    if opts.T_MegStack then opts.T_MegStack:SetValue(false) end
                    if opts.T_MegStackPassive then opts.T_MegStackPassive:SetValue(false) end
                    if opts.T_MegStackLoc then opts.T_MegStackLoc:SetValue(false) end
                    if opts.T_AutoReturn then opts.T_AutoReturn:SetValue(false) end
                    if opts.T_AutoStoreFruit then opts.T_AutoStoreFruit:SetValue(false) end
                    if opts.T_CyborgAuto then opts.T_CyborgAuto:SetValue(false) end
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
                local opts = getgenv().FishmanState.Fluent and getgenv().FishmanState.Fluent.Options
                if opts then
                    if opts.T_AutoLegBait and savedState.autoLegBait then opts.T_AutoLegBait:SetValue(true, true) end
                    if opts.T_Fish then opts.T_Fish:SetValue(getgenv().FishmanState.Model.State.isFishing) end
                    if opts.T_StrictReel and savedState.strictReel then opts.T_StrictReel:SetValue(true) end
                    if opts.T_Buy then opts.T_Buy:SetValue(getgenv().FishmanState.Model.State.autoBuy) end
                    if opts.T_Sell then opts.T_Sell:SetValue(getgenv().FishmanState.Model.State.autoSell) end
                    if opts.T_Travel then opts.T_Travel:SetValue(getgenv().FishmanState.Model.State.isAutoTraveling) end
                    if opts.T_Craft then opts.T_Craft:SetValue(getgenv().FishmanState.Model.State.autoCraft) end
                    if opts.T_MoveToFishingSpot and savedState.moveToSpot then opts.T_MoveToFishingSpot:SetValue(true) end
                    if opts.T_AntiLag and savedState.antiLag then opts.T_AntiLag:SetValue(true) end
                    if opts.T_DeepSea and savedState.deepSea then opts.T_DeepSea:SetValue(true) end
                    if opts.T_MegStack and savedState.megStack then opts.T_MegStack:SetValue(true) end
                    if opts.T_MegStackPassive and savedState.megStackPassive then opts.T_MegStackPassive:SetValue(true) end
                    if opts.T_MegStackLoc and savedState.megStackLoc then opts.T_MegStackLoc:SetValue(true) end
                    if opts.T_AutoReturn and savedState.autoReturn then opts.T_AutoReturn:SetValue(true) end
                    if opts.T_AutoStoreFruit and savedState.autoStoreFruit then opts.T_AutoStoreFruit:SetValue(true) end
                    if opts.T_CyborgAuto and savedState.cyborgAuto then opts.T_CyborgAuto:SetValue(true) end
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
