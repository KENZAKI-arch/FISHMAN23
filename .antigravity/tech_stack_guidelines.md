# Long-Term Memory (FISHMAN23)

## Project-Wide Setups & Tech Stack
- Language: Luau (Roblox Lua)
- Environment: Roblox Studio / Executor Client

## Error Log & Critical Lessons
- **Memory Leaks from Executors:** When building executor scripts, NEVER leave `RunService` or `workspace.DescendantAdded` connections unwrapped. If a user re-executes a script without a global GC (`getgenv().StopPrevious`), the connections stack infinitely and crash the game. Always use `_connections` and an `addConn()` wrapper to cleanly destroy them upon script reload.
- **Inventory Data (GPO):** `PlayerGui.ui.inventoryJSONData` no longer exists. All inventory bait and fish data is correctly fetched and parsed from `ReplicatedStorage.Stats[LocalPlayer.Name].Inventory.Inventory` via JSON decoding.
- **Background Loops & Conditionals:** Do not hardcode vital logic (like auto-refilling bait) behind a single unrelated toggle's background loop (e.g. `if autoBuy then CheckInventory()`). If the user leaves `autoBuy` off, the bait refill logic silently fails because the loop never triggers.
