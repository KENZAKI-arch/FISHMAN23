print("--- [Checkpoint 1] Script Starting ---")

-- Wait for the game to load
repeat task.wait() until game:IsLoaded()
print("--- [Checkpoint 2] Game Loaded ---")

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService") -- Added to track mouse movement

-- Safely wait for LocalPlayer
while not Players.LocalPlayer do task.wait(0.5) end
local LocalPlayer = Players.LocalPlayer
print("--- [Checkpoint 3] Player Found: " .. LocalPlayer.Name .. " ---")

local targetPlaceId = 1730877806

-- Safely find a place to put the UI without crashing
local GuiFolder
local success = pcall(function()
    GuiFolder = (gethui and gethui()) or CoreGui
end)
if not success or not GuiFolder then
    print("[Warning] CoreGui blocked by executor. Using PlayerGui instead.")
    GuiFolder = LocalPlayer:WaitForChild("PlayerGui")
end
print("--- [Checkpoint 4] UI Folder Ready: " .. GuiFolder.Name .. " ---")

-- ========================================== --
-- DRAGGING FUNCTION (Makes UI Movable)
-- ========================================== --
local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ========================================== --
-- 1. GLOBAL MEMORY
-- ========================================== --
getgenv().FishmanPSCode = getgenv().FishmanPSCode or ""
getgenv().FishmanDestination = getgenv().FishmanDestination or "fishHub" 
getgenv().FishmanAutoTeleport = getgenv().FishmanAutoTeleport or false 

local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/CombinedAutoLoad.lua"

local function UpdateTeleportMemory(willAutoTeleport)
    local command = [[
        getgenv().FishmanPSCode = "]] .. getgenv().FishmanPSCode .. [["
        getgenv().FishmanDestination = "]] .. getgenv().FishmanDestination .. [["
        getgenv().FishmanAutoTeleport = ]] .. tostring(willAutoTeleport) .. [[
        loadstring(game:HttpGet("]] .. myScriptURL .. [["))()
    ]]
    if queue_on_teleport then
        pcall(function() queue_on_teleport(command) end)
    end
end

-- ========================================== --
-- 2. CREATE THE CONTROL PANEL UI
-- ========================================== --
local function CreateMainUI()
    print("--- [Checkpoint 5] Building UI ---")
    
    if GuiFolder:FindFirstChild("FishmanControlPanel") then
        GuiFolder.FishmanControlPanel:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FishmanControlPanel"
    ScreenGui.Parent = GuiFolder

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 300, 0, 240) 
    MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    MainFrame.Active = true -- Required for clicking to work perfectly
    MainFrame.Parent = ScreenGui
    
    -- Apply the dragging tool to the Main Panel
    MakeDraggable(MainFrame)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Text = "🐟 Fishman Setup"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Parent = MainFrame

    local CodeBox = Instance.new("TextBox")
    CodeBox.Size = UDim2.new(0.9, 0, 0, 40)
    CodeBox.Position = UDim2.new(0.05, 0, 0.15, 0)
    CodeBox.PlaceholderText = "Enter Private Server Code Here"
    CodeBox.Text = getgenv().FishmanPSCode
    CodeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    CodeBox.TextColor3 = Color3.new(1, 1, 1)
    CodeBox.Parent = MainFrame

    CodeBox.FocusLost:Connect(function()
        getgenv().FishmanPSCode = CodeBox.Text
        print("[UI] PS Code updated to: " .. getgenv().FishmanPSCode)
        UpdateTeleportMemory(false)
    end)

    local function CreateDestButton(text, argValue, yPos)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0.9, 0, 0, 30)
        Btn.Position = UDim2.new(0.05, 0, yPos, 0)
        Btn.Text = text
        Btn.BackgroundColor3 = (getgenv().FishmanDestination == argValue) and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(80, 80, 90)
        Btn.TextColor3 = Color3.new(1, 1, 1)
        Btn.Parent = MainFrame

        Btn.MouseButton1Click:Connect(function()
            getgenv().FishmanDestination = argValue
            print("[UI] Destination set to: " .. argValue)
            for _, child in pairs(MainFrame:GetChildren()) do
                if child:IsA("TextButton") and child.Name ~= "TeleportButton" then 
                    child.BackgroundColor3 = Color3.fromRGB(80, 80, 90) 
                end
            end
            Btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            UpdateTeleportMemory(false)
        end)
    end

    CreateDestButton("Fish Hub", "fishHub", 0.35)
    CreateDestButton("Trade Hub", "tradeHub", 0.50)
    CreateDestButton("Second Sea", "Second Sea", 0.65)

    local TeleportBtn = Instance.new("TextButton")
    TeleportBtn.Name = "TeleportButton"
    TeleportBtn.Size = UDim2.new(0.9, 0, 0, 40)
    TeleportBtn.Position = UDim2.new(0.05, 0, 0.80, 0)
    TeleportBtn.Text = "🚀 TELEPORT NOW"
    TeleportBtn.Font = Enum.Font.GothamBold
    TeleportBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    TeleportBtn.TextColor3 = Color3.new(1, 1, 1)
    TeleportBtn.Parent = MainFrame

    TeleportBtn.MouseButton1Click:Connect(function()
        if game.PlaceId == targetPlaceId and game.PrivateServerId == "" then
            print("[Manual] Teleporting directly to destination...")
            
            if getgenv().FishmanPSCode ~= "" then
                task.spawn(function()
                    local events = ReplicatedStorage:WaitForChild("Events", 9e9)
                    local reserved = events:WaitForChild("reserved", 9e9)
                    reserved:InvokeServer(getgenv().FishmanPSCode)
                end)
                task.wait(1.5) 
            end
            
            local confirmArgs = { [1] = getgenv().FishmanDestination }
            local playerGui = LocalPlayer:WaitForChild("PlayerGui", 9e9)
            local chooseType = playerGui:WaitForChild("chooseType", 9e9)
            local frame = chooseType:WaitForChild("Frame", 9e9)
            local remoteEvent = frame:WaitForChild("RemoteEvent", 9e9)
            
            remoteEvent:FireServer(unpack(confirmArgs))
            
        else
            print("[Manual] Jumping to Lobby first...")
            getgenv().FishmanAutoTeleport = true
            UpdateTeleportMemory(true)
            TeleportService:Teleport(targetPlaceId, LocalPlayer)
        end
    end)

    print("--- [Checkpoint 6] UI Successfully Built ---")
end

CreateMainUI()
UpdateTeleportMemory(getgenv().FishmanAutoTeleport)

-- ========================================== --
-- 3. CUSTOM KICK / DISCONNECT WATCHER
-- ========================================== --
task.spawn(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
    
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            child.Visible = false 
            
            local RejoinUI = Instance.new("ScreenGui")
            RejoinUI.Name = "CustomRejoinPrompt"
            RejoinUI.Parent = GuiFolder

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(0, 300, 0, 150)
            Frame.Position = UDim2.new(0.5, -150, 0.5, -75)
            Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Frame.Active = true 
            Frame.Parent = RejoinUI
            
            -- Apply the dragging tool to the Disconnect box too
            MakeDraggable(Frame)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 50)
            Label.Text = "You were disconnected.\nDo you want to rejoin?"
            Label.TextColor3 = Color3.new(1, 1, 1)
            Label.BackgroundTransparency = 1
            Label.Parent = Frame

            local YesBtn = Instance.new("TextButton")
            YesBtn.Size = UDim2.new(0.4, 0, 0, 40)
            YesBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
            YesBtn.Text = "Yes, Rejoin"
            YesBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            YesBtn.Parent = Frame

            local NoBtn = Instance.new("TextButton")
            NoBtn.Size = UDim2.new(0.4, 0, 0, 40)
            NoBtn.Position = UDim2.new(0.55, 0, 0.6, 0)
            NoBtn.Text = "No, Stay Here"
            NoBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            NoBtn.Parent = Frame

            YesBtn.MouseButton1Click:Connect(function()
                RejoinUI:Destroy()
                print("[Watcher] Rejoining through Lobby...")
                getgenv().FishmanAutoTeleport = true
                UpdateTeleportMemory(true) 
                TeleportService:Teleport(targetPlaceId, LocalPlayer)
            end)

            NoBtn.MouseButton1Click:Connect(function()
                RejoinUI:Destroy()
                child.Visible = true 
            end)
        end
    end)
end)

-- ========================================== --
-- 4. AUTO-ROUTING LOGIC
-- ========================================== --
if game.PlaceId == targetPlaceId and game.PrivateServerId == "" then
    if getgenv().FishmanAutoTeleport == true then
        print("[Logic] Arrived in Lobby! Automatically finishing teleport...")
        
        getgenv().FishmanAutoTeleport = false 
        UpdateTeleportMemory(false)
        
        if getgenv().FishmanPSCode ~= "" then
            task.spawn(function()
                local events = ReplicatedStorage:WaitForChild("Events", 9e9)
                local reserved = events:WaitForChild("reserved", 9e9)
                reserved:InvokeServer(getgenv().FishmanPSCode)
            end)
            task.wait(1.5) 
        end
        
        local confirmArgs = { [1] = getgenv().FishmanDestination }
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 9e9)
        local chooseType = playerGui:WaitForChild("chooseType", 9e9)
        local frame = chooseType:WaitForChild("Frame", 9e9)
        local remoteEvent = frame:WaitForChild("RemoteEvent", 9e9)
        
        remoteEvent:FireServer(unpack(confirmArgs))
    else
        print("[Logic] In lobby. Ready when you click 'TELEPORT NOW'.")
    end
else
    print("[Logic] Arrived in Private Server. Use the UI to jump elsewhere when ready.")
end

print("--- [Checkpoint 8] Script Finished Loading ---")