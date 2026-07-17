local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Create a folder in CoreGui to store all ESP highlights so they don't clutter workspace
local espFolder = CoreGui:FindFirstChild("RoboESPFolder")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "RoboESPFolder"
    espFolder.Parent = CoreGui
end

-- Configuration
local ESP_COLOR = Color3.fromRGB(255, 50, 50)
local TARGET_NAME = "Robo" -- The name (or partial name) of the NPC you want to ESP

local function createESP(npc)
    if not npc:IsA("Model") then return end
    
    local espName = "ESP_" .. tostring(npc:GetDebugId(10))
    
    -- Check if it already has ESP
    if espFolder:FindFirstChild(espName) then
        return
    end

    -- Create Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = espName
    highlight.Adornee = npc
    highlight.FillColor = ESP_COLOR
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = espFolder
    
    -- Create Name Tag (BillboardGui)
    local headOrRoot = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
    if headOrRoot then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NameTag"
        billboard.Adornee = headOrRoot
        billboard.Size = UDim2.new(0, 100, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = billboard
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = npc.Name
        textLabel.TextColor3 = ESP_COLOR
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.Font = Enum.Font.Code
        textLabel.TextScaled = true
        
        billboard.Parent = highlight
    end
    
    -- Clean up when NPC is destroyed
    local connection
    connection = npc.AncestryChanged:Connect(function(_, parent)
        if not parent then
            highlight:Destroy()
            connection:Disconnect()
        end
    end)
end

local function scanForRobos()
    -- Scan through workspace for models that match our criteria
    -- We look for models containing "Robo" in their name and having a Humanoid
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and string.find(string.lower(obj.Name), string.lower(TARGET_NAME)) then
            -- Optional: ensure it's an NPC by checking for a Humanoid
            if obj:FindFirstChildOfClass("Humanoid") then
                createESP(obj)
            end
        end
    end
end

-- Initial scan
scanForRobos()

-- Keep scanning periodically for newly spawned NPCs
-- We use a loop instead of Heartbeat to reduce lag if there are many parts in workspace
task.spawn(function()
    while task.wait(2) do
        scanForRobos()
    end
end)

print("Robo NPC ESP Loaded!")
