# Strategic Memory (FISHMAN23)

## Workflow & Directories
- **Autoexec Path:** The primary local file path for testing and execution is always the Potassium autoexec: `C:\Users\luigi\AppData\Local\Potassium\autoexec`
- **Auto Commit & Deploy Requirement:** Always commit and push changes to GitHub after making modifications, and ensure the updated file is also copied to the Potassium autoexec folder.

## Architecture
- **MVC Structure:** `CombinedAutoLoad.lua` routes private server executions to load `Controller.lua` from GitHub, which in turn fetches and initializes `Model.lua` and `View.lua`.

