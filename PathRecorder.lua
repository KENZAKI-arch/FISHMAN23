local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local RECORD_INTERVAL_STUDS = 15

local isRecording = false
local recordedPath = {}
local lastRecordedPos = nil
local heartbeatConn = nil

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PathRecorderGui"
ScreenGui.ResetOnSpawn = false

-- Use CoreGui if exploiting, otherwise PlayerGui
local success, err = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 100)
MainFrame.Position = UDim2.new(0.5, -100, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Text = "Path Recorder"
Title.Font = Enum.Font.Code
Title.TextSize = 14
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
StatusLabel.Text = "Waypoints: 0"
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 14
StatusLabel.Parent = MainFrame

local RecordButton = Instance.new("TextButton")
RecordButton.Size = UDim2.new(0.9, 0, 0, 30)
RecordButton.Position = UDim2.new(0.05, 0, 0, 60)
RecordButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
RecordButton.TextColor3 = Color3.new(1, 1, 1)
RecordButton.Text = "Start Recording"
RecordButton.Font = Enum.Font.Code
RecordButton.TextSize = 14
RecordButton.Parent = MainFrame

-- Logic
local function stopRecordingAndPrint()
    isRecording = false
    RecordButton.Text = "Start Recording"
    RecordButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
    
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    
    if #recordedPath == 0 then
        print("[PathRecorder] No waypoints were recorded.")
        return
    end
    
    local outString = "local WAYPOINTS = {\n"
    for i, pos in ipairs(recordedPath) do
        local comma = (i == #recordedPath) and "" or ","
        outString = outString .. string.format("    Vector3.new(%.1f, %.1f, %.1f)%s\n", pos.X, pos.Y, pos.Z, comma)
    end
    outString = outString .. "}"
    
    print("\n===============================")
    print("-- RECORDED WAYPOINTS MACRO --")
    print(outString)
    print("===============================\n")
    
    if setclipboard then
        setclipboard(outString)
        StatusLabel.Text = "Copied to Clipboard!"
    else
        StatusLabel.Text = "Printed to F9 Console!"
    end
    
    -- Reset for next use
    recordedPath = {}
    lastRecordedPos = nil
end

local function startRecording()
    isRecording = true
    recordedPath = {}
    lastRecordedPos = nil
    RecordButton.Text = "Stop & Print"
    RecordButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    StatusLabel.Text = "Waypoints: 0"
    
    heartbeatConn = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local currentPos = character.HumanoidRootPart.Position
        
        if not lastRecordedPos or (currentPos - lastRecordedPos).Magnitude >= RECORD_INTERVAL_STUDS then
            table.insert(recordedPath, currentPos)
            lastRecordedPos = currentPos
            StatusLabel.Text = "Waypoints: " .. tostring(#recordedPath)
        end
    end)
end

RecordButton.MouseButton1Click:Connect(function()
    if isRecording then
        stopRecordingAndPrint()
    else
        startRecording()
    end
end)

-- Make draggable
local dragging
local dragInput
local dragStart
local startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

local UserInputService = game:GetService("UserInputService")
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print("[PathRecorder] Loaded! Click Start Recording on the UI.")
