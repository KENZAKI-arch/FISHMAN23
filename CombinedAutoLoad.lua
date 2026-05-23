local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local targetPlaceId = 1730877806

-- ========================================== --
-- PART 1: THE DISCONNECT WATCHER
-- ========================================== --
-- This runs constantly in the background, watching for the disconnect screen.
task.spawn(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
    
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            print("[Watcher] Disconnected! Auto-rejoining in 5 seconds...")
            task.wait(5) 
            
            pcall(function()
                TeleportService:Teleport(targetPlaceId, LocalPlayer)
            end)
        end
    end)
end)

-- ========================================== --
-- PART 2: TARGET PLACE LOGIC
-- ========================================== --
-- This checks your current location. If you are in the target place, it runs the sequence.
if game.PlaceId == targetPlaceId then
    print("[Logic] Target place detected. Starting sequence in 5 seconds...")
    task.wait(5)
    
    -- STEP 1: Send the teleport code to the server
    task.spawn(function()
        local codeArgs = {
            [1] = "qj1ttW4JG1"
        }
        
        -- Storing these variables makes the code a bit cleaner and easier to read
        local events = ReplicatedStorage:WaitForChild("Events", 9e9)
        local reserved = events:WaitForChild("reserved", 9e9)
        
        reserved:InvokeServer(unpack(codeArgs))
    end)
    
    -- Wait a tiny bit just to make sure Step 1 sends before Step 2 confirms
    task.wait(1)
    
    -- STEP 2: Send the "tradeHub" confirmation
    local confirmArgs = {
        [1] = "true"
    }
    
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 9e9)
    local chooseType = playerGui:WaitForChild("chooseType", 9e9)
    local frame = chooseType:WaitForChild("Frame", 9e9)
    local remoteEvent = frame:WaitForChild("RemoteEvent", 9e9)
    
    remoteEvent:FireServer(unpack(confirmArgs))
    print("[Logic] Sequence complete!")
end