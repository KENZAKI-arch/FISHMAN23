getgenv().CURRENT_STAGE = 2
getgenv().MACRO_WAYPOINTS = {
    -- ==========================================
    -- STAGE 2 (Waypoints)
    -- ==========================================
    -- USE FLY_DIRECT to cross the void without triggering Pathfinding!
    { Pos = Vector3.new(3200, 2405, -20181), Action = "FLY_DIRECT" }, 
    
    -- Intermediate checkpoint to help the pathfinder connect the bridge/room
    { Pos = Vector3.new(3194, 2380, -20286), Action = "NAVIGATE" }, 
    { Pos = Vector3.new(3199, 2378, -20401), Action = "NAVIGATE" },
    
    { Pos = Vector3.new(3465, 2378, -20344), Action = "NAVIGATE" }, -- F2 Corridor
    { Pos = Vector3.new(3449, 2378, -20377), Action = "NAVIGATE" }, -- F2 Corridor Midpoint
    { Pos = Vector3.new(3462, 2378, -20618), Action = "NAVIGATE" }, -- F2 Corridor p2
    { Pos = Vector3.new(3383, 2343, -20565), Action = "NAVIGATE" }, -- Pre-Lever Room
    { Pos = Vector3.new(3199, 2343, -20559), Action = "NAVIGATE" }, -- Pre-Lever Room 2
    { Pos = Vector3.new(3198, 2343, -20539), Action = "PULL_LEVER" }, -- Lever Room
    { Pos = Vector3.new(3200, 2343, -20559), Action = "FLY_DIRECT" }, -- 3200 Exit Lever Room (Fly straight through door)
    { Pos = Vector3.new(3438, 2378, -20408), Action = "NAVIGATE" }, -- F2 Corridor Return
    { Pos = Vector3.new(3199, 2378, -20398), Action = "NAVIGATE" }, -- Central Hall Junction (In front of Boss Gate)
    { Pos = Vector3.new(3200, 2378, -20624), Action = "NAVIGATE" }, -- Boss Gate Hallway
    { Pos = Vector3.new(3200, 2375, -20737), Action = "NAVIGATE" }, -- Final Boss Room (Kills Impel Down High Elite Guard)
    { Pos = Vector3.new(3197, 2379, -21085), Action = "WAIT_TELEPORT" } -- Teleporter to Stage 3
}

print("[Impel] ⚙️ Stage 2 Configuration Loaded!")