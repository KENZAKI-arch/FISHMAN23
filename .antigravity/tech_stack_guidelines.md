# Long-Term Memory (FISHMAN23)

## Project-Wide Setups & Tech Stack
- Language: Luau (Roblox Lua)
- Environment: Roblox Studio / Executor Client

## Guidelines
- **Workflow:** Always commit and push modifications to GitHub, and copy the updated script to `C:\Users\luigi\AppData\Local\Potassium\autoexec`.
- **Travel Toggles & Auto Return:** When disabling manual or temporary travel toggles (like Manual Meg Stack Travel), do NOT automatically re-enable `T_AutoReturn` or spawn return flight loops. Doing so causes Auto Return to trigger immediately if distance > 20 studs, preventing the character from halting or dropping where they stand. Always zero `AssemblyLinearVelocity` and `AssemblyAngularVelocity` in `DisableFlight()` to drop without inertia.
