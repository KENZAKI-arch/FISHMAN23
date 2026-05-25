print("--- [Checkpoint 1] Script Starting ---")

-- Wait for the game to load
repeat task.wait() until game:IsLoaded()
print("--- [Checkpoint 2] Game Loaded ---")

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService") 
local HttpService = game:GetService("HttpService") -- Added for file saving

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
-- 1. HARD DRIVE MEMORY (Bulletproof Save)
-- ========================================== --
local SaveFileName = "FishmanSaveData.json"

-- Attempt to read the save file from your computer first
pcall(function()
    if isfile(SaveFileName) then
        local savedData = HttpService:JSONDecode(readfile(SaveFileName))
        getgenv().FishmanPSCode = savedData.PSCode
        getgenv().FishmanDestination = savedData.Dest
        getgenv().FishmanAutoTeleport = savedData.AutoTP
    end
end)

-- If no file exists yet, give it default settings
getgenv().FishmanPSCode = getgenv().FishmanPSCode or ""
getgenv().FishmanDestination = getgenv().FishmanDestination or "fishHub" 
getgenv().FishmanAutoTeleport = getgenv().FishmanAutoTeleport or false 

local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/joinersystem.lua"

local function SaveTeleportMemory(willAutoTeleport)
    getgenv().FishmanAutoTeleport = willAutoTeleport
    
    -- Write everything to a file on your PC so it survives disconnects
    pcall(function()
        local dataToSave = {
            PSCode = getgenv().FishmanPSCode,
            Dest = getgenv().FishmanDestination,
            AutoTP = getgenv().FishmanAutoTeleport
        }
        writefile(SaveFileName, HttpService:JSONEncode(dataToSave))
    end)
    
    -- Backup teleport queue
    local command = [[
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
    MainFrame.Active = true 
    MainFrame.Parent = ScreenGui
    
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
        SaveTeleportMemory(false)
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
            SaveTeleportMemory(false)
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
            SaveTeleportMemory(true)
            TeleportService:Teleport(targetPlaceId, LocalPlayer)
        end
    end)

    print("--- [Checkpoint 6] UI Successfully Built ---")
end

CreateMainUI()
SaveTeleportMemory(getgenv().FishmanAutoTeleport)

-- ========================================== --
-- 3. CUSTOM KICK / DISCONNECT WATCHER (AFK Auto-Rejoin)
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
            
            MakeDraggable(Frame)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 50)
            Label.Text = "Disconnected.\nRouting to Lobby in 10 seconds..."
            Label.TextColor3 = Color3.new(1, 1, 1)
            Label.BackgroundTransparency = 1
            Label.Parent = Frame

            local YesBtn = Instance.new("TextButton")
            YesBtn.Size = UDim2.new(0.4, 0, 0, 40)
            YesBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
            YesBtn.Text = "Rejoin Now"
            YesBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            YesBtn.Parent = Frame

            local NoBtn = Instance.new("TextButton")
            NoBtn.Size = UDim2.new(0.4, 0, 0, 40)
            NoBtn.Position = UDim2.new(0.55, 0, 0.6, 0)
            NoBtn.Text = "Cancel"
            NoBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            NoBtn.Parent = Frame

            local function triggerRejoin()
                if RejoinUI.Parent then
                    RejoinUI:Destroy()
                    print("[Watcher] Kicked! Forcing teleport back to Lobby first...")
                    
                    -- This saves 'AutoTeleport = true' to your hard drive file
                    SaveTeleportMemory(true) 
                    
                    -- Spam the teleport command to the Lobby (1730877806) until it works
                    task.spawn(function()
                        while task.wait(1) do
                            pcall(function()
                                TeleportService:Teleport(1730877806, LocalPlayer)
                            end)
                        end
                    end)
                end
            end

            local autoRejoinCountdown = task.delay(10, triggerRejoin)

            YesBtn.MouseButton1Click:Connect(function()
                task.cancel(autoRejoinCountdown) 
                triggerRejoin() 
            end)

            NoBtn.MouseButton1Click:Connect(function()
                task.cancel(autoRejoinCountdown) 
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
        
        -- Turn off AutoTeleport in the save file so you don't get stuck in a loop forever
        SaveTeleportMemory(false)
        
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
    print("[Logic] Arrived in Private Server.")
    
    local currentDest = getgenv().FishmanDestination
    if currentDest == "fishHub" or currentDest == "tradeHub" then
        print("[Logic] Successfully arrived at " .. currentDest .. "! Loading AutoFisher...")
        
        task.spawn(function()
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/AF2/refs/heads/main/Controller.lua"))()
            end)
        end)
    else
        print("[Logic] Use the UI to jump elsewhere when ready.")
    end
end

print("--- [Checkpoint 8] Script Finished Loading ---")