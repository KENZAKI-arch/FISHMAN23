getgenv().CURRENT_STAGE = 1
getgenv().MACRO_WAYPOINTS = {
    -- ==========================================
    -- STAGE 1 (Maze Part)
    -- ==========================================
    { Pos = Vector3.new(2953, 2075, -14005), Action = "NAVIGATE" }, -- F1 Start
    { Pos = Vector3.new(2664, 2075, -15490), Action = "WAIT_TELEPORT" } -- F1 End (Teleports to F2)
}

print("[Impel] ⚙️ Stage 1 Configuration Loaded!")
