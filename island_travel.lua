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

local travelConn = nil

local function StopTravel()
    if travelConn then
        travelConn:Disconnect()
        travelConn = nil
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

        local travelSpeed = 90
        -- Travel Y first to avoid mountains
        local travelHeight = math.max(rootPart.Position.Y, targetPosition.Y) + 500
        local waypoint1 = Vector3.new(rootPart.Position.X, travelHeight, rootPart.Position.Z)
        local waypoint2 = Vector3.new(targetPosition.X, travelHeight, targetPosition.Z)
        local finalTarget = Vector3.new(targetPosition.X, targetPosition.Y + 20, targetPosition.Z)

        Fluent:Notify({ Title = "Flight Started", Content = "Traveling to " .. selectedIsland, Duration = 3 })

        -- 1. Preparation (Enable Flight Physics)
        humanoid.PlatformStand = true
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

        -- 2. Movement Logic (Heartbeat + Lerp)
        local travelStage = 1
        travelConn = RunService.Heartbeat:Connect(function(deltaTime)
            if not character or not character.Parent or humanoid.Health <= 0 then
                StopTravel()
                return
            end

            local cur = rootPart.Position
            local tgt
            if travelStage == 1 then tgt = waypoint1
            elseif travelStage == 2 then tgt = waypoint2
            else tgt = finalTarget end

            local goingUp = (tgt.Y > cur.Y)
            local nextPoint

            if goingUp and math.abs(cur.Y - tgt.Y) > 1 then nextPoint = Vector3.new(cur.X, tgt.Y, cur.Z)
            elseif math.abs(cur.X - tgt.X) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, cur.Z)
            elseif math.abs(cur.Z - tgt.Z) > 1 then nextPoint = Vector3.new(tgt.X, cur.Y, tgt.Z)
            elseif not goingUp and math.abs(cur.Y - tgt.Y) > 1 then nextPoint = Vector3.new(tgt.X, tgt.Y, tgt.Z)
            else
                -- Stage Transition
                if travelStage == 1 then travelStage = 2 return
                elseif travelStage == 2 then travelStage = 3 return end
                
                -- Arrived
                StopTravel()
                Fluent:Notify({ Title = "Arrived", Content = "Safely landed at " .. selectedIsland, Duration = 4 })
                return
            end

            local newX, newZ = cur.X, cur.Z
            local horizNext = Vector3.new(nextPoint.X, cur.Y, nextPoint.Z)
            local horizDist = (Vector3.new(cur.X, 0, cur.Z) - Vector3.new(nextPoint.X, 0, nextPoint.Z)).Magnitude
            
            if horizDist > 0 then
                local alpha = math.clamp((travelSpeed * deltaTime) / horizDist, 0, 1)
                local hLerp = cur:Lerp(horizNext, alpha)
                newX, newZ = hLerp.X, hLerp.Z
            end

            local newY = cur.Y
            local vertDist = math.abs(nextPoint.Y - cur.Y)
            if vertDist > 0 then
                local dir = (nextPoint.Y > cur.Y) and 1 or -1
                local moveY = travelSpeed * deltaTime
                if moveY > vertDist then moveY = vertDist end
                newY = cur.Y + (moveY * dir)
            end

            -- Apply Physics Bypass
            rootPart.CFrame = CFrame.new(newX, newY, newZ)
            bv.Velocity = Vector3.new(0, 0, 0)
            bg.CFrame = CFrame.new(rootPart.Position, Vector3.new(tgt.X, rootPart.Position.Y, tgt.Z))
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
