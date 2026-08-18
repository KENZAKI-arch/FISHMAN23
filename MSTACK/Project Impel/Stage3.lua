getgenv().CURRENT_STAGE = 3
getgenv().MACRO_WAYPOINTS = {
    -- ==========================================
    -- STAGE 3 (Waypoints)
    -- ==========================================
    -- Provide your first waypoint here! 
    { Pos = Vector3.new(4960, 2308, -20604), Action = "NAVIGATE" }, -- Stage 3 Spawn
    { Pos = Vector3.new(4963, 2307, -20763), Action = "NAVIGATE" },
    { Pos = Vector3.new(5102, 2307, -20792), Action = "NAVIGATE" }, -- clear room before lever appears
    { Pos = Vector3.new(5157, 2307, -20799), Action = "PULL_LEVER" }, -- pull lever here
    { Pos = Vector3.new(4970, 2307, -20761), Action = "NAVIGATE" }, -- go back here
    { Pos = Vector3.new(4802, 2307, -20757), Action = "NAVIGATE" }, -- clear room 
    { Pos = Vector3.new(4707, 2307, -20721), Action = "PULL_LEVER" }, -- pull lever
    { Pos = Vector3.new(4978, 2307, -20753), Action = "NAVIGATE" }, -- go back 
    { Pos = Vector3.new(4856, 2369, -20985), Action = "NAVIGATE" }, -- go here
    { Pos = Vector3.new(4794, 2400, -20828), Action = "NAVIGATE" }, -- boss fight
    { Pos = Vector3.new(5063, 2398, -20805), Action = "NAVIGATE" }, -- go here clear room
    { Pos = Vector3.new(5552, 2406, -20833), Action = "NAVIGATE" }, -- go here clear room again
    { Pos = Vector3.new(5696, 2444, -20799), Action = "NAVIGATE" }, -- stairway checkpoint
    { Pos = Vector3.new(5603, 2500, -20964), Action = "NAVIGATE" }, -- stairway room clear
    { Pos = Vector3.new(5683, 2482, -20533), Action = "NAVIGATE" }, -- boss fight (Final Boss Room)
    { Pos = Vector3.new(5666, 2489, -20268), Action = "WAIT_TELEPORT" }
    -- WAIT_TELEPORT will be added here once we have the Stage 4 teleporter coordinates!
}

print("[Impel] ⚙️ Stage 3 Configuration Loaded!")
