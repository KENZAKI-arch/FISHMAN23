-- ==========================================
-- Auto Reroll Race Script (UI Version)
-- ==========================================
local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 10)

if not PlayerGui then
    warn("PlayerGui not found!")
    return
end

local Customization = PlayerGui:WaitForChild("Customization", 10)
if not Customization then
    warn("Customization UI not found!")
    return
end

local Main = Customization:WaitForChild("Main", 10)
local RaceTypeLabel = Main:WaitForChild("RaceType", 10)

if not RaceTypeLabel then
    warn("Could not find RaceTypeLabel!")
    return
end

-- Stop previous instance
if getgenv().StopAutoReroll then
    pcall(getgenv().StopAutoReroll)
end

local isRunning = true
local isAutoRolling = false
local DESIRED_RACE = "SKYPIAN"

-- ======================================================================
-- 🎨 FLUENT UI INTEGRATION
-- ======================================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🧬 Race Reroller",
    SubTitle = "Auto-roller",
    TabWidth = 140,
    Size = UDim2.fromOffset(400, 260),
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Main = Window:AddTab({ Title = "Reroll", Icon = "dices" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

getgenv().StopAutoReroll = function()
    isRunning = false
    isAutoRolling = false
    if Window and type(Window.Destroy) == "function" then
        pcall(function() Window:Destroy() end)
    end
    print("[Auto Reroll] Stopped and cleaned up.")
end

-- ======================================================================
-- UI COMPONENTS
-- ======================================================================
local StatusPara = Tabs.Main:AddParagraph({ Title = "Current Status", Content = "Waiting..." })

Tabs.Main:AddInput("TargetRace", {
    Title = "Target Race",
    Default = "SKYPIAN",
    Placeholder = "Enter race name...",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        DESIRED_RACE = string.upper(Value)
    end
})

local RollToggle = Tabs.Main:AddToggle("T_Roll", { 
    Title = "Start Auto Rerolling", 
    Default = false 
})

RollToggle:OnChanged(function(Value)
    isAutoRolling = Value
    if Value then
        StatusPara:SetDesc("Rolling for: " .. DESIRED_RACE)
    else
        StatusPara:SetDesc("Paused.")
    end
end)

Tabs.Settings:AddButton({
    Title = "Destroy UI & Shutdown",
    Description = "Cleans up the script and unloads UI.",
    Callback = function()
        getgenv().StopAutoReroll()
    end
})

Window:SelectTab(1)
Fluent:Notify({ Title = "Loaded", Content = "Ready to reroll!", Duration = 3 })

-- ======================================================================
-- CORE LOOP
-- ======================================================================
task.spawn(function()
    while isRunning do
        if isAutoRolling then
            -- Read the current race
            local currentText = RaceTypeLabel.Text -- e.g., "You are a HUMAN"
            
            -- Check if it matches the target (case-insensitive check)
            if string.find(string.upper(currentText), DESIRED_RACE) then
                Fluent:Notify({ Title = "Success!", Content = "Successfully rolled " .. DESIRED_RACE .. "!", Duration = 5 })
                print("[Auto Reroll] Successfully rolled " .. DESIRED_RACE .. "!")
                
                -- Turn off the toggle
                if Fluent.Options.T_Roll then
                    Fluent.Options.T_Roll:SetValue(false)
                end
                isAutoRolling = false
                StatusPara:SetDesc("Finished! Got: " .. DESIRED_RACE)
            else
                -- If not match, fire the Reroll RemoteEvent
                pcall(function()
                    game:GetService("ReplicatedStorage"):WaitForChild("Events", 5):WaitForChild("reroll", 5):InvokeServer()
                end)
                StatusPara:SetDesc("Rerolled... Checking again.")
            end
        end
        
        -- Wait a moment before rerolling again to allow the server to process and UI to update
        task.wait(1.5)
    end
end)
