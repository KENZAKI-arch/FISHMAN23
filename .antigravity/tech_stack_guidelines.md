# Long-Term Memory (FISHMAN23)

## Project-Wide Setups & Tech Stack
- Language: Luau (Roblox Lua)
- Environment: Roblox Studio / Executor Client

## Guidelines
- **Workflow:** Always commit and push modifications to GitHub, and copy the updated script to `C:\Users\luigi\AppData\Local\Potassium\autoexec`.
- **Manual Travel & Flight Cancellation:** For manual travel features (e.g., `T_ManualMegStackLoc`), use a dedicated state flag (`Model.State.isManualTraveling`) rather than reusing other flags like `isRefillingMegBait`. When toggled OFF, set `isManualTraveling = false`, `isCraftFlying = false`, and call `Model.DisableFlight()` to immediately pause travel in place rather than triggering an auto-return flight.
- **UI Toggle Initialization & Lobby Safeguards:** In Fluent UI, toggle callbacks execute immediately upon creation with their Default value (`false`). When loading external gameplay scripts (e.g., `protov4_nofactory.lua`), always verify `if Value` before fetching or executing. In addition, always guard gameplay-dependent toggles with `if isLobby then return end` so that synchronous `WaitForChild` calls in external scripts do not freeze UI initialization when loaded in the Lobby.
