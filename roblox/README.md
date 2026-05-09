# Lava Run – Roblox Setup

## Workspace
Three parts in `Workspace`:
- `Start`  – touch starts run + lava + timer
- `Finish` – touch ends run, saves time to top-100
- `Lava`   – position **(13.676, -45.984, 62.35)**, will be anchored by the script

> Note: the part is now called **Finish** (was `Ziel`). Rename it in your place.

## Scripts
- `ServerScript_LavaRun.lua` -> `ServerScriptService` (as a `Script`)
- `LocalScript_UI.lua`       -> `StarterPlayer/StarterPlayerScripts` (as a `LocalScript`)

## Lava image
The lava part is textured with a Decal on all 6 faces. To use the attached
picture:

1. In Roblox Studio: **Asset Manager -> Decals -> Add new** and upload the image.
2. Right-click the uploaded decal -> **Copy ID to Clipboard**.
3. Open `ServerScript_LavaRun.lua` and replace
   `local LAVA_IMAGE_ID = "rbxassetid://0"` with `rbxassetid://<your id>`.

(Roblox doesn't let scripts upload images at runtime - you must upload it
once via Studio.)

## Game Settings
- **Security -> Enable Studio Access to API Services**: ON (required for DataStore)

## Behavior
- Lava speed: **5.5 studs/sec**, stops at **y = 180**
- Lava touch kills the player
- On death: timer is reset (server **and** client side), lava drops back
  to its start position, run no longer counts
- Touching `Start` again always re-resets the lava and starts a fresh timer
- Reaching `Finish` without dying submits the time to the top-100 leaderboard
  (pastel-pink UI on the right)
- DataStores: `LavaRunTopTimes_v1` (OrderedDataStore) + `LavaRunNames_v1`
