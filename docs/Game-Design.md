# Game Design

This page describes the full gameplay loop, stage breakdown, scoring, and design rationale.

---

## Gameplay Loop

```
Spawn at Stage 1
    │
    ▼
Navigate platforms → touch Checkpoint flag
    │
    ├─► Fall on kill brick / off platform → respawn at last checkpoint
    │
    ▼
Collect coins along the way (+5 pts each)
    │
    ▼
Reach Stage 10 end → touch Finish platform
    │
    ▼
Finish Screen: Time · Deaths · Coins collected
    │
    ▼
Play Again → respawn at Stage 1 (deaths / timer reset)
```

---

## Stage Breakdown

All stages are spaced **100 studs** apart along the X axis. The course runs in a straight line so players always know which direction to go.

| Stage | Theme | Key Mechanic | Difficulty |
|---|---|---|---|
| 1 | Stepping Stones | Wide gaps, large platforms | ★☆☆☆☆ |
| 2 | Narrow Planks | Small 4×4 platforms with side gaps | ★★☆☆☆ |
| 3 | Staircase | Rising platforms (+4 studs each) | ★★☆☆☆ |
| 4 | Moving Platforms | Sine-wave side-to-side motion | ★★★☆☆ |
| 5 | Kill-Brick Flanks | Kill bricks on the platform edges | ★★★☆☆ |
| 6 | Zigzag | Alternating Z-offset platforms | ★★★☆☆ |
| 7 | Lava Floor | Giant kill-brick floor; tiny walkway | ★★★★☆ |
| 8 | Vertical Jumps | Platforms rise 10 studs per hop | ★★★★☆ |
| 9 | Spinners | Rotating kill-brick bars on platforms | ★★★★☆ |
| 10 | Final Gauntlet | Moving + vertical + spinning combined | ★★★★★ |

### Stage Generation

Each stage is built at runtime by `StageBuilder.buildStage(stageNumber, originX, parent)`. The config table for each stage specifies:

- `platforms` – list of `{size, offset, moving?}` entries
- `kills` – list of `{size, offset, spin?}` kill-brick entries
- `killY` – Y level of the invisible kill floor

This means **adding a new stage requires only a new entry in the config table** — no manual Studio work needed. See [Extending the Game](Extending-the-Game.md).

---

## Checkpoints

- One checkpoint flag (a tall 2×6×2 Part) sits at the start of every stage.
- Tagged `Checkpoint` via `CollectionService`; carries the `StageNumber` attribute.
- On touch, if the stage number is higher than the player's current stage, their `stage` is updated and the flag turns gold.
- On death, `GameManager` teleports the character to `getSpawnForStage(data.stage)` after a 0.1-second delay (allowing the character to fully load).

---

## Coins

- 3 coins per stage × 10 stages = **30 coins total**.
- Each coin is worth **5 points** (configurable in `Constants.COIN_VALUE`).
- Coins animate (bob + spin) driven by `CoinService`.
- Once collected, the coin becomes invisible/non-collidable and respawns after **30 seconds**.
- The `Coins` value in `leaderstats` updates in real time.

---

## Leaderboard

The in-game leaderboard (the default Roblox scoreboard shown by pressing Tab) shows three stats per player:

| Stat | Source |
|---|---|
| **Stage** | Updated whenever a checkpoint is touched |
| **Deaths** | Incremented in `Humanoid.Died` callback |
| **Coins** | Incremented on coin collection |

These are `IntValue` instances inside a `leaderstats` folder, which Roblox renders automatically on the leaderboard.

---

## Timer

- Each player's start time is `tick()` captured in `playerData` when they join.
- The client tracks its own elapsed time locally using `player:GetAttribute("JoinTime")`.
- `TimerService` broadcasts a server heartbeat (`TimerTick` RemoteEvent) every second so all clients can keep their HUD timers in sync.
- On course completion, the elapsed seconds are sent to the server and recorded in the fastest-times table.

---

## Fastest Times

`TimerService` maintains a server-side top-5 table:

```lua
{ { name = "PlayerA", time = 142 }, { name = "PlayerB", time = 198 }, ... }
```

Clients can query it via the `GetFastestTimes` RemoteFunction. A future leaderboard UI panel can call this to show the all-time best times for the current server session.

---

## Death & Respawn Flow

```
Humanoid.Health → 0
    │
    ├─ Server: deaths += 1, leaderstats.Deaths updated
    ├─ Server: RemoteEvent "PlayerDied" fired to client
    │       └─ Client: red screen flash
    │
    └─ Roblox: character respawns (RespawnTime property on Players service)
            └─ Server: CharacterAdded fires → teleport to last checkpoint
```

`RespawnTime` defaults to 5 seconds. You can reduce it in Studio under `Players.RespawnTime` or via script:
```lua
game:GetService("Players").RespawnTime = 2.5
```

---

## Difficulty Scaling

Moving platform speed: `1.5 + stageNumber × 0.15` studs/second of sine phase.  
Spinner speed: `45 + stageNumber × 5` degrees/second.  
Both values are set as Part attributes by `StageBuilder` so they can be tweaked without touching server logic.
