if getgenv().FishmanScriptServer == game.JobId then 
    print("[Fishman] Script is already running in this server!")
    return 
end
getgenv().FishmanScriptServer = game.JobId

local function RunFishmanSetup()
    print("--- [Fishman] Script Starting ---")

    -- 1. Safely wait for the game to load
    if not game:IsLoaded() then 
        game.Loaded:Wait() 
    end

    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService = game:GetService("UserInputService")
    
    local CoreGui
    pcall(function() CoreGui = game:GetService("CoreGui") end)

    local LocalPlayer = Players.LocalPlayer
    while not LocalPlayer do 
        task.wait(3)
        LocalPlayer = Players.LocalPlayer 
    end

    local targetPlaceId = 1730877806

    -- 2. Find a safe place to put the UI and folders
    local GuiFolder
    pcall(function() GuiFolder = (gethui and gethui()) end)
    if not GuiFolder and CoreGui then
        pcall(function() GuiFolder = CoreGui end)
    end
    if not GuiFolder then
        print("[Warning] CoreGui blocked. Falling back to PlayerGui.")
        GuiFolder = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- 3. Setup Global Memory
    local GlobalMem = getgenv()
    
    local configFileName = "FishmanConfig_" .. tostring(LocalPlayer.UserId) .. ".json"

    pcall(function()
        if isfile and readfile and isfile(configFileName) then
            local HttpService = game:GetService("HttpService")
            local data = HttpService:JSONDecode(readfile(configFileName))
            if data then
                if GlobalMem.FishmanPSCode == nil then GlobalMem.FishmanPSCode = data.FishmanPSCode end
                if GlobalMem.FishmanDestination == nil then GlobalMem.FishmanDestination = data.FishmanDestination end
                if GlobalMem.FishmanAutoTeleport == nil then GlobalMem.FishmanAutoTeleport = data.FishmanAutoTeleport end
                print("[Fishman] Loaded Config from file.")
            end
        end
    end)

    GlobalMem.FishmanPSCode = GlobalMem.FishmanPSCode or "qj1ttW4JG1"
    GlobalMem.FishmanDestination = GlobalMem.FishmanDestination or "fishHub" 
    GlobalMem.FishmanAutoTeleport = GlobalMem.FishmanAutoTeleport or false 

    local function SaveConfig()
        pcall(function()
            if writefile then
                local HttpService = game:GetService("HttpService")
                local data = {
                    FishmanPSCode = GlobalMem.FishmanPSCode,
                    FishmanDestination = GlobalMem.FishmanDestination,
                    FishmanAutoTeleport = GlobalMem.FishmanAutoTeleport
                }
                writefile(configFileName, HttpService:JSONEncode(data))
            end
        end)
    end

    -- ========================================== --
    -- TELEPORT MEMORY INJECTION (Using your URL)
    -- ========================================== --
    local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/joinersystem.lua"
    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

    local function UpdateTeleportMemory(willAutoTeleport)
        GlobalMem.FishmanAutoTeleport = willAutoTeleport
        SaveConfig()
        print("[Fishman] State Saved -> AutoTeleport:", willAutoTeleport)
        
        if not qot then return end
        
        -- This string gets sent to the NEXT server you join
        local command = [[
            pcall(function()
                getgenv().FishmanPSCode = "]] .. GlobalMem.FishmanPSCode .. [["
                getgenv().FishmanDestination = "]] .. GlobalMem.FishmanDestination .. [["
                getgenv().FishmanAutoTeleport = ]] .. tostring(willAutoTeleport) .. [[
                
                -- Wait 2 seconds for autoexec to run. If it didn't, fallback to downloading from GitHub
                task.spawn(function()
                    task.wait(2)
                    if getgenv().FishmanScriptServer ~= game.JobId then
                        loadstring(game:HttpGet("]] .. myScriptURL .. [["))()
                    end
                end)
            end)
        ]]
        pcall(function() qot(command) end)
    end

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
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
    -- CREATE THE MAIN MENU
    -- ========================================== --
    local function CreateMainUI()
        print("[Fishman] Loading User Interface...")
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
        CodeBox.Text = GlobalMem.FishmanPSCode
        CodeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        CodeBox.TextColor3 = Color3.new(1, 1, 1)
        CodeBox.Parent = MainFrame

        CodeBox.FocusLost:Connect(function()
            GlobalMem.FishmanPSCode = CodeBox.Text
            UpdateTeleportMemory(false)
        end)

        local function CreateDestButton(text, argValue, yPos)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(0.9, 0, 0, 30)
            Btn.Position = UDim2.new(0.05, 0, yPos, 0)
            Btn.Text = text
            Btn.BackgroundColor3 = (GlobalMem.FishmanDestination == argValue) and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(80, 80, 90)
            Btn.TextColor3 = Color3.new(1, 1, 1)
            Btn.Parent = MainFrame

            Btn.MouseButton1Click:Connect(function()
                GlobalMem.FishmanDestination = argValue
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
        TeleportBtn.BackgroundColor3 = Color3.fromRGB(202, 150, 0)
        TeleportBtn.TextColor3 = Color3.new(1, 1, 1)
        TeleportBtn.Parent = MainFrame

        TeleportBtn.MouseButton1Click:Connect(function()
            if game.PlaceId == targetPlaceId and game.PrivateServerId == "" then
                -- Already in Lobby, jump straight to PS
                if GlobalMem.FishmanPSCode ~= "" then
                    task.spawn(function()
                        local events = ReplicatedStorage:WaitForChild("Events", 9e9)
                        local reserved = events:WaitForChild("reserved", 9e9)
                        pcall(function() reserved:InvokeServer(GlobalMem.FishmanPSCode) end)
                    end)
                    task.wait(5) 
                end
                
                local confirmArgs = { [1] = GlobalMem.FishmanDestination }
                pcall(function()
                    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 20)
                    local chooseType = playerGui:WaitForChild("chooseType", 20)
                    local frame = chooseType:WaitForChild("Frame", 20)
                    local remoteEvent = frame:WaitForChild("RemoteEvent", 20)
                    remoteEvent:FireServer(unpack(confirmArgs))
                end)
            else
                -- Not in Lobby, jump to Lobby first
                GlobalMem.FishmanAutoTeleport = true
                UpdateTeleportMemory(true)
                TeleportService:Teleport(targetPlaceId, LocalPlayer)
            end
        end)
    end

    CreateMainUI()
    UpdateTeleportMemory(GlobalMem.FishmanAutoTeleport)

    -- ========================================== --
    -- AUTO-ROUTING LOGIC
    -- ========================================== --
    if game.PlaceId == targetPlaceId and game.PrivateServerId == "" then
        local destCode = GlobalMem.FishmanPSCode
        local destPlace = GlobalMem.FishmanDestination

        if GlobalMem.FishmanAutoTeleport then
            print("[Fishman] Manual Teleport active - Routing to chosen destination in 3 seconds.")
            GlobalMem.FishmanAutoTeleport = false
            SaveConfig()
        else
            print("[Fishman] Default Teleport - Routing to Trade Hub in 3 seconds.")
            destCode = "qj1ttW4JG1"
            destPlace = "tradeHub"
        end

        task.spawn(function()
            task.wait(3) 
            
            if destCode ~= "" then
                print("[Fishman] Teleporting to Private Server:", destCode)
                task.spawn(function()
                    local events = ReplicatedStorage:WaitForChild("Events", 9e9)
                    local reserved = events:WaitForChild("reserved", 9e9)
                    pcall(function() reserved:InvokeServer(destCode) end)
                end)
                task.wait(5) 
            end
            
            local confirmArgs = { [1] = destPlace }
            pcall(function()
                local playerGui = LocalPlayer:WaitForChild("PlayerGui", 20)
                local chooseType = playerGui:WaitForChild("chooseType", 20)
                local frame = chooseType:WaitForChild("Frame", 20)
                local remoteEvent = frame:WaitForChild("RemoteEvent", 20)
                remoteEvent:FireServer(unpack(confirmArgs))
            end)
        end)
    elseif game.PlaceId ~= targetPlaceId and not GlobalMem.FishmanAutoTeleport then
        print("[Fishman] Not in Lobby - Defaulting to Trade Hub.")
        GlobalMem.FishmanAutoTeleport = false
        UpdateTeleportMemory(false)
        TeleportService:Teleport(targetPlaceId, LocalPlayer)
    end
end

-- Run everything safely!
local success, errorMessage = pcall(RunFishmanSetup)
if not success then
    warn("CRITICAL SCRIPT ERROR: " .. tostring(errorMessage))
end