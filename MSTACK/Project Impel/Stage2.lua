getgenv().CURRENT_STAGE = 2
getgenv().MACRO_WAYPOINTS = {
    -- ==========================================
    -- STAGE 2 (Waypoints)
    -- ==========================================
    -- USE FLY_DIRECT to cross the void without triggering Pathfinding!
    { Pos = Vector3.new(3200, 2405, -20181), Action = "FLY_DIRECT" }, 
    
    { Pos = Vector3.new(3465, 2378, -20344), Action = "NAVIGATE" }, -- F2 Corridor
    { Pos = Vector3.new(3449, 2378, -20377), Action = "NAVIGATE" }, -- F2 Corridor Midpoint
    { Pos = Vector3.new(3462, 2378, -20618), Action = "NAVIGATE" }, -- F2 Corridor p2
    { Pos = Vector3.new(3198, 2343, -20539), Action = "PULL_LEVER" }, -- Lever Room
    { Pos = Vector3.new(3204, 2378, -20402), Action = "NAVIGATE" }, -- Reverse Path (Walk out of lever room)
    { Pos = Vector3.new(3200, 2375, -20737), Action = "END_MAZE" }  -- Final Boss Room
}

print("[Impel] ⚙️ Stage 2 Configuration Loaded!")
