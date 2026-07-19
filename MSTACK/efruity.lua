local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local targetFruits = {
    "Dragon", "Venom", "Mochi", "Soul", "Pika", "Buddha", "Magu", "Goro", "Goru",
    "Hie", "Kage", "Mera", "Tori", "Pteranodon", "Smoke", "Yami", "Suna", "Yuki", "Ope", "Zushi", "Ito", "Paw"
}

local function checkFruits(fruitList)
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    if not character or not backpack then return end
    
    local inventoryCounts = {}
    local foundAny = false
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local toolName = string.lower(tool.Name)
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    inventoryCounts[tool.Name] = (inventoryCounts[tool.Name] or 0) + 1
                    foundAny = true
                    break
                end
            end
        end
    end
    
    if foundAny then
        local lines = {}
        for name, count in pairs(inventoryCounts) do
            table.insert(lines, count .. "x " .. name)
        end
        local message = table.concat(lines, ", ")
        
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Fruits Found",
                Text = message,
                Duration = 5
            })
        end)
    else
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Fruit Check",
                Text = "No target fruits found.",
                Duration = 3
            })
        end)
    end
end

local function storeFruits(fruitList)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    if not character or not humanoid or not backpack then return end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local toolName = string.lower(tool.Name)
            local isTargetFruit = false
            
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    isTargetFruit = true
                    break
                end
            end
            
            if isTargetFruit then
                -- Force-equip the tool (fruit)
                humanoid:EquipTool(tool)
                
                -- Wait a split second to ensure the server registers the equip
                task.wait(0.2)
                
                -- Fire the remote to attempt to store it
                ReplicatedStorage.Events.FruitStorage:InvokeServer(true)
                
                -- Wait a moment to let the server process
                task.wait(0.5)
                
                -- Check if the fruit is still in the inventory (meaning storing failed)
                if tool.Parent == character or tool.Parent == backpack then
                    -- Ensure it's equipped before dropping
                    humanoid:EquipTool(tool)
                    task.wait(0.1)
                    
                    -- Simulate pressing Backspace to drop
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
                    task.wait(0.1)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
                    
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "Fruit Dropped",
                            Text = "Couldn't store, so dropped: " .. tool.Name,
                            Duration = 3
                        })
                    end)
                else
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "Fruit Stored",
                            Text = "Successfully stored: " .. tool.Name,
                            Duration = 3
                        })
                    end)
                end
                
                -- Wait before trying the next item
                task.wait(0.5)
            end
        end
    end
end

local function dropFruits(fruitList)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    if not character or not humanoid or not backpack then return end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local toolName = string.lower(tool.Name)
            local isTargetFruit = false
            
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    isTargetFruit = true
                    break
                end
            end
            
            if isTargetFruit then
                -- Force-equip the tool (fruit)
                humanoid:EquipTool(tool)
                
                -- Wait a split second to ensure the server registers the equip
                task.wait(0.2)
                
                -- Simulate pressing Backspace to drop
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
                
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "Dropping Fruit",
                        Text = "Dropped: " .. tool.Name,
                        Duration = 3
                    })
                end)
                
                -- Wait before trying the next item
                task.wait(0.5)
            end
        end
    end
end

local function createUI()
    local guiName = "FruitManagerGUI"
    
    -- Clean up old UI if it exists
    local existingGui = CoreGui:FindFirstChild(guiName) or Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(guiName)
    if existingGui then
        existingGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = guiName
    
    -- Try attaching to CoreGui for exploit executors, fallback to PlayerGui
    local success, _ = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not success then
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 180)
    frame.Position = UDim2.new(0.5, -100, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "Fruit Manager"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
    minimizeBtn.Position = UDim2.new(1, -50, 0, 2)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "-"
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.TextSize = 18
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = frame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -25, 0, 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 0.3, 0.3)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = frame
    
    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0.9, 0, 0, 30)
    checkBtn.Position = UDim2.new(0.05, 0, 0, 35)
    checkBtn.Text = "Check Fruits"
    checkBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    checkBtn.TextColor3 = Color3.new(1, 1, 1)
    checkBtn.Font = Enum.Font.Gotham
    checkBtn.TextSize = 14
    checkBtn.Parent = frame
    
    local checkBtnCorner = Instance.new("UICorner")
    checkBtnCorner.CornerRadius = UDim.new(0, 6)
    checkBtnCorner.Parent = checkBtn
    
    local storeBtn = Instance.new("TextButton")
    storeBtn.Size = UDim2.new(0.9, 0, 0, 30)
    storeBtn.Position = UDim2.new(0.05, 0, 0, 70)
    storeBtn.Text = "Store Fruits"
    storeBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    storeBtn.TextColor3 = Color3.new(1, 1, 1)
    storeBtn.Font = Enum.Font.Gotham
    storeBtn.TextSize = 14
    storeBtn.Parent = frame
    
    local storeBtnCorner = Instance.new("UICorner")
    storeBtnCorner.CornerRadius = UDim.new(0, 6)
    storeBtnCorner.Parent = storeBtn
    
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.9, 0, 0, 30)
    dropBtn.Position = UDim2.new(0.05, 0, 0, 105)
    dropBtn.Text = "Drop Fruits"
    dropBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    dropBtn.TextColor3 = Color3.new(1, 1, 1)
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextSize = 14
    dropBtn.Parent = frame
    
    local dropBtnCorner = Instance.new("UICorner")
    dropBtnCorner.CornerRadius = UDim.new(0, 6)
    dropBtnCorner.Parent = dropBtn
    
    local autoStoreBtn = Instance.new("TextButton")
    autoStoreBtn.Size = UDim2.new(0.9, 0, 0, 30)
    autoStoreBtn.Position = UDim2.new(0.05, 0, 0, 140)
    autoStoreBtn.Text = "Auto Store: OFF"
    autoStoreBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    autoStoreBtn.TextColor3 = Color3.new(1, 1, 1)
    autoStoreBtn.Font = Enum.Font.Gotham
    autoStoreBtn.TextSize = 14
    autoStoreBtn.Parent = frame
    
    local autoStoreBtnCorner = Instance.new("UICorner")
    autoStoreBtnCorner.CornerRadius = UDim.new(0, 6)
    autoStoreBtnCorner.Parent = autoStoreBtn
    
    local function makeDraggable(gui)
        local UserInputService = game:GetService("UserInputService")
        local dragging
        local dragInput
        local dragStart
        local startPos
        
        gui.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = gui.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        gui.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
    
    makeDraggable(frame)
    
    local isMinimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            frame.Size = UDim2.new(0, 200, 0, 30)
            checkBtn.Visible = false
            storeBtn.Visible = false
            dropBtn.Visible = false
            autoStoreBtn.Visible = false
        else
            frame.Size = UDim2.new(0, 200, 0, 180)
            checkBtn.Visible = true
            storeBtn.Visible = true
            dropBtn.Visible = true
            autoStoreBtn.Visible = true
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    checkBtn.MouseButton1Click:Connect(function()
        checkFruits(targetFruits)
    end)
    
    storeBtn.MouseButton1Click:Connect(function()
        storeFruits(targetFruits)
    end)
    
    dropBtn.MouseButton1Click:Connect(function()
        dropFruits(targetFruits)
    end)
    
    local autoStoreEnabled = false
    autoStoreBtn.MouseButton1Click:Connect(function()
        autoStoreEnabled = not autoStoreEnabled
        if autoStoreEnabled then
            autoStoreBtn.Text = "Auto Store: ON"
            autoStoreBtn.TextColor3 = Color3.new(0.3, 1, 0.3) -- Green text
            
            task.spawn(function()
                while autoStoreEnabled do
                    storeFruits(targetFruits)
                    task.wait(3600) -- Wait 3600 seconds (1 hour)
                end
            end)
        else
            autoStoreBtn.Text = "Auto Store: OFF"
            autoStoreBtn.TextColor3 = Color3.new(1, 1, 1) -- White text
        end
    end)
end

createUI()
