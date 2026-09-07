-- ==========================================
-- PROJECT IMPEL - HEALTH CHECK COMMAND
-- ==========================================

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Clean up any previous instance
if getgenv()._HealthCheckCleanup then
    pcall(getgenv()._HealthCheckCleanup)
end

local function getHealthString()
    local char = LocalPlayer.Character
    local hum = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid"))
    if hum then
        local currentHp = math.floor(hum.Health + 0.5)
        return string.format("You have %d HP!", currentHp)
    end
    return nil
end

getgenv().CheckHP = function()
    local hpText = getHealthString()
    if hpText then
        print(hpText)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Health Status",
                Text = hpText,
                Duration = 3
            })
        end)
        return hpText
    else
        warn("[HealthCheck] Humanoid or Character not found!")
    end
end
getgenv().PrintHP = getgenv().CheckHP

-- Print health immediately on execution
local initialHp = getgenv().CheckHP()

local function handleChatCommand(message)
    if not message then return end
    local clean = string.lower(string.gsub(message, "^%s*(.-)%s*$", "%1"))
    if clean == "/hp" or clean == "!hp" or clean == ":hp" or clean == "/health" or clean == "!health" or clean == "hp" or clean == "/checkhp" then
        getgenv().CheckHP()
    end
end

local conns = {}

-- Legacy Chat Connection
local legacyChatConn = LocalPlayer.Chatted:Connect(handleChatCommand)
table.insert(conns, legacyChatConn)

-- Modern TextChatService Connection
pcall(function()
    if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChatConn = TextChatService.MessageReceived:Connect(function(textChatMessage)
            if textChatMessage.TextSource and textChatMessage.TextSource.UserId == LocalPlayer.UserId then
                handleChatCommand(textChatMessage.Text)
            end
        end)
        table.insert(conns, textChatConn)
    end
end)

-- Hotkey Connection (F6)
local hotkeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        getgenv().CheckHP()
    end
end)
table.insert(conns, hotkeyConn)

getgenv()._HealthCheckCleanup = function()
    for _, conn in ipairs(conns) do
        pcall(function() conn:Disconnect() end)
    end
end

print("[HealthCheck] ✅ Standalone Health Check initialized! Type '/hp' in chat, press F6, or run getgenv().CheckHP()")
