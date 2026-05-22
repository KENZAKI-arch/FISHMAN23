local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Define our paths so the script is easier to read
local eventsFolder = ReplicatedStorage:WaitForChild("Events", 9e9)
local questEvent = eventsFolder:WaitForChild("Quest", 9e9)
local setSpawnEvent = eventsFolder:WaitForChild("SetSpawn", 9e9)
local roboNpc = Workspace:WaitForChild("NPCs", 9e9):WaitForChild("Robo", 9e9)

-- =========================================== --
-- SIMULATING THE INTERACTION
-- =========================================== --

-- Step 1: Open the NPC Chat
questEvent:InvokeServer({"npcChat", true})

task.wait(0.5) -- Wait half a second so the server registers the chat is open

-- Step 2: Trigger the "Set Spawn" action
-- Note: Your remote logger showed the NPC was the 2nd argument, meaning the 1st is nil.
setSpawnEvent:FireServer(nil, roboNpc)

task.wait(0.5) -- Wait half a second for the save to process

-- Step 3: Close the NPC Chat
questEvent:InvokeServer({"npcChat", false})