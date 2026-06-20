# Roblox Obby Game

A sample Roblox obstacle course (obby) game built with Lua scripts, structured for use with [Rojo](https://rojo.space/) to sync files into Roblox Studio.

## Game Features

- **Obstacle Course (Obby)** – 10 progressively harder stages
- **Checkpoint System** – Players respawn at the last checkpoint they touched
- **Leaderboard** – Live stage progress shown on the in-game leaderboard
- **Death Counter** – Tracks how many times each player has fallen
- **Coin Collectibles** – Scattered coins that award points
- **Timer** – Tracks how long players take to complete the full course
- **Finish Line** – Triggers a congratulations UI and records fastest times

## Project Structure

```
src/
├── ServerScriptService/     # Server-side game logic
│   ├── GameManager.server.lua       # Core game loop, checkpoints, leaderboard
│   ├── CoinService.server.lua       # Coin spawning and collection
│   └── TimerService.server.lua      # Completion timer tracking
├── StarterPlayerScripts/    # Client-side scripts (run per player)
│   └── ObbyClient.client.lua        # Death effects, checkpoint UI feedback
├── StarterGui/              # UI elements
│   └── ObbyGui/
│       ├── HUD.lua                  # Stage & death count HUD
│       └── FinishScreen.lua         # End-of-course congratulations screen
├── ReplicatedStorage/       # Shared modules
│   └── Shared/
│       ├── Constants.lua            # Game constants (stage count, coin value, etc.)
│       └── StageBuilder.lua         # Procedural stage generation helper
└── Workspace/
    └── CourseTemplate.lua           # Workspace setup reference
```

## Setup with Rojo

1. Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/)
2. Open Roblox Studio with your place file
3. Install the Rojo Studio plugin
4. Run `rojo serve` from this directory
5. Connect in Studio via the Rojo plugin

## Default.project.json

A `default.project.json` is included so Rojo knows how to map `src/` folders to the correct Roblox services.

## Development

Scripts follow these conventions:
- `*.server.lua` – Server Scripts (run in `ServerScriptService`)
- `*.client.lua` – Local Scripts (run in `StarterPlayerScripts`)
- `*.lua` without suffix – Module Scripts

## License

MIT
