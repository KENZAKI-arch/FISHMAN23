local redzlib = {}

function redzlib:MakeWindow(config)
    local Window = {}
    
    -- Cleanup previous GUI
    local coreGui = game:GetService("CoreGui")
    local oldGui = coreGui:FindFirstChild("FishmanMobileGUI")
    if oldGui then oldGui:Destroy() end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "FishmanMobileGUI"
    gui.ResetOnSpawn = false
    gui.Parent = coreGui
    Window.Gui = gui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = (config.Title or "Hub") .. " - " .. (config.SubTitle or "")
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = mainFrame
    
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(0, 140, 1, -50)
    tabContainer.Position = UDim2.new(0, 10, 0, 40)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ScrollBarThickness = 2
    tabContainer.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabContainer
    
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -170, 1, -50)
    contentContainer.Position = UDim2.new(0, 160, 0, 40)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    Window.Tabs = {}
    local currentTabFrame = nil
    
    function Window:Destroy()
        if gui then gui:Destroy() end
    end
    
    function Window:Toggle()
        mainFrame.Visible = not mainFrame.Visible
    end
    
    function Window:MakeTab(info)
        local tabName = (type(info) == "table" and info[1]) or info.Name or "Tab"
        local Tab = {}
        
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -10, 0, 35)
        tabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabBtn.Text = tabName
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.TextSize = 14
        tabBtn.Parent = tabContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = tabBtn
        
        local contentFrame = Instance.new("ScrollingFrame")
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.ScrollBarThickness = 4
        contentFrame.Visible = false
        contentFrame.Parent = contentContainer
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding = UDim.new(0, 5)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = contentFrame
        
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
        end)
        
        if not currentTabFrame then
            currentTabFrame = contentFrame
            contentFrame.Visible = true
            tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        end
        
        tabBtn.MouseButton1Click:Connect(function()
            if currentTabFrame then
                currentTabFrame.Visible = false
            end
            for _, c in ipairs(tabContainer:GetChildren()) do
                if c:IsA("TextButton") then
                    c.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                    c.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
            end
            currentTabFrame = contentFrame
            contentFrame.Visible = true
            tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        end)
        
        function Tab:AddButton(btnInfo)
            local name = (type(btnInfo) == "table" and btnInfo[1]) or btnInfo.Name
            local cb = (type(btnInfo) == "table" and btnInfo[2]) or btnInfo.Callback
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 35)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = name or "Button"
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Parent = contentFrame
            
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = btn
            
            btn.MouseButton1Click:Connect(function()
                if cb then cb() end
            end)
            return {
                Fire = function() if cb then cb() end end
            }
        end
        
        function Tab:AddToggle(toggleInfo)
            local name = toggleInfo.Name or "Toggle"
            local cb = toggleInfo.Callback
            local default = toggleInfo.Default or false
            local state = default
            
            local ToggleObj = {}
            ToggleObj.Value = state
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 35)
            btn.BackgroundColor3 = state and Color3.fromRGB(60, 120, 255) or Color3.fromRGB(40, 40, 40)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = name .. " : " .. (state and "ON" or "OFF")
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Parent = contentFrame
            
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = btn
            
            local function updateVisuals()
                btn.BackgroundColor3 = ToggleObj.Value and Color3.fromRGB(60, 120, 255) or Color3.fromRGB(40, 40, 40)
                btn.Text = name .. " : " .. (ToggleObj.Value and "ON" or "OFF")
            end
            
            btn.MouseButton1Click:Connect(function()
                ToggleObj:Set(not ToggleObj.Value)
            end)
            
            function ToggleObj:Set(val)
                ToggleObj.Value = val
                updateVisuals()
                if cb then cb(ToggleObj.Value) end
            end
            
            -- trigger default
            task.spawn(function()
                if cb and ToggleObj.Value then cb(ToggleObj.Value) end
            end)
            
            return ToggleObj
        end
        
        function Tab:AddParagraph(paraInfo)
            local title = (type(paraInfo) == "table" and paraInfo[1]) or paraInfo.Title or ""
            local desc = (type(paraInfo) == "table" and paraInfo[2]) or paraInfo.Text or ""
            
            local ParaObj = {}
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 50)
            frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            frame.Parent = contentFrame
            
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame
            
            local titleLbl = Instance.new("TextLabel")
            titleLbl.Size = UDim2.new(1, -10, 0, 20)
            titleLbl.Position = UDim2.new(0, 5, 0, 5)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Text = title
            titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            titleLbl.Font = Enum.Font.GothamBold
            titleLbl.TextSize = 14
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.Parent = frame
            
            local descLbl = Instance.new("TextLabel")
            descLbl.Size = UDim2.new(1, -10, 0, 20)
            descLbl.Position = UDim2.new(0, 5, 0, 25)
            descLbl.BackgroundTransparency = 1
            descLbl.Text = desc
            descLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 12
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.Parent = frame
            
            function ParaObj:SetDesc(newDesc)
                descLbl.Text = tostring(newDesc)
            end
            
            return ParaObj
        end
        
        function Tab:AddTextBox(tbInfo)
            local name = tbInfo.Name or "TextBox"
            local default = tbInfo.Default or ""
            local cb = tbInfo.Callback
            
            local TBObj = {}
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 35)
            frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            frame.Parent = contentFrame
            
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, -5, 1, 0)
            lbl.Position = UDim2.new(0, 5, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = name
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = frame
            
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0.5, -5, 0, 25)
            box.Position = UDim2.new(0.5, 0, 0, 5)
            box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            box.TextColor3 = Color3.fromRGB(255, 255, 255)
            box.Text = tostring(default)
            box.Font = Enum.Font.Gotham
            box.TextSize = 12
            box.Parent = frame
            box.ClearTextOnFocus = false
            
            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 4)
            bc.Parent = box
            
            box.FocusLost:Connect(function()
                if cb then cb(box.Text) end
            end)
            
            function TBObj:Set(val)
                box.Text = tostring(val)
                if cb then cb(val) end
            end
            
            return TBObj
        end
        
        function Tab:AddDropdown(ddInfo)
            local name = ddInfo.Name or "Dropdown"
            local options = ddInfo.Options or {}
            local default = ddInfo.Default or (options[1] or "")
            local cb = ddInfo.Callback
            
            local DDObj = {}
            local isOpen = false
            
            local mainFrame = Instance.new("Frame")
            mainFrame.Size = UDim2.new(1, -10, 0, 35)
            mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            mainFrame.ClipsDescendants = true
            mainFrame.Parent = contentFrame
            
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = mainFrame
            
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(1, 0, 0, 35)
            toggleBtn.BackgroundTransparency = 1
            toggleBtn.Text = name .. " : " .. tostring(default)
            toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggleBtn.Font = Enum.Font.Gotham
            toggleBtn.TextSize = 14
            toggleBtn.Parent = mainFrame
            
            local itemsFrame = Instance.new("ScrollingFrame")
            itemsFrame.Size = UDim2.new(1, 0, 1, -35)
            itemsFrame.Position = UDim2.new(0, 0, 0, 35)
            itemsFrame.BackgroundTransparency = 1
            itemsFrame.ScrollBarThickness = 2
            itemsFrame.Parent = mainFrame
            
            local ilayout = Instance.new("UIListLayout")
            ilayout.Parent = itemsFrame
            
            local function populate(opts)
                for _, child in ipairs(itemsFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, opt in ipairs(opts) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1, 0, 0, 25)
                    b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    b.TextColor3 = Color3.fromRGB(200, 200, 200)
                    b.Text = tostring(opt)
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 12
                    b.Parent = itemsFrame
                    
                    b.MouseButton1Click:Connect(function()
                        toggleBtn.Text = name .. " : " .. tostring(opt)
                        isOpen = false
                        mainFrame.Size = UDim2.new(1, -10, 0, 35)
                        if cb then cb(opt) end
                    end)
                end
                itemsFrame.CanvasSize = UDim2.new(0, 0, 0, #opts * 25)
            end
            
            populate(options)
            
            toggleBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                mainFrame.Size = isOpen and UDim2.new(1, -10, 0, 135) or UDim2.new(1, -10, 0, 35)
            end)
            
            function DDObj:SetValues(newOpts)
                options = newOpts
                populate(options)
            end
            
            function DDObj:Set(val)
                toggleBtn.Text = name .. " : " .. tostring(val)
                if cb then cb(val) end
            end
            
            return DDObj
        end
        
        function Tab:AddSlider(slInfo)
            local name = slInfo.Name or "Slider"
            local min = slInfo.Min or 0
            local max = slInfo.Max or 100
            local default = slInfo.Default or min
            local cb = slInfo.Callback
            
            local SLObj = {}
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 50)
            frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            frame.Parent = contentFrame
            
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 0, 20)
            lbl.Position = UDim2.new(0, 5, 0, 5)
            lbl.BackgroundTransparency = 1
            lbl.Text = name .. " : " .. tostring(default)
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = frame
            
            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -20, 0, 6)
            barBg.Position = UDim2.new(0, 10, 0, 35)
            barBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            barBg.Parent = frame
            
            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
            barFill.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
            barFill.Parent = barBg
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.Parent = barBg
            
            local dragging = false
            btn.MouseButton1Down:Connect(function() dragging = true end)
            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            
            game:GetService("UserInputService").InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local absPos = barBg.AbsolutePosition.X
                    local absSize = barBg.AbsoluteSize.X
                    local mousePos = input.Position.X
                    local percent = math.clamp((mousePos - absPos) / absSize, 0, 1)
                    barFill.Size = UDim2.new(percent, 0, 1, 0)
                    
                    local val = math.floor(min + (max - min) * percent)
                    lbl.Text = name .. " : " .. tostring(val)
                    if cb then cb(val) end
                end
            end)
            
            function SLObj:Set(val)
                local percent = math.clamp((val - min) / (max - min), 0, 1)
                barFill.Size = UDim2.new(percent, 0, 1, 0)
                lbl.Text = name .. " : " .. tostring(val)
                if cb then cb(val) end
            end
            
            return SLObj
        end
        
        return Tab
    end
    
    return Window
end
