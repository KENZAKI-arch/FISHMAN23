-- Teleport Engine

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or shared
local GlobalMem = env

-- Bind state variables locally for ease of use in this file
local _running = getgenv().FishmanState._running
local _connections = getgenv().FishmanState._connections
local Tabs = getgenv().FishmanState.Tabs
local Fluent = getgenv().FishmanState.Fluent
local addConn = getgenv().FishmanState.addConn
local disconnectAll = getgenv().FishmanState.disconnectAll
local TriggerSafeguardShutdown = getgenv().FishmanState.TriggerSafeguardShutdown
local SaveConfig = getgenv().FishmanState.SaveConfig
local isLobby = getgenv().FishmanState.isLobby


local mySession = getgenv().FishmanSession or 0

-- ======================================================================
-- 🚀 TELEPORT MEMORY INJECTION
-- ======================================================================
local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/loader.lua"
local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
getgenv().FishmanState.UpdateTeleportMemory = nil -- Forward declaration

-- ======================================================================
-- 🛡️ SAFEGUARD APP SHUTDOWN (ON DISCONNECT / RESTART)
-- ======================================================================
local function TriggerAppShutdown(reason)
    if getgenv().FishmanState.CloseRobloxApp then
        getgenv().FishmanState.CloseRobloxApp(reason)
    end
end

-- 1. GuiService Error Message (Kicks, Disconnect Error 277/268/529, Server Shutdown)
getgenv().FishmanState.addConn(GuiService.ErrorMessageChanged:Connect(function(errorMessage)
    if errorMessage and #errorMessage > 0 then
        TriggerAppShutdown("Disconnect / Error Detected: " .. tostring(errorMessage))
    end
end))

-- 2. CoreGui Disconnect Modal Watcher (Roblox prompt overlay)
task.spawn(function()
    pcall(function()
        local CoreGui = game:GetService("CoreGui")
        local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 10)
        local promptOverlay = promptGui and promptGui:WaitForChild("promptOverlay", 10)
        if promptOverlay then
            getgenv().FishmanState.addConn(promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" or child.Name:find("Prompt") then
                    task.wait(0.2)
                    TriggerAppShutdown("Disconnect Prompt Displayed (" .. tostring(child.Name) .. ")")
                end
            end))
        end
    end)
end)

-- 3. Teleport / Game Restart Failures
getgenv().FishmanState.addConn(TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    TriggerAppShutdown("Teleport / Restart Failed: " .. tostring(errorMessage))
end))

getgenv().FishmanState.UpdateTeleportMemory = function(willAutoTeleport)
    GlobalMem.FishmanAutoTeleport = willAutoTeleport
    GlobalMem.LastTeleportTime = os.time()
    getgenv().FishmanState.SaveConfig()
    
    -- Legacy queue_on_teleport removed for stability. 
    -- The script relies entirely on disk-saved state (Config.lua) for teleport persistence.
end

getgenv().FishmanState.GetCurrentPSCode = function()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local settingsGui = playerGui:FindFirstChild("Settings")
        if settingsGui then
            local main = settingsGui:FindFirstChild("Main")
            if main then
                local codeLabel = main:FindFirstChild("Code")
                if codeLabel and (codeLabel:IsA("TextLabel") or codeLabel:IsA("TextBox")) then
                    return codeLabel.Text
                end
            end
        end
    end
    return ""
end

getgenv().FishmanState.ActivatePotatoGraphics = function()
    if _G.PotatoGraphicsActive then return end
    _G.PotatoGraphicsActive = true
    
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.FogStart = 9e9

    settings().Rendering.QualityLevel = 1

    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CastShadow = false
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            pcall(function() v.BackSurface = "SmoothNoOutlines" end)
            pcall(function() v.BottomSurface = "SmoothNoOutlines" end)
            pcall(function() v.FrontSurface = "SmoothNoOutlines" end)
            pcall(function() v.LeftSurface = "SmoothNoOutlines" end)
            pcall(function() v.RightSurface = "SmoothNoOutlines" end)
            pcall(function() v.TopSurface = "SmoothNoOutlines" end)
        elseif v:IsA("Decal") then
            v.Transparency = 1
            v.Texture = ""
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        end
    end

    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("PostEffect") then
            v.Enabled = false
        end
    end

    getgenv().FishmanState.addConn(workspace.DescendantAdded:Connect(function(child)
        if child:IsA("BasePart") then
            child.CastShadow = false
        elseif child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
            task.spawn(function()
                RunService.Heartbeat:Wait()
                if child and child.Parent then
                    pcall(function() child:Destroy() end)
                end
            end)
        end
    end))
    
    if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Anti-Lag", Content = "Potato Graphics Active!", Duration = 3 }) end
    print("Anti-Lag: Active")
end
