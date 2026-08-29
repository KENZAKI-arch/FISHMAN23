-- Version 3.8
-- ======================================================================
-- ⚙️ SETTINGS TAB UI
-- ======================================================================
Tabs.Settings:AddToggle("T_AutoReconnect", { 
    Title = "Auto Reconnect on Disconnect", 
    Default = GlobalMem.FishmanAutoReconnect, 
    Callback = function(Value)
        GlobalMem.FishmanAutoReconnect = Value
        SaveConfig()
    end 
})

Tabs.Settings:AddToggle("T_AntiLag", { 
    Title = "Disable 3D Rendering (Anti-Lag)", 
    Default = false, 
    Callback = function(Value)
        RunService:Set3dRenderingEnabled(not Value)
    end 
})

Tabs.Settings:AddSlider("S_FPSCap", {
    Title = "FPS Cap",
    Description = "Limits your FPS to reduce CPU/GPU usage when AFKing.",
    Default = 35,
    Min = 5,
    Max = 240,
    Rounding = 0,
    Callback = function(Value)
        if setfpscap then pcall(setfpscap, Value) end
    end
})

Tabs.Settings:AddButton({
    Title = "🥔 Potato Graphics",
    Description = "Reduces all game graphics to the absolute minimum for maximum FPS.",
    Callback = function()
        ActivatePotatoGraphics()
    end
})

Tabs.Settings:AddButton({
    Title = "🔄 Update / Load Latest Version",
    Description = "Destroys the current UI and executes the latest joinersystem from GitHub.",
    Callback = function()
        Fluent:Notify({ Title = "Updating", Content = "Fetching latest script from GitHub...", Duration = 3 })
        ShutdownEverything()
        if Window and Window.Destroy then
            Window:Destroy()
        end
        task.wait(1)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/FISHMAN23/main/MSTACK/joinersystem.lua?t="..tostring(tick())))()
    end
})

Tabs.Settings:AddButton({
    Title = "Destroy UI & Shutdown",
    Description = "Cleans up all loops, unloads the UI, and stops the script safely.",
    Callback = function()
        ShutdownEverything()
        if Window and Window.Destroy then
            Window:Destroy()
        end
    end
})

Window:SelectTab(isLobby and 1 or 2)
Fluent:Notify({ Title = "Fishman Unified", Content = "Script loaded successfully!", Duration = 5 })

local isPaused = false
local savedState = {}

addConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    secondsSinceLastInput = 0
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        isPaused = not isPaused
        if isPaused then
            Fluent:Notify({ Title = "🛑 Emergency Stop", Content = "Script paused! Press F again to resume.", Duration = 5 })
            
            -- Stop Auto Start state (AFK Mode)
            isAFKModeActive = false
            if Fluent.Options and Fluent.Options.T_AFK then
                Fluent.Options.T_AFK:SetValue(false)
            end

            if Model and Model.State then
                -- Save current task states
                savedState = {
                    isFishing = Model.State.isFishing,
                    autoBuy = Model.State.autoBuy,
                    autoSell = Model.State.autoSell,
                    isAutoTraveling = Model.State.isAutoTraveling,
                    autoCraft = Model.State.autoCraft,
                    isCurrentlyCrafting = Model.State.isCurrentlyCrafting,
                    antiLag = (Fluent.Options and Fluent.Options.T_AntiLag) and Fluent.Options.T_AntiLag.Value or false,
                    deepSea = (Fluent and Fluent.Options and Fluent.Options.T_DeepSea) and Fluent.Options.T_DeepSea.Value or false,
                    megStack = (Fluent and Fluent.Options and Fluent.Options.T_MegStack) and Fluent.Options.T_MegStack.Value or false,
                    megStackLoc = (Fluent and Fluent.Options and Fluent.Options.T_MegStackLoc) and Fluent.Options.T_MegStackLoc.Value or false
                }

                -- Force stop everything instantly
                Model.State.isFishing = false
                -- Model.State.autoBuy = false
                Model.State.autoSell = false
                Model.State.isAutoTraveling = false
                Model.State.autoCraft = false
                Model.State.isCurrentlyCrafting = false
                Model.State.isCraftFlying = false
                Model.State.isBuying = false
                
                -- Update UI toggles to visually show they are off
                if Fluent.Options then
                    if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(false) end
                    -- if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(false) end
                    if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(false) end
                    if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(false) end
                    if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(false) end
                    if Fluent.Options.T_AntiLag then Fluent.Options.T_AntiLag:SetValue(false) end
                    if Fluent.Options.T_DeepSea then Fluent.Options.T_DeepSea:SetValue(false) end
                    if Fluent.Options.T_MegStack then Fluent.Options.T_MegStack:SetValue(false) end
                    if Fluent.Options.T_MegStackLoc then Fluent.Options.T_MegStackLoc:SetValue(false) end
                end

                -- Abort actions
                if Model.DisableFlight then pcall(Model.DisableFlight) end
                if Model.UnequipRod then pcall(Model.UnequipRod) end
                if Model.State.activeNavigation and Model.State.activeNavigation._isNavigating then
                    Model.State.activeNavigation:Cancel()
                end

                -- Close any dialogue
                pcall(function()
                    local events = ReplicatedStorage:FindFirstChild("Events")
                    local quest = events and events:FindFirstChild("Quest")
                    if quest then quest:InvokeServer({ [1] = "npcChat", [2] = false }) end
                end)
            end
        else
            Fluent:Notify({ Title = "▶️ Resumed", Content = "Script restored to previous tasks.", Duration = 5 })

            if Model and Model.State then
                -- Restore previously active tasks
                Model.State.isFishing = savedState.isFishing or false
                Model.State.autoBuy = savedState.autoBuy or false
                Model.State.autoSell = savedState.autoSell or false
                Model.State.isAutoTraveling = savedState.isAutoTraveling or false
                Model.State.autoCraft = savedState.autoCraft or false
                
                -- Update UI toggles visually to match restored state
                if Fluent.Options then
                    if Fluent.Options.T_Fish then Fluent.Options.T_Fish:SetValue(Model.State.isFishing) end
                    if Fluent.Options.T_Buy then Fluent.Options.T_Buy:SetValue(Model.State.autoBuy) end
                    if Fluent.Options.T_Sell then Fluent.Options.T_Sell:SetValue(Model.State.autoSell) end
                    if Fluent.Options.T_Travel then Fluent.Options.T_Travel:SetValue(Model.State.isAutoTraveling) end
                    if Fluent.Options.T_Craft then Fluent.Options.T_Craft:SetValue(Model.State.autoCraft) end
                    if Fluent.Options.T_AntiLag and savedState.antiLag then Fluent.Options.T_AntiLag:SetValue(true) end
                    if Fluent.Options.T_DeepSea then Fluent.Options.T_DeepSea:SetValue(savedState.deepSea) end
                    if Fluent.Options.T_MegStack then Fluent.Options.T_MegStack:SetValue(savedState.megStack) end
                    if Fluent.Options.T_MegStackLoc then Fluent.Options.T_MegStackLoc:SetValue(savedState.megStackLoc) end
                end

                -- Resume traveling if needed
                if Model.State.isAutoTraveling and Model.StartTraveling then
                    Model.StartTraveling()
                end
            end
        end
    end
end))
addConn(UserInputService.InputChanged:Connect(function() secondsSinceLastInput = 0 end))

if OrionLib then OrionLib:Init() end
