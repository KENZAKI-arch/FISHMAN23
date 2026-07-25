# Long-Term Memory (FISHMAN23)

## Project-Wide Setups & Tech Stack
- Language: Luau (Roblox Lua)
- Environment: Roblox Studio / Executor Client

## Guidelines
- **Workflow:** Always commit and push modifications to GitHub, and copy the updated script to `C:\Users\luigi\AppData\Local\Potassium\autoexec`.
- **Manual Travel & Flight Cancellation:** For manual travel features (e.g., `T_ManualMegStackLoc`), use a dedicated state flag (`Model.State.isManualTraveling`) rather than reusing other flags like `isRefillingMegBait`. When toggled OFF, set `isManualTraveling = false`, `isCraftFlying = false`, and call `Model.DisableFlight()` to immediately pause travel in place rather than triggering an auto-return flight.
