local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local activeNavigation = nil

local EVASION_DIRECTIONS = {
    Vector3.new(1, 0, 0),   -- 1. Slide Right
    Vector3.new(0, 1, 0)    -- 2. Climb Up (Only if cornered/trapped)
}

---------------------------------------------------------
-- 1. Physics Navigation Logic
---------------------------------------------------------
local function navigateTo(object, targetPosition, speed, arrivalDistance)
    speed = speed or 100
    arrivalDistance = arrivalDistance or 200
    
    local primaryPart = object:IsA("Model") and object.PrimaryPart or (object:IsA("BasePart") and object or nil)
    if not primaryPart then return nil end

    local startPosition = primaryPart.Position

    local size = primaryPart.Size
    if object:IsA("Model") then
        local _, modelSize = object:GetBoundingBox()
        size = modelSize
    end

    local downwardParams = RaycastParams.new()
    downwardParams.FilterType = Enum.RaycastFilterType.Exclude
    downwardParams.FilterDescendantsInstances = {object, LocalPlayer.Character}
    downwardParams.IgnoreWater = false 

    local forwardParams = RaycastParams.new()
    forwardParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local ignoreList = {object, LocalPlayer.Character}
    local OCEAN_LEVEL = 0 
    
    local oceanModel = workspace:FindFirstChild("Ocean")
    if oceanModel then 
        table.insert(ignoreList, oceanModel) 
        local highestWater = -math.huge
        for _, part in ipairs(oceanModel:GetDescendants()) do
            if part:IsA("BasePart") then
                local topSurface = part.Position.Y + (part.Size.Y / 2)
                if topSurface > highestWater then
                    highestWater = topSurface
                end
            end
        end
        if highestWater ~= -math.huge then
            OCEAN_LEVEL = highestWater
        end
    end
    
    local envFolder = workspace:FindFirstChild("Env")
    if envFolder then
        local waterStuff = envFolder:FindFirstChild("WaterStuff")
        if waterStuff then
            table.insert(ignoreList, waterStuff)
            local highestWater = -math.huge
            for _, part in ipairs(waterStuff:GetDescendants()) do
                if part:IsA("BasePart") then
                    local topSurface = part.Position.Y + (part.Size.Y / 2)
                    if topSurface > highestWater then
                        highestWater = topSurface
                    end
                end
            end
            if highestWater ~= -math.huge and highestWater > OCEAN_LEVEL then
                OCEAN_LEVEL = highestWater
            end
        end
    end
    
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder then
        table.insert(ignoreList, npcsFolder)
        
        local downIgnore = downwardParams.FilterDescendantsInstances
        table.insert(downIgnore, npcsFolder)
        downwardParams.FilterDescendantsInstances = downIgnore
    end
    
    forwardParams.FilterDescendantsInstances = ignoreList
    forwardParams.IgnoreWater = true 

    local humanoid = object:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = true end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = primaryPart

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.CFrame = primaryPart.CFrame
    bg.Parent = primaryPart

    local navigator = { 
        _isNavigating = true,
        _isPaused = false,
        _evadingTimer = 0,
        _evasionDir = nil,
        _roboTarget = nil,
        _lastScan = 0,
        Distance = 0 -- Added live distance tracker
    }
    local connection = nil
    local noclipConnection = nil
    
    function navigator:Cancel()
        self._isNavigating = false
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        if humanoid then humanoid.PlatformStand = false end
        if connection then connection:Disconnect() end
        if noclipConnection then noclipConnection:Disconnect() end
    end
    
    function navigator:TogglePause()
        self._isPaused = not self._isPaused
        if self._isPaused then
            if bv then bv.Velocity = Vector3.zero end
        end
        return self._isPaused
    end

    local function raycastSolid(origin, direction, params)
        local result = workspace:Raycast(origin, direction, params)
        local loops = 0
        while result and not result.Instance.CanCollide and loops < 10 do
            local currentList = params.FilterDescendantsInstances
            table.insert(currentList, result.Instance)
            params.FilterDescendantsInstances = currentList
            loops = loops + 1
            result = workspace:Raycast(origin, direction, params)
        end
        return result
    end

    local function blockcastSolid(cframe, extents, dir, params)
        local result = workspace:Blockcast(cframe, extents, dir, params)
        local loops = 0
        while result and not result.Instance.CanCollide and loops < 10 do
            local currentList = params.FilterDescendantsInstances
            table.insert(currentList, result.Instance)
            params.FilterDescendantsInstances = currentList
            loops = loops + 1
            result = workspace:Blockcast(cframe, extents, dir, params)
        end
        return result
    end

    noclipConnection = RunService.Stepped:Connect(function()
        if not navigator._isNavigating or navigator._isPaused then return end
        if object then
            for _, part in ipairs(object:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)

    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not navigator._isNavigating then
            navigator:Cancel()
            return
        end
        
        if navigator._isPaused then return end
        
        local currentPos = primaryPart.Position
        local flatCurrent = Vector3.new(currentPos.X, 0, currentPos.Z)
        local flatTarget = Vector3.new(targetPosition.X, 0, targetPosition.Z)
        
        local directionToTarget = (flatTarget - flatCurrent)
        local distToTarget = directionToTarget.Magnitude
        
        -- Update the live tracker distance!
        navigator.Distance = math.floor(distToTarget)
        
        if not navigator._roboTarget and distToTarget <= 1500 then
            local now = tick()
            if now - navigator._lastScan > 1 then
                navigator._lastScan = now
                if npcsFolder then
                    local closestRobo = nil
                    local shortestDist = 1500
                    
                    for _, npc in ipairs(npcsFolder:GetChildren()) do
                        if string.find(string.lower(npc.Name), "robo") then
                            local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
                            if root then
                                local distToDestination = (root.Position - targetPosition).Magnitude
                                local distToStart = (root.Position - startPosition).Magnitude
                                
                                if distToDestination < shortestDist and distToDestination < distToStart then
                                    shortestDist = distToDestination
                                    closestRobo = root
                                end
                            end
                        end
                    end
                    
                    if closestRobo then
                        navigator._roboTarget = closestRobo
                        print("AutoNavigator: Robo Detected near destination! Locking on to his front...")
                    end
                end
            end
        end
        
        if navigator._roboTarget then
            local roboPos = navigator._roboTarget.Position
            local roboLook = navigator._roboTarget.CFrame.LookVector
            
            targetPosition = roboPos + (roboLook * 15)
            
            flatTarget = Vector3.new(targetPosition.X, 0, targetPosition.Z)
            directionToTarget = (flatTarget - flatCurrent)
            distToTarget = directionToTarget.Magnitude
            
            arrivalDistance = 8 
        end
        
        local moveDir = directionToTarget.Unit
        if distToTarget == 0 then moveDir = primaryPart.CFrame.LookVector end
        
        local targetVelocity = (moveDir * speed)
        local targetRotation = CFrame.lookAt(currentPos, currentPos + moveDir)
        
        local lookAheadPos = flatCurrent + (targetVelocity.Unit * 5)
        local rayOrigin = Vector3.new(lookAheadPos.X, currentPos.Y + 500, lookAheadPos.Z)
        
        local groundHit = raycastSolid(rayOrigin, Vector3.new(0, -1000, 0), downwardParams)
        
        if distToTarget <= arrivalDistance then
            if navigator._roboTarget then
                navigator:Cancel()
                print("Flight Reached Robo!")
                return
            else
                if groundHit and groundHit.Position.Y > (OCEAN_LEVEL + 3) then
                    navigator:Cancel()
                    print("Safe solid ground detected! Landing early.")
                    return
                end
                
                if distToTarget <= 20 then
                    navigator:Cancel()
                    print("Forced drop at center.")
                    return
                end
            end
        end
        
        local targetY = currentPos.Y
        if groundHit then
            targetY = groundHit.Position.Y + 5 + (size.Y / 2)
        end
        
        local minAllowedHeight = OCEAN_LEVEL + 5 + (size.Y / 2)
        if targetY < minAllowedHeight then
            targetY = minAllowedHeight
        end
        
        local wallCheckCFrame = primaryPart.CFrame + Vector3.new(0, 3, 0)
        local isCloseToArrival = (distToTarget <= arrivalDistance + 15)
        
        if navigator._evadingTimer > 0 and not isCloseToArrival then
            navigator._evadingTimer = navigator._evadingTimer - deltaTime
            local evadeWallCast = blockcastSolid(wallCheckCFrame, size, navigator._evasionDir * 15, forwardParams)
            if evadeWallCast and evadeWallCast.Distance <= 5 then
                navigator._evadingTimer = 0
            else
                targetVelocity = (navigator._evasionDir * speed)
                
                if navigator._evasionDir.Y >= 0.99 or navigator._evasionDir.Y <= -0.99 then
                    targetRotation = CFrame.lookAt(currentPos, currentPos + navigator._evasionDir + (moveDir * 0.01))
                else
                    targetRotation = CFrame.lookAt(currentPos, currentPos + navigator._evasionDir)
                end
            end
        elseif not isCloseToArrival then
            local wallCast = blockcastSolid(wallCheckCFrame, size, moveDir * 10, forwardParams)
            if wallCast and wallCast.Distance <= 5 then
                if wallCast.Distance > 0.5 then
                    local evaded = false
                    local baseLook = CFrame.lookAt(currentPos, currentPos + moveDir)
                    
                    for _, evasionDir in ipairs(EVASION_DIRECTIONS) do
                        local relativeVector = evasionDir
                        
                        if evasionDir.X ~= 0 then
                            relativeVector = baseLook:VectorToWorldSpace(evasionDir)
                        end
                        
                        local evadeCast = blockcastSolid(wallCheckCFrame, size, relativeVector * 15, forwardParams)
                        
                        if not evadeCast then
                            navigator._evadingTimer = 0.3 
                            navigator._evasionDir = relativeVector
                            targetVelocity = (relativeVector * speed)
                            
                            if relativeVector.Y >= 0.99 or relativeVector.Y <= -0.99 then
                                targetRotation = CFrame.lookAt(currentPos, currentPos + relativeVector + (moveDir * 0.01))
                            else
                                targetRotation = CFrame.lookAt(currentPos, currentPos + relativeVector)
                            end
                            evaded = true
                            break
                        end
                    end
                    
                    if not evaded then
                        warn("AutoNavigator: Path tight! Forcing UP!")
                        navigator._evadingTimer = 0.3
                        navigator._evasionDir = Vector3.new(0, 1, 0)
                    end
                end
            end
        end
        
        if navigator._evadingTimer <= 0 or isCloseToArrival then
            local heightDiff = targetY - currentPos.Y
            local yVelocity = math.clamp(heightDiff * 5, -speed, speed)
            targetVelocity = Vector3.new(targetVelocity.X, yVelocity, targetVelocity.Z)
        end
        
        bv.Velocity = targetVelocity
        bg.CFrame = targetRotation
    end)
    
    return navigator
end

---------------------------------------------------------
-- 2. GUI & Island Picking Logic
---------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IslandNavigatorGUI"
screenGui.ResetOnSpawn = false

local targetGui = LocalPlayer:FindFirstChild("PlayerGui")
if not targetGui then targetGui = game:GetService("CoreGui") end

if targetGui:FindFirstChild(screenGui.Name) then
    targetGui[screenGui.Name]:Destroy()
end
screenGui.Parent = targetGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 205)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Auto Navigator"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 1, 0)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = topBar

local selectedIslandPosition = nil
local dropdownHeader = Instance.new("TextButton")
dropdownHeader.Size = UDim2.new(1, -20, 0, 35)
dropdownHeader.Position = UDim2.new(0, 10, 0, 40)
dropdownHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropdownHeader.Text = "Select Island 🔽"
dropdownHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownHeader.Font = Enum.Font.GothamBold
dropdownHeader.TextSize = 14
dropdownHeader.ZIndex = 2
dropdownHeader.Parent = mainFrame
Instance.new("UICorner", dropdownHeader).CornerRadius = UDim.new(0, 6)

local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Size = UDim2.new(1, -20, 0, 120)
dropdownList.Position = UDim2.new(0, 10, 0, 80)
dropdownList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropdownList.BorderSizePixel = 0
dropdownList.ScrollBarThickness = 4
dropdownList.Visible = false
dropdownList.ZIndex = 5
dropdownList.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = dropdownList
listLayout.Padding = UDim.new(0, 2)

local guider = game.ReplicatedStorage:FindFirstChild("CompassGuider")
if guider then
    local islands = guider:GetChildren()
    for _, island in ipairs(islands) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.Text = island.Name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.ZIndex = 6
        btn.Parent = dropdownList
        
        btn.MouseButton1Click:Connect(function()
            selectedIslandPosition = island.Value
            dropdownHeader.Text = island.Name .. " 🔽"
            dropdownList.Visible = false
        end)
    end
    dropdownList.CanvasSize = UDim2.new(0, 0, 0, #islands * 32)
end

dropdownHeader.MouseButton1Click:Connect(function()
    dropdownList.Visible = not dropdownList.Visible
end)

local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(1, -20, 0, 35)
flyBtn.Position = UDim2.new(0, 10, 0, 80)
flyBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
flyBtn.Text = "Start Flight"
flyBtn.TextColor3 = Color3.new(1, 1, 1)
flyBtn.Font = Enum.Font.GothamBold
flyBtn.TextSize = 14
flyBtn.Parent = mainFrame
Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0, 6)

local pauseBtn = Instance.new("TextButton")
pauseBtn.Size = UDim2.new(1, -20, 0, 35)
pauseBtn.Position = UDim2.new(0, 10, 0, 120)
pauseBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 45)
pauseBtn.Text = "Pause Flight"
pauseBtn.TextColor3 = Color3.new(1, 1, 1)
pauseBtn.Font = Enum.Font.GothamBold
pauseBtn.TextSize = 14
pauseBtn.Parent = mainFrame
Instance.new("UICorner", pauseBtn).CornerRadius = UDim.new(0, 6)

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(1, -20, 0, 35)
cancelBtn.Position = UDim2.new(0, 10, 0, 160)
cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
cancelBtn.Text = "Cancel Flight"
cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.TextSize = 14
cancelBtn.Parent = mainFrame
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 6)

local dragging, dragInput, dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

topBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

flyBtn.MouseButton1Click:Connect(function()
    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart then return end
    
    if activeNavigation and activeNavigation._isNavigating then return end
    
    if not selectedIslandPosition then
        dropdownHeader.Text = "⚠️ Please select an island!"
        task.wait(2)
        if not selectedIslandPosition then dropdownHeader.Text = "Select Island 🔽" end
        return
    end
    
    flyBtn.Text = "Flying..."
    pauseBtn.Text = "Pause Flight"
    dropdownList.Visible = false
    
    activeNavigation = navigateTo(character, selectedIslandPosition, 90, 20)
    
    -- LIVE TRACKER LOOP
    task.spawn(function()
        while activeNavigation and activeNavigation._isNavigating do
            if activeNavigation._isPaused then
                flyBtn.Text = "Paused (" .. tostring(activeNavigation.Distance) .. " studs)"
            elseif activeNavigation._roboTarget then
                flyBtn.Text = "Lock: Robo! (" .. tostring(activeNavigation.Distance) .. " studs)"
            else
                flyBtn.Text = "Flying... (" .. tostring(activeNavigation.Distance) .. " studs)"
            end
            task.wait(0.1)
        end
        flyBtn.Text = "Start Flight"
        pauseBtn.Text = "Pause Flight"
    end)
end)

pauseBtn.MouseButton1Click:Connect(function()
    if activeNavigation and activeNavigation._isNavigating then
        local isPaused = activeNavigation:TogglePause()
        if isPaused then
            pauseBtn.Text = "Resume Flight"
            pauseBtn.BackgroundColor3 = Color3.fromRGB(45, 180, 100)
        else
            pauseBtn.Text = "Pause Flight"
            pauseBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 45)
        end
    end
end)

cancelBtn.MouseButton1Click:Connect(function()
    if activeNavigation and activeNavigation._isNavigating then
        activeNavigation:Cancel()
        flyBtn.Text = "Start Flight"
        pauseBtn.Text = "Pause Flight"
        pauseBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 45)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    if activeNavigation and activeNavigation._isNavigating then
        activeNavigation:Cancel()
    end
    screenGui:Destroy()
end)
