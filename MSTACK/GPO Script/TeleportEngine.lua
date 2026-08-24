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

-- ======================================================================
-- 🚀 TELEPORT MEMORY INJECTION
-- ======================================================================
local myScriptURL = "https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/refs/heads/main/MSTACK/joinersystem.lua"
local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
local UpdateTeleportMemory -- Forward declaration

-- ======================================================================
-- 🔄 AUTO RECONNECT ENGINE
-- ======================================================================
getgenv().FishmanState.addConn(GuiService.ErrorMessageChanged:Connect(function()
    if GlobalMem.FishmanAutoReconnect then
        task.spawn(function()
            -- It's a disconnect! Reroute to configured Default PS and Destination!
            if GlobalMem.FishmanDefaultPSCode then GlobalMem.FishmanPSCode = GlobalMem.FishmanDefaultPSCode end
            if GlobalMem.FishmanDefaultDestination then GlobalMem.FishmanDestination = GlobalMem.FishmanDefaultDestination end
            GlobalMem.FishmanAutoTeleport = true
            getgenv().FishmanState.SaveConfig()
            
            while getgenv().FishmanState._running and task.wait(5) do
                pcall(function()
                    if UpdateTeleportMemory then UpdateTeleportMemory(true) end
                    TeleportService:Teleport(targetPlaceId, LocalPlayer)
                end)
            end
        end)
    end
end))

function UpdateTeleportMemory(willAutoTeleport)
    GlobalMem.FishmanAutoTeleport = willAutoTeleport
    GlobalMem.LastTeleportTime = os.time()
    getgenv().FishmanState.SaveConfig()
    
    if not qot then return end
    
    local command = [[
        pcall(function()
            getgenv().FishmanPSCode = "]] .. GlobalMem.FishmanPSCode .. [["
            getgenv().FishmanDestination = "]] .. GlobalMem.FishmanDestination .. [["
            getgenv().FishmanDefaultPSCode = "]] .. tostring(GlobalMem.FishmanDefaultPSCode or "") .. [["
            getgenv().FishmanDefaultDestination = "]] .. tostring(GlobalMem.FishmanDefaultDestination or "") .. [["
            getgenv().FishmanQOT_Active = true
            getgenv().FishmanAutoTeleport = ]] .. tostring(willAutoTeleport) .. [[
            
            task.spawn(function()
                task.wait(15)
                if getgenv().FishmanScriptServer ~= game.JobId then
                    loadstring(game:HttpGet("]] .. myScriptURL .. [["))()
                end
            end)
        end)
    ]]
    pcall(function() qot(command) end)
end

local function GetCurrentPSCode()
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

local function ActivatePotatoGraphics()
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
        task.spawn(function()
            if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            elseif child:IsA("BasePart") then
                child.CastShadow = false
            end
        end)
    end))
    
    if getgenv().FishmanState.Fluent then getgenv().FishmanState.Fluent:Notify({ Title = "Anti-Lag", Content = "Potato Graphics Active!", Duration = 3 }) end
    print("Anti-Lag: Active")
end
