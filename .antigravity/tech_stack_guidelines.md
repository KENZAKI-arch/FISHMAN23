# Long-Term Memory (FISHMAN23)

## Project-Wide Setups & Tech Stack
- Language: Luau (Roblox Lua)
- Environment: Roblox Studio / Executor Client

## Error Log & Critical Lessons
- **Second Sea Teleport (GPO):** Teleporting to the Second Sea in GPO requires a 2-step sequence: 1) Open sea menu via `PlayerGui.chooseType.Frame.RemoteEvent:FireServer(true)`, wait **0.5 seconds**, and 2) Confirm via `PlayerGui.ConfirmationPrompt.RemoteEvent:FireServer("Second Sea")`. Never send `"Second Sea"` to `chooseType.Frame.RemoteEvent` as it is invalid and will abort the teleport state.
- **Memory Leaks from Executors:** When building executor scripts, NEVER leave `RunService` or `workspace.DescendantAdded` connections unwrapped. If a user re-executes a script without a global GC (`getgenv().StopPrevious`), the connections stack infinitely and crash the game. Always use `_connections` and an `addConn()` wrapper to cleanly destroy them upon script reload.
- **Inventory Data (GPO):** `PlayerGui.ui.inventoryJSONData` no longer exists. All inventory bait and fish data is correctly fetched and parsed from `ReplicatedStorage.Stats[LocalPlayer.Name].Inventory.Inventory` via JSON decoding.
- **Background Loops & Conditionals:** Do not hardcode vital logic (like auto-refilling bait) behind a single unrelated toggle's background loop (e.g. `if autoBuy then CheckInventory()`). If the user leaves `autoBuy` off, the bait refill logic silently fails because the loop never triggers.
- **Pause Logic Integrity:** The global pause (`F` keybind) and the `storeFruits`/`dropFruits` pause functions shouldn't explicitly turn off the `CyborgAuto` toggle, as the `MegStack` toggle natively handles cycling the Cyborg Autofarm on and off based on the megalodon count.
- **Devil Fruit Type Detection (GPO):** In GPO, Devil Fruits carry the Roblox attribute `Category` set to `"Special"`. All fruit detection functions (`isTargetFruit`) use `tool:GetAttribute("Category") == "Special"` with target fruit string name checking as a fallback.
- **Handling StreamingEnabled for Vehicles:** When game streaming is active, a vehicle's `BasePart`s (like `VehicleSeat`) may stream out, causing `FindFirstChild("VehicleSeat", true)` to fail. However, the empty `Model` instance itself usually persists in Workspace. As a mitigation, fallback to returning the `Model` itself and fetch its coordinates using `hoverboard:GetPivot()` rather than `hoverboard.CFrame`.
