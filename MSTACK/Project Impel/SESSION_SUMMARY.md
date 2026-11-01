# Complete Session Archive: Musashi Farm v1.0 & Combat Engine

**Session ID**: `f56d5e04-f1ea-4ca8-8cc9-c454912aac14`  
**Target Repository**: `FISHMAN23` (`MSTACK/Project Impel/CoreAutofarm.lua`, `Loader.lua`, `Stage3.lua`)  
**Parent Submodule**: `AutofishSYSTEMGIT` (`AUTOFISHMAN/FISHMAN23`)  
**Latest Deployed Commit**: `9ea23b3` on `origin main`

---

## 1. Executive Summary of Changes

Over the course of this session, the Project Impel Musashi Farm combat engine was upgraded with:
1. **v1.0 Top Header UI**: A draggable top bar with `[v1.0]` branding, close button, and cache-busting loader.
2. **Multi-Layered Hit Detection**: Sub-frame reaction to player damage via events, remotes, stuns, and health deltas.
3. **Rubberband Hit-and-Run Combat Cycle**: Faraway orbital spinning in a 30-stud safe zone, catapulting in at high speed, sneaking in a combo, and slingshotting back out.
4. **Vertical Head Strike Positioning**: Zero lateral offset, striking strictly from above the enemy's head.
5. **Head Jailer of Impel Down Boss Sizing & Priority**: Dynamic head elevation calculation for giant boss rigs (preventing grounded attacks) and full boss lock across all navigation and combat modes.

---

## 2. Chronological Log of User Requests & Solutions

### Request 1 & 2: Auto-Dodge & Safe Refill Spot
- **User Request**: Add auto-dodge; when HP drops to 600 against Head Jailer at Stage 3, go to `(5539, 2406, -20793)` to refill HP, then return.
- **Resolution**: Implemented outboxer dodge mechanics and waypoint routing.

### Request 3, 4, 5, 6: Outboxer Combat Distance & Vertical Head Positioning
- **User Request**: Make dodge studs farther (30 studs away), don't stay near the enemy (outboxer playstyle), and position attacks strictly vertically above the enemy's head with no sideways offset.
- **Resolution**:
  - Pinned attack CFrame directly above the enemy head:
    ```lua
    targetSpot = Vector3.new(eHrp.Position.X, desiredY, eHrp.Position.Z)
    ```
  - Configured 30-stud disengage radius (`math.max(30.0, enemyRadius + 20.0)`).
  - Ensured attacks halt during evasive disengage so swings aren't wasted into thin air.

### Request 7 & 8: UI Branding (`v1.0`)
- **User Request**: Put a `v1.0` version at the top of the UI.
- **Resolution**:
  - Built a dedicated dark header bar (`headerFrame`) positioned right at the top above the Musashi Farm toggle button.
  - Text: `MUSASHI FARM  [v1.0]` in bold gold accent (`Color3.fromRGB(255, 215, 0)`).
  - Interactive window dragging support attached to the header bar.
  - Added cache-busting parameters (`?t=timestamp`) in `Loader.lua` to prevent executor CDN caching.

### Request 9: Multi-Layered Hit Detection
- **User Request**: Detection of character getting hit wasn't triggering disengage.
- **Root Cause**: `tookDamage` was an undeclared local variable in `Controller.UpdateMovement`, and combat loops blocked in `task.wait()` without combo interruption flags.
- **Resolution**:
  - **`Humanoid.HealthChanged`**: Direct hook triggering on $\ge 0.1$ HP damage loss.
  - **Per-Frame Delta**: Heartbeat fallback check.
  - **Ragdoll & Stun Listeners**: Detects `Ragdolls` folder and stun attributes.
  - **Remote Interception**: Hooks `ClientDMG` and `CombatTag` remotes.
  - **Combo Breaker**: `cancelCombo` immediately exits active melee combo upon being hit.
  - **Auto Skill**: Fires `BasicEvasive` combo breaker.

### Request 10: Rubberband Hit-and-Run with Faraway Orbit Spin
- **User Request**: Sneak in attacks, get back to the enemy fast. Spin from faraway in the safe area, dash in to combo, and slingshot back out like rubberbanding.
- **Resolution**:
  - **Orbit Spin**: Rotates at `2.8 rad/s` at 30+ studs away with wall collision raycasting.
  - **Catapult Speed**: Boosted combat speed to `175 studs/s` (from `50`).
  - **Attack Pacing**: Tightened swing wait to `0.24s` and damage delay to `0.12s`.
  - **Rubberband Loop**: Lands combo, immediately sets `isDodgingAttack = true` for `1.05s`, catapulting back out to 30 studs.

### Request 11: Head Jailer Attacking on Ground Normally
- **User Request**: Against Head Jailer of Impel Down, the bot attacked on the ground normally instead of going above him.
- **Root Cause**:
  1. `desiredY` was hardcoded to `+ 7.5`, which placed the player at knee/shin height on giant 20+ stud tall boss models.
  2. `findStage3Boss` was omitted from `NAVIGATE_MAZE`, `MAZE_COMBAT`, `ROOM_ROUND_UP`, `ROOM_COMBAT`, and `findBestTarget()`, leaving the bot patrolling on the floor.
  3. Attack range checks used 3D distance to `bHrp`, which exceeded range when hovering high above the boss.
- **Resolution**:
  - Created `getEnemyHeadTopY(npc)` helper to find the exact top of the boss's `Head`.
  - Set `desiredY = math.max(headTopY + 4.5, eHrp.Position.Y + 7.5)`.
  - Integrated `findStage3Boss` across all combat and navigation modes with a 150-stud lock.
  - Separated horizontal and vertical hit registration checks in `Model.GetEnemiesInRange()` and `Model.DoMeleeCombo()`.

---

## 3. Key Configuration Parameters

| Parameter | Location | Value | Purpose |
| :--- | :--- | :--- | :--- |
| `flySpeed` | `CoreAutofarm.lua` | `50 studs/s` | Base navigation flight speed |
| `currentMoveSpeed` (Combat) | `CoreAutofarm.lua` | `175 studs/s` | Catapult rubberband dash-in / snap-out |
| `orbitAngle` rate | `CoreAutofarm.lua` | `2.8 rad/s` | Safe faraway orbit evasion speed |
| Orbit Distance | `CoreAutofarm.lua` | `30+ studs` | Distance maintained during safe orbit |
| Head Clearance | `CoreAutofarm.lua` | `+ 4.5 studs` | Vertical distance directly above enemy head |
| Swing Pacing | `CoreAutofarm.lua` | `0.24s` | M1 swing interval |
| Damage Pacing | `CoreAutofarm.lua` | `0.12s` | Damage packet invocation delay |
| Boss Lock Distance | `CoreAutofarm.lua` | `150 studs` | Maximum distance to maintain combat lock on bosses |

---

## 4. Git Commits & Deployment History

- `e4ac15f`: Initial outboxer 32-stud evasion and v1.0 UI header bar.
- `07a3aa0`: Multi-layered hit detection engine (Humanoid, Remotes, Stuns, BasicEvasive).
- `473e3e6`: Rubberband combat cycle with faraway orbit spin and 175 studs/s speed.
- `9ea23b3`: Head Jailer boss prioritization, dynamic head elevation, and 3D hit registration fix.
