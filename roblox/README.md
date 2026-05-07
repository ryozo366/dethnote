# Femboy Obby - Roblox Game

## Wie du den Level in Roblox Studio lädst

### Schnellstart (Copy-Paste Methode)
1. Öffne **Roblox Studio** → neues Baseplate-Projekt
2. Gehe zu **View → Command Bar** (unten)
3. Öffne `BuildLevel1.luau`, kopiere den gesamten Inhalt
4. Paste in die Command Bar und drücke Enter
5. Die Map baut sich automatisch auf!

### Leaderboard einrichten
1. In Studio: Explorer → **ServerScriptService**
2. Neues Script erstellen, Inhalt von `src/ServerScriptService/Leaderboard.luau` reinkopieren

### Empfohlene Studio-Einstellungen
- **Baseplate löschen** (Explorer → Workspace → Baseplate → Delete) für Void-Look
- **SpawnLocation** auf der Start-Plattform platzieren (Model-Tab → Spawn)
- **Skybox**: Lighting → Atmosphere → Density 0.3, Color auf Pastel-Lila setzen
- **Ambient Light**: Lighting → Ambient → `RGB(255, 200, 220)` (rosa Tint)

## Level-Aufbau (Sektionen)

| Sektion | Name | Mechanic |
|---------|------|----------|
| 0 | Spawn Platform | Großes Start-Pad mit Katzenohren |
| 1 | Pastel Stepping Stones | Einfache Sprünge, zick-zack |
| 2 | Moving Platforms | Hin-her schwingende Plattformen |
| 3 | Cat Ear Tower | Hochklettern mit versetzten Pads |
| 4 | Spinner Gauntlet | Rotierende Kill-Bricks ausweichen |
| 5 | Rainbow Bridge | Schmale Neon-Brücke |
| 6 | Win Platform | Goldenes End-Pad mit Win-Screen |

## Farb-Palette

| Name | RGB |
|------|-----|
| Pink | 255, 182, 213 |
| Hot Pink | 255, 105, 180 |
| Lavender | 200, 170, 255 |
| Soft Purple | 160, 100, 220 |
| Pastel Blue | 180, 220, 255 |
