-- Dynamic Maze AutoFarm (Pathfinding + Tween/Lerp Flight)
-- Calculates the shortest path and smoothly flies you through it using BodyVelocity and Lerping.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local FLY_SPEED = 50
local isRunning = false
local currentRoutine = nil
local lastStaminaTick = 0
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- UI Setup
if CoreGui:FindFirstChild("MazeFlyGui") then
    CoreGui.MazeFlyGui:Destroy()
end
local pGui = LocalPlayer:FindFirstChild("PlayerGui")
if pGui and pGui:FindFirstChild("MazeFlyGui") then
    pGui.MazeFlyGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MazeFlyGui"
ScreenGui.ResetOnSpawn = false
local success = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = pGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 40)
MainFrame.Position = UDim2.new(0.5, -100, 0, 120)
MainFrame.BackgroundColor3 = Color3.fromRGB(60, 180, 60) -- Green when OFF
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -35, 1, 0)
ToggleBtn.Position = UDim2.new(0, 5, 0, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Text = "MAZE FLYER: OFF [N]"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = MainFrame

-- Stamina drain
local function drainStamina(character)
    local currentTick = tick()
    if currentTick - lastStaminaTick < 0.3 then return end
    lastStaminaTick = currentTick

    local staminaVal = nil
    local staminaObj = character:FindFirstChild("Stamina") or character:FindFirstChild("Energy")
    if staminaObj and staminaObj:IsA("NumberValue") then
        staminaVal = staminaObj
    else
        local attr = character:GetAttribute("Stamina") or character:GetAttribute("Energy")
        if attr ~= nil then
            if not character:FindFirstChild("_StaminaHolder") then
                local holder = Instance.new("NumberValue")
                holder.Name = "_StaminaHolder"
                holder.Value = attr
                holder.Parent = character
            end
            staminaVal = character:FindFirstChild("_StaminaHolder")
        end
    end
    if staminaVal then
        staminaVal.Value = math.max(0, staminaVal.Value - 1)
    end
end

-- Hardcoded Maze Target
local function getMazeTarget()
    return Vector3.new(2605, 2075, -15410)
end

local function stopMaze()
    isRunning = false
    ToggleBtn.Text = "MAZE FLYER: OFF [N]"
    MainFrame.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
    
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local existingBv = character.HumanoidRootPart:FindFirstChild("MazeAntiGravity")
        if existingBv then existingBv:Destroy() end
    end
    
    if currentRoutine then
        task.cancel(currentRoutine)
        currentRoutine = nil
    end
end

local function flyToTarget(hrp, targetPos)
    local bv = hrp:FindFirstChild("MazeAntiGravity") or Instance.new("BodyVelocity")
    bv.Name = "MazeAntiGravity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    
    local character = hrp.Parent
    local stuckTimer = 0
    local lastDist = (hrp.Position - targetPos).Magnitude
    
    while isRunning and hrp.Parent do
        local dist = (hrp.Position - targetPos).Magnitude
        if dist <= 0.5 then
            break -- Reached the exact waypoint (prevents corner cutting)
        end
        
        local deltaTime = task.wait()
        
        -- Stuck Detection: If we haven't moved closer by at least 0.1 studs
        if lastDist - dist < 0.1 then
            stuckTimer = stuckTimer + deltaTime
        else
            stuckTimer = 0
            lastDist = dist
        end
        
        -- If stuck for more than 0.5 seconds, Noclip & Dash!
        if stuckTimer > 0.5 then
            print("[MazeSolver] Stuck on wall! Noclipping & Dashing...")
            
            -- 1. Noclip all parts
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            -- 2. Dash removed to prevent kick
            
            -- Reset stuck timer so we don't spam it every frame
            stuckTimer = 0
            task.wait(0.2) -- Let the dash play out briefly
        end
        
        local lerpAlpha = math.clamp((FLY_SPEED * deltaTime) / dist, 0, 1)
        
        -- Lock Y rotation to look forward, but keep CFrame clean
        local lookAtCFrame
        if dist > 0.1 then
            lookAtCFrame = CFrame.lookAt(hrp.Position, targetPos)
        else
            lookAtCFrame = hrp.CFrame
        end
        
        hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos) * lookAtCFrame.Rotation, lerpAlpha)
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.RotVelocity = Vector3.new(0, 0, 0)
        
        drainStamina(character)
    end
end

local function mazeFlyLogic()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    
    local targetDest = getMazeTarget()
    
    print("[MazeSolver] Calculating shortest path...")
    local path = PathfindingService:CreatePath({
        AgentRadius = 3,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4,
        Costs = { Water = 20 }
    })
    
    local success, err = pcall(function()
        path:ComputeAsync(hrp.Position, targetDest)
    end)
    
    if not success or path.Status ~= Enum.PathStatus.Success then
        print("[MazeSolver] Path calculation failed! Attempting straight line flight.")
        flyToTarget(hrp, targetDest)
        stopMaze()
        return
    end
    
    local waypoints = path:GetWaypoints()
    print("[MazeSolver] Path generated! Smoothly flying through " .. #waypoints .. " waypoints...")
    
    for i, waypoint in ipairs(waypoints) do
        if not isRunning then break end
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then break end
        local hrp = character.HumanoidRootPart
        
        local pos = waypoint.Position
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            pos = pos + Vector3.new(0, 5, 0)
        end
        
        -- Fly smoothly to the specific waypoint
        flyToTarget(hrp, pos)
    end
    
    print("[MazeSolver] Reached the end!")
    stopMaze()
end

local function startMaze()
    if isRunning then return end
    isRunning = true
    ToggleBtn.Text = "MAZE FLYER: ON [N]"
    MainFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    
    -- Start flying logic in background thread
    currentRoutine = task.spawn(mazeFlyLogic)
end

ToggleBtn.MouseButton1Click:Connect(function()
    if isRunning then stopMaze() else startMaze() end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if isRunning then stopMaze() end
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.N then
        if isRunning then stopMaze() else startMaze() end
    end
end)

getgenv().StartDynamicMaze = function()
    if isRunning then stopMaze() else startMaze() end
end
