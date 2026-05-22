local View = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

function View.Build(onToggleCallback)
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

    -- Dragging Logic completely isolated in View
    local dragging, dragInput, dragStart, startPos
    
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    toggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Button Click Event
    local isFarming = false
    toggleBtn.MouseButton1Click:Connect(function()
        isFarming = not isFarming
        
        -- Update UI visuals
        toggleBtn.Text = isFarming and "AUTO FARM: ON" or "AUTO FARM: OFF"
        toggleBtn.BackgroundColor3 = isFarming and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(255, 85, 85)
        
        -- Tell Controller what happened
        onToggleCallback(isFarming)
    end)
end

return View