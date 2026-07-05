-- ======================================================================
-- ✈️ AUTO ISLAND TRAVEL SCRIPT (FLUENT UI)
-- ======================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Island Travel System",
    SubTitle = "Bypass Method",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 280),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Travel", Icon = "plane" })
}

-- Fetch Islands Dynamically
local islandNames = {}
if workspace:FindFirstChild("Islands") then
    for _, island in ipairs(workspace.Islands:GetChildren()) do
        table.insert(islandNames, island.Name)
    end
    table.sort(islandNames)
else
    Fluent:Notify({ Title = "Error", Content = "Could not find 'Islands' folder in workspace.", Duration = 5 })
end

if #islandNames == 0 then table.insert(islandNames, "None Found") end

local selectedIsland = islandNames[1]

Tabs.Main:AddDropdown("IslandDropdown", {
    Title = "Select Target Island",
    Values = islandNames,
    Multi = false,
    Default = 1,
})

Fluent.Options.IslandDropdown:OnChanged(function(Value)
    selectedIsland = Value
end)

local currentTravelSpeed = 50

Tabs.Main:AddSlider("TravelSpeed", {
    Title = "Flight Speed",
    Description = "Keep this low (e.g. 50-60) to avoid Anti-Cheat kicks on long flights.",
    Default = 50,
    Min = 20,
    Max = 120,
    Rounding = 0,
    Callback = function(Value)
        currentTravelSpeed = Value
    end
})

local travelThread = nil
local stateConn = nil
local currentTween = nil

local function StopTravel()
    if travelThread then
        task.cancel(travelThread)
        travelThread = nil
    end
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    if stateConn then
        stateConn:Disconnect()
        stateConn = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid then humanoid.PlatformStand = false end
        if rootPart then
            local bg = rootPart:FindFirstChild("AutoTravel_Gyro")
            if bg then bg:Destroy() end
            local bv = rootPart:FindFirstChild("AutoTravel_Velocity")
            if bv then bv:Destroy() end
        end
    end
end

Tabs.Main:AddButton({
    Title = "🚀 Start Travel",
    Description = "Initiates bypass flight to the selected island.",
    Callback = function()
        StopTravel() -- Clean up previous travel if running
        
        if selectedIsland == "None Found" then
            Fluent:Notify({ Title = "Error", Content = "No valid island selected.", Duration = 3 })
            return
        end
        
        local targetIsland = workspace.Islands:FindFirstChild(selectedIsland)
        if not targetIsland then
            Fluent:Notify({ Title = "Error", Content = "Island not found in workspace.", Duration = 3 })
            return
        end
        
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not rootPart or not humanoid then return end

        local targetPosition
        if targetIsland:IsA("Model") then
            targetPosition = targetIsland:GetPivot().Position
        else
            targetPosition = targetIsland.Position
        end

        local travelSpeed = currentTravelSpeed
        -- Travel Y first to avoid mountains
        local travelHeight = math.max(rootPart.Position.Y, targetPosition.Y) + 500
        local waypoint1 = Vector3.new(rootPart.Position.X, travelHeight, rootPart.Position.Z)
        local waypoint2 = Vector3.new(targetPosition.X, travelHeight, targetPosition.Z)
        local finalTarget = Vector3.new(targetPosition.X, targetPosition.Y + 20, targetPosition.Z)

        Fluent:Notify({ Title = "Flight Started", Content = "Traveling to " .. selectedIsland, Duration = 3 })

        -- 1. Preparation (Unanchored Bypass Physics)
        humanoid.PlatformStand = false -- Important for falling animation
        rootPart.Anchored = false 

        local bg = rootPart:FindFirstChild("AutoTravel_Gyro") or Instance.new("BodyGyro")
        bg.Name = "AutoTravel_Gyro"
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = rootPart.CFrame
        bg.Parent = rootPart

        local bv = rootPart:FindFirstChild("AutoTravel_Velocity") or Instance.new("BodyVelocity")
        bv.Name = "AutoTravel_Velocity"
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = rootPart

        -- Force falling animation constantly to trick anti-cheat
        stateConn = RunService.Heartbeat:Connect(function()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end)

        local TweenService = game:GetService("TweenService")
        local function PlayTween(targetVec)
            local dist = (rootPart.Position - targetVec).Magnitude
            if dist < 1 then return end
            
            local tInfo = TweenInfo.new(dist / travelSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
            currentTween = TweenService:Create(rootPart, tInfo, { CFrame = CFrame.new(targetVec) })
            
            local bgCFrame = CFrame.new(rootPart.Position, Vector3.new(targetVec.X, rootPart.Position.Y, targetVec.Z))
            if bgCFrame.LookVector.Magnitude > 0 then bg.CFrame = bgCFrame end
            
            currentTween:Play()
            currentTween.Completed:Wait()
        end

        travelThread = task.spawn(function()
            -- Stage 1: Go Up
            PlayTween(waypoint1)
            task.wait(0.1)
            
            -- Stage 2: Go Across
            PlayTween(waypoint2)
            task.wait(0.1)
            
            -- Stage 3: Go Down
            PlayTween(finalTarget)
            
            StopTravel()
            Fluent:Notify({ Title = "Arrived", Content = "Safely landed at " .. selectedIsland, Duration = 4 })
        end)
    end
})

Tabs.Main:AddButton({
    Title = "🛑 Stop Travel",
    Description = "Instantly cancels flight and drops you down.",
    Callback = function()
        StopTravel()
        Fluent:Notify({ Title = "Travel Cancelled", Content = "Flight stopped manually.", Duration = 3 })
    end
})

Window:SelectTab(1)
