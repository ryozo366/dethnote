# Lava Run – Roblox Setup

## Workspace
Drei Parts in `Workspace`:
- `Start` – Touch löst Run + Lava + Timer aus
- `Ziel` – Touch beendet Run, speichert Zeit ins Top-100
- `Lava` – Position **(13.676, -45.984, 62.35)**, wird vom Script anchored

## Scripts
- `ServerScript_LavaRun.lua` → `ServerScriptService` (als `Script`)
- `LocalScript_UI.lua` → `StarterPlayer/StarterPlayerScripts` (als `LocalScript`)

## Game Settings
- **Security → Enable Studio Access to API Services**: AN (für DataStore)

## Verhalten
- Lava-Geschwindigkeit: **5.5 studs/sek**, stoppt bei **y = 180**
- Lava-Berührung tötet Spieler → Timer reset, Lava reset
- Ziel ohne Tod: Zeit kommt ins Top-100 Leaderboard (pastel-pink UI rechts)
- DataStore: `LavaRunTopTimes_v1` (OrderedDataStore) + `LavaRunNames_v1`
