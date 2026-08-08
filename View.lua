local View = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

function View.Build(onToggleCallback, onCloseCallback)
    local LocalPlayer = Players.LocalPlayer
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFarmGui"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
    if not success then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 180, 0, 50)
    toggleBtn.Position = UDim2.new(0.5, -90, 0.1, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    toggleBtn.Text = "AUTO FARM: OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.Parent = screenGui

    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

    -- Version Label
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Name = "VersionLabel"
    versionLabel.Size = UDim2.new(1, 0, 0, 20)
    versionLabel.Position = UDim2.new(0, 0, 0, -22)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Active = true
    versionLabel.Text = "AUTOFARM V1.2"
    versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    versionLabel.Font = Enum.Font.GothamBold
    versionLabel.TextSize = 12
    versionLabel.TextXAlignment = Enum.TextXAlignment.Center
    versionLabel.Parent = toggleBtn

    local labelStroke = Instance.new("UIStroke", versionLabel)
    labelStroke.Color = Color3.fromRGB(0, 0, 0)
    labelStroke.Thickness = 1.2
    labelStroke.Transparency = 0.3

    -- Close / Cleanup Button ("X")
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 50)
    closeBtn.Position = UDim2.new(1, 6, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = toggleBtn

    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", closeBtn)
    stroke.Color = Color3.fromRGB(255, 85, 85)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3

    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos

    local function setupDragging(button)
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = toggleBtn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)

        button.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
    end

    setupDragging(toggleBtn)
    setupDragging(closeBtn)
    setupDragging(versionLabel)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- State Management Helper
    local isFarming = false

    local function setFarmingState(state)
        if isFarming == state then return end
        isFarming = state
        
        -- Update UI visuals
        toggleBtn.Text = isFarming and "AUTO FARM: ON" or "AUTO FARM: OFF"
        toggleBtn.BackgroundColor3 = isFarming and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(255, 85, 85)
        
        -- Tell Controller what happened
        onToggleCallback(isFarming)
    end

    local allowAutoStart = true

    -- Manual Button Click Event
    toggleBtn.MouseButton1Click:Connect(function()
        allowAutoStart = false -- If you manually click, it stops the auto-starter from interfering
        setFarmingState(not isFarming)
    end)

    -- Close Button Click Event (Clean Up)
    closeBtn.MouseButton1Click:Connect(function()
        allowAutoStart = false
        setFarmingState(false)
        if onCloseCallback then
            onCloseCallback()
        end
        screenGui:Destroy()
    end)

    -- Map Detection Auto-Start Logic
    task.spawn(function()
        -- 1. Check the workspace and wait infinitely until the "Islands" folder exists
        local islands = Workspace:WaitForChild("Islands", 9e9)
        
        -- 2. Wait infinitely until "Fishman Island" physically exists inside the folder
        islands:WaitForChild("Fishman Island", 9e9)
        
        -- 3. The island is completely loaded! Wait exactly 5 seconds.
        task.wait(5)
        
        -- 4. Start the farm (as long as you haven't manually clicked the button yet)
        if allowAutoStart and not isFarming then
            allowAutoStart = false
            setFarmingState(true)
        end
    end)
end

return View