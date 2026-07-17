local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local targetFruits = {
    "Dragon", "Venom", "Mochi", "Soul", "Pika", "Buddha", "Magu", "Goro", "Goru",
    "Hie", "Kage", "Mera", "Tori", "Pteranodon", "Smoke", "Yami", "Suna", "Ope"
}

local function storeTargetFruits(fruitList)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    if not character or not humanoid or not backpack then return end
    
    -- Count fruits in inventory first
    local inventoryCounts = {}
    local foundAny = false
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local toolName = string.lower(tool.Name)
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    inventoryCounts[tool.Name] = (inventoryCounts[tool.Name] or 0) + 1
                    foundAny = true
                    break
                end
            end
        end
    end
    
    -- Print the inventory summary
    if foundAny then
        print("--- Target Fruits in Inventory ---")
        for name, count in pairs(inventoryCounts) do
            print(count .. "x " .. name)
        end
        print("----------------------------------")
    else
        print("No target fruits found in inventory.")
    end
    
    -- Loop through all tools in the backpack to attempt storing
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local toolName = string.lower(tool.Name)
            local isTargetFruit = false
            
            -- Check if the tool's name matches any fruit in our list
            for _, fruitName in ipairs(fruitList) do
                if string.find(toolName, string.lower(fruitName)) then
                    isTargetFruit = true
                    break
                end
            end
            
            if isTargetFruit then
                -- Force-equip the tool (fruit)
                humanoid:EquipTool(tool)
                
                -- Wait a split second to ensure the server registers the equip
                task.wait(0.2)
                
                -- Fire the remote to attempt to store it
                ReplicatedStorage.Events.FruitStorage:InvokeServer(true)
                print("Attempted to store: " .. tool.Name)
                
                -- Wait before trying the next item
                task.wait(0.5)
            end
        end
    end
end

-- Run the function using our list of targeted fruits
storeTargetFruits(targetFruits)
