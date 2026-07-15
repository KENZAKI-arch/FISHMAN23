local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function analyzeJSON(sourceName, valueObj)
    if not valueObj then
        print("❌ [" .. sourceName .. "] Object not found!")
        return
    end

    local rawJSON = valueObj.Value
    if type(rawJSON) ~= "string" or rawJSON == "" then
        print("❌ [" .. sourceName .. "] Value is empty or not a string.")
        return
    end

    local ok, data = pcall(function() return HttpService:JSONDecode(rawJSON) end)
    if not ok then
        print("❌ [" .. sourceName .. "] Failed to decode JSON! Raw value:")
        print(rawJSON)
        return
    end

    if type(data) ~= "table" then
        print("❌ [" .. sourceName .. "] Decoded data is not a table!")
        return
    end

    local baitFound = false
    local baitItems = {}

    for k, v in pairs(data) do
        local keyStr = string.lower(tostring(k))
        if string.find(keyStr, "bait") then
            table.insert(baitItems, tostring(k) .. ": " .. tostring(v))
            baitFound = true
        end
    end

    if baitFound then
        print("✅ [" .. sourceName .. "] SUCCESS! Found Bait Keys:")
        for _, b in ipairs(baitItems) do
            print("  -> " .. b)
        end
    else
        print("⚠️ [" .. sourceName .. "] Decoded successfully, but NO keys containing the word 'bait' were found.")
        print("Here is a dump of all keys inside " .. sourceName .. " to help identify the problem:")
        local allKeys = {}
        for k, _ in pairs(data) do
            table.insert(allKeys, tostring(k))
        end
        print("  -> " .. table.concat(allKeys, ", "))
    end
end

print("\n=======================================================")
print("🔍 FISHMAN BAIT DETECTOR DEBUGGER STARTED")
print("=======================================================")

-- 1. Check PlayerGui.ui.inventoryJSONData
local ui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ui")
local invDataObj = ui and ui:FindFirstChild("inventoryJSONData")
analyzeJSON("PlayerGui.ui.inventoryJSONData", invDataObj)

-- 2. Check ReplicatedStorage.Stats[PlayerName].Inventory.Inventory
local statsFolder = ReplicatedStorage:FindFirstChild("Stats" .. LocalPlayer.Name)
local statsInvObj = statsFolder and statsFolder:FindFirstChild("Inventory") and statsFolder.Inventory:FindFirstChild("Inventory")
analyzeJSON("ReplicatedStorage.Stats.Inventory", statsInvObj)

print("=======================================================\n")
