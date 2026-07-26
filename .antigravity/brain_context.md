# Strategic Memory (FISHMAN23)

## Workflow & Directories
- **Autoexec Path:** The primary local file path for testing and execution is always the Potassium autoexec: `C:\Users\luigi\AppData\Local\Potassium\autoexec`
- **Auto Commit & Deploy Requirement:** Always commit and push changes to GitHub after making modifications. ONLY copy main execution scripts (such as loaders or main controllers) to the Potassium autoexec folder. NEVER copy module scripts (e.g., `Model.lua`, `View.lua`) into autoexec, as executors run every script in that folder independently on startup.

## Architecture
- **MVC Structure:** `CombinedAutoLoad.lua` routes private server executions to load `Controller.lua` from GitHub, which in turn fetches and initializes `Model.lua` and `View.lua`.

