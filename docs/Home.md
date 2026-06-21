# Roblox Obby Game – Wiki

Welcome to the documentation for the **Roblox Obby Game** – a 10-stage obstacle course built in Lua, structured for [Rojo](https://rojo.space/) sync with Roblox Studio.

---

## Pages

| Page | Description |
|---|---|
| [Setup Guide](Setup-Guide.md) | Install Rojo, sync to Studio, and run the game |
| [Game Design](Game-Design.md) | Stage breakdown, gameplay loop, and feature overview |
| [Scripting Reference](Scripting-Reference.md) | API docs for every script and module |
| [Extending the Game](Extending-the-Game.md) | Add stages, obstacles, coins, and UI elements |
| [Architecture](Architecture.md) | How the server, client, and shared modules interact |

---

## At a Glance

```
10 stages  ·  30 coins  ·  checkpoint system  ·  live leaderboard  ·  fastest-times board
```

### Feature Summary

- **Procedural course generation** – all stages are built at runtime from config tables in `StageBuilder.lua`; no manual Part placement needed in Studio.
- **Checkpoint & respawn** – players respawn at the last stage checkpoint they touched, not back at Stage 1.
- **Kill bricks** – tagged with `KillBrick` via `CollectionService`; touching any kill brick sets `Humanoid.Health = 0`.
- **Moving platforms** – driven by a `RunService.Heartbeat` loop on the server using a sine wave; speed scales with stage number.
- **Spinning obstacles** – server-side rotation applied every `Heartbeat` frame.
- **Coins** – 3 coins per stage, each worth 5 points; respawn after 30 seconds; animated (bob + spin) by `CoinService`.
- **HUD** – shows Stage, Deaths, Coins, and elapsed Time; updates reactively on `leaderstats` value changes.
- **Finish screen** – animated card overlay with Time, Deaths, and Coins on completion; Play Again button respawns the character.
- **Fastest-times board** – server keeps the top 5 completion times (per player name) accessible via `RemoteFunction`.

---

## Quick Start

```bash
# 1. Install Rojo CLI
aftman install   # or: cargo install rojo

# 2. Serve the project
cd roblox-app
rojo serve

# 3. In Roblox Studio, install the Rojo plugin and click Connect
```

See [Setup Guide](Setup-Guide.md) for full details.

---

## Project Structure

```
roblox-app/
├── default.project.json          Rojo project manifest
├── docs/                         Wiki pages (this folder)
└── src/
    ├── ServerScriptService/
    │   ├── GameManager.server.lua
    │   ├── CoinService.server.lua
    │   └── TimerService.server.lua
    ├── StarterPlayerScripts/
    │   └── ObbyClient.client.lua
    ├── StarterGui/ObbyGui/
    │   ├── HUD.lua
    │   └── FinishScreen.lua
    ├── ReplicatedStorage/Shared/
    │   ├── Constants.lua
    │   └── StageBuilder.lua
    └── Workspace/
        └── CourseTemplate.lua
```
