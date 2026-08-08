-- ========================================== --
-- DUPLICATE GUARD
-- ========================================== --
if getgenv().FishmanAutoFarmRunning then 
    warn("Script is already running! Preventing duplicate.")
    return 
end
getgenv().FishmanAutoFarmRunning = true

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for LocalPlayer to exist
repeat task.wait() until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

local targetPlaceId = 1730877806

-- ========================================== --
-- THE VIP LIST (PLAYER PS CODES)
-- ========================================== --
local playerCodes = {
    ["MechaGlider42"] = "qj1ttW4JG1",
    ["TurboWisp_99"] = "zbjzi1NnJX",
    ["ViridianSpark12334"] = "QhEcbyZOja",
    ["ButterflyWater1282"] = "eVyQDUetrk",
    ["Seonhee234"] = "7SLb9HLpN5",
    ["DomainRichards123"] = "qj1ttW4JG1",
    ["ShenzhenBeiwang"] = "vYF7N93cqH",
    ["LuminousTide5"] = "7SLb9HLpN9",
    ["FriskCharacter1223"] = "dmgBOmXnQy",
    ["Bluepurpleguygojo2"] = "Cl2TZMcuBt",
    ["IgnisWeaver"] = "orXYYLZ717",
    ["ThalassaRift12"] = "PRriWnrVWW"
}

local myPSCode = playerCodes[LocalPlayer.Name]

-- Debug: confirm which account is running
print("[Debug] Running as: " .. LocalPlayer.Name)
if myPSCode then
    print("[Debug] PS Code found: " .. myPSCode)
else
    print("[Debug] No PS Code assigned!")
end

-- ========================================== --
-- THE INFINITE LOOP (AUTO-LOAD)
-- ========================================== --
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/CombinedAutoLoad.lua"
local loadCommand = "loadstring(game:HttpGet('" .. myScriptURL .. "?v=' .. tostring(math.random())))()"

if queue_on_teleport then
    queue_on_teleport(loadCommand) 
    print("[Loader] Locked and loaded for the next teleport!")
end

-- ========================================== --
-- DISCONNECT WATCHER (Runs all the time)
-- ========================================== --
local GuiService = game:GetService("GuiService")
GuiService.ErrorMessageChanged:Connect(function()
    print("[Watcher] Disconnected! Auto-rejoining in 5 seconds...")
    task.wait(5) 
    
    -- Clear the flag BEFORE teleporting
    getgenv().FishmanAutoFarmRunning = false
    
    pcall(function()
        TeleportService:Teleport(targetPlaceId, LocalPlayer)
    end)
end)

-- ========================================== --
-- THE FORK IN THE ROAD (Routing)
-- ========================================== --
if game.PlaceId == targetPlaceId and game.PrivateServerId == "" then
    
    -- PATH A: We are in the public lobby.
    if myPSCode then
        print("[Logic] Code found for " .. LocalPlayer.Name .. "! Joining Private Server in 5 seconds...")
        task.wait(5)
        
        task.spawn(function()
            local codeArgs = { [1] = myPSCode }
            local events = ReplicatedStorage:WaitForChild("Events", 9e9)
            local reserved = events:WaitForChild("reserved", 9e9)
            reserved:InvokeServer(unpack(codeArgs))
        end)
        
        task.wait(1)
        
        -- Clear the flag BEFORE teleporting to PS
        getgenv().FishmanAutoFarmRunning = false
        
        local confirmArgs = { [1] = "true" }
        
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 9e9)
        local chooseType = playerGui:WaitForChild("chooseType", 9e9)
        local frame = chooseType:WaitForChild("Frame", 9e9)
        local remoteEvent = frame:WaitForChild("RemoteEvent", 9e9)
        
        remoteEvent:FireServer(unpack(confirmArgs))
        print("[Logic] Sequence complete. Teleporting...")
    else
        print("[Logic] No Private Server code assigned for " .. LocalPlayer.Name .. ". Staying in public server.")
    end

else
    
    -- PATH B: We are in the Private Server.
    print("[Logic] In Private Server. Setting up Auto-Farm Tween UI...")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TweenToFarmGui"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function() screenGui.Parent = CoreGui end)
    if not success then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local tweenBtn = Instance.new("TextButton")
    tweenBtn.Size = UDim2.new(0, 200, 0, 50)
    tweenBtn.Position = UDim2.new(0.5, -100, 0.2, 0)
    tweenBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    tweenBtn.Text = "AUTO FARM"
    tweenBtn.TextColor3 = Color3.fromRGB(85, 255, 85)
    tweenBtn.Font = Enum.Font.GothamBold
    tweenBtn.TextSize = 20
    tweenBtn.Parent = screenGui
    Instance.new("UICorner", tweenBtn).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", tweenBtn)
    stroke.Color = Color3.fromRGB(85, 255, 85)
    stroke.Thickness = 2

    tweenBtn.MouseButton1Click:Connect(function()
        tweenBtn.Text = "TRAVELING..."
        tweenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stroke.Color = Color3.fromRGB(255, 255, 255)
        tweenBtn.Active = false

        local RunService = game:GetService("RunService")
        local targetX = 7976.704
        local targetY = -2152.832
        local targetZ = -17074.277
        local targetLandingPos = Vector3.new(targetX, targetY, targetZ)
        local flySpeed = 90

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")

        local bv = rootPart:FindFirstChild("AntiGravity") or Instance.new("BodyVelocity")
        bv.Name = "AntiGravity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = rootPart

        local noclipLoop
        local flightLoop

        noclipLoop = RunService.Stepped:Connect(function()
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)

        flightLoop = RunService.Heartbeat:Connect(function(deltaTime)
            if not rootPart or not rootPart.Parent then return end

            if _G.CancelAutoTravel == true then
                if bv then bv:Destroy() end
                if noclipLoop then noclipLoop:Disconnect() end
                if flightLoop then flightLoop:Disconnect() end
                screenGui:Destroy()
                return
            end

            local currentPos = rootPart.Position
            local nextPoint
            
            if math.abs(currentPos.X - targetX) > 1 then
                nextPoint = Vector3.new(targetX, currentPos.Y, currentPos.Z)
            elseif math.abs(currentPos.Z - targetZ) > 1 then
                nextPoint = Vector3.new(targetX, currentPos.Y, targetZ)
            elseif math.abs(currentPos.Y - targetY) > 1 then
                nextPoint = Vector3.new(targetX, targetY, targetZ)
            else
                -- ARRIVED
                if bv then bv:Destroy() end
                if noclipLoop then noclipLoop:Disconnect() end
                if flightLoop then flightLoop:Disconnect() end
                
                screenGui:Destroy()
                
                print("[Logic] Arrived at Fishman Island. Loading Controller...")
                loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/Controller.lua"))()
                return
            end

            local finalCFrame = CFrame.lookAt(nextPoint, targetLandingPos) 
            local distance = (currentPos - nextPoint).Magnitude
            
            if distance > 0.5 then
                local lerpAlpha = math.clamp((flySpeed * deltaTime) / distance, 0, 1)
                rootPart.CFrame = rootPart.CFrame:Lerp(finalCFrame, lerpAlpha)
            else
                rootPart.CFrame = finalCFrame
            end
            
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.RotVelocity = Vector3.new(0, 0, 0)
        end)
    end)

end