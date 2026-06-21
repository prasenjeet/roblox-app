# Architecture

How the server, client, and shared modules interact at runtime.

---

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        ROBLOX SERVER                            │
│                                                                 │
│  GameManager.server.lua                                         │
│  ├─ Builds course (StageBuilder)                                │
│  ├─ Owns playerData table                                       │
│  ├─ Manages checkpoints, kills, coins, finish                   │
│  └─ Drives moving platforms & spinners (Heartbeat)              │
│                                                                 │
│  CoinService.server.lua                                         │
│  └─ Animates coin parts (Heartbeat)                             │
│                                                                 │
│  TimerService.server.lua                                        │
│  ├─ Broadcasts TimerTick every 1s                               │
│  ├─ Records fastest-times table                                 │
│  └─ Exposes GetFastestTimes RemoteFunction                      │
└────────────────────┬────────────────────────────────────────────┘
                     │  RemoteEvents / RemoteFunction
                     │  (ReplicatedStorage)
┌────────────────────▼────────────────────────────────────────────┐
│                       ROBLOX CLIENT (per player)                │
│                                                                 │
│  ObbyClient.client.lua                                          │
│  ├─ CheckpointReached → floating text + screen flash            │
│  ├─ PlayerDied        → red screen flash                        │
│  ├─ CoinCollected     → floating text + HUD update              │
│  ├─ CourseCompleted   → show FinishScreen, fire ConfirmCompletion│
│  └─ TimerTick         → update TimerLabel                       │
│                                                                 │
│  HUD (ScreenGui)                                                │
│  └─ Stage · Deaths · Coins · Timer                              │
│                                                                 │
│  FinishScreen (ScreenGui)                                       │
│  └─ Time · Deaths · Coins · Play Again button                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Player Joins

```
Players.PlayerAdded
    │
    ├── Server: setupLeaderboard(player)         → IntValues in leaderstats
    ├── Server: playerData[player] = { ... }
    └── Server: player.CharacterAdded → teleport to Stage 1 spawn
```

### Checkpoint Touched

```
Part.Touched (server)
    │
    ├── Server: validate (stageNum > data.stage)
    ├── Server: data.stage = stageNum
    ├── Server: leaderstats.Stage.Value = stageNum
    ├── Server: checkpoint.Color = gold
    └── Server: CheckpointReached:FireClient(player, stageNum)
                    │
                    └── Client: floating text + green flash + HUD update
```

### Player Dies

```
Humanoid.Died (server)
    │
    ├── Server: data.deaths += 1
    ├── Server: leaderstats.Deaths.Value updated
    ├── Server: PlayerDied:FireClient(player)
    │               │
    │               └── Client: red screen flash + HUD death update
    │
    └── Roblox: respawn after Players.RespawnTime
                    │
                    └── Server: CharacterAdded → teleport to last checkpoint
```

### Coin Collected

```
Part.Touched (server)
    │
    ├── Server: guard (collectedCoins[coin] check)
    ├── Server: coin hidden (Transparency=1, CanCollide=false)
    ├── Server: data.coins += COIN_VALUE
    ├── Server: leaderstats.Coins updated
    ├── Server: CoinCollected:FireClient(player, value)
    │               │
    │               └── Client: floating text + HUD update
    └── Server: task.delay(30) → coin becomes visible again
```

### Course Completed

```
FinishTrigger.Touched (server)
    │
    ├── Server: guard (data.completed check)
    ├── Server: data.completed = true
    ├── Server: elapsed = tick() - data.startTime
    └── Server: CourseCompleted:FireClient(player, elapsed, deaths, coins)
                    │
                    └── Client: FinishScreen.Visible = true
                                ConfirmCompletion:FireServer(elapsed)
                                    │
                                    └── Server (TimerService): recordTime(name, elapsed)
```

---

## ReplicatedStorage Layout

```
ReplicatedStorage
├── Shared/
│   ├── Constants        ModuleScript
│   └── StageBuilder     ModuleScript
├── CheckpointReached    RemoteEvent   (Server → Client)
├── PlayerDied           RemoteEvent   (Server → Client)
├── CourseCompleted      RemoteEvent   (Server → Client)
├── CoinCollected        RemoteEvent   (Server → Client)
├── ConfirmCompletion    RemoteEvent   (Client → Server, via TimerService)
├── GetFastestTimes      RemoteFunction (Client invokes Server)
└── TimerTick            RemoteEvent   (Server → All Clients, 1/sec)
```

---

## CollectionService Tags

Tags are the coupling point between geometry and game logic. Adding a tag is how a Part "opts in" to a behaviour:

| Tag | Set by | Consumed by | Effect |
|---|---|---|---|
| `Checkpoint` | `StageBuilder` | `GameManager` | Tracks player stage progress |
| `KillBrick` | `StageBuilder` | `GameManager` | Kills any humanoid on touch |
| `Coin` | `StageBuilder` | `GameManager`, `CoinService` | Awards points; animated |
| `Finish` | `StageBuilder` | `GameManager` | Triggers course completion |

New tagged parts added after server start are picked up automatically via `GetInstanceAddedSignal`.

---

## Part Attributes

Part attributes are the coupling point between geometry and the Heartbeat loop:

| Attribute | Type | Set by | Read by | Effect |
|---|---|---|---|---|
| `Moving` | `bool` | `StageBuilder` | `GameManager.indexDynamicParts` | Adds to moving-parts list |
| `MoveRange` | `number` | `StageBuilder` | `GameManager` Heartbeat | Sine amplitude in studs |
| `MoveSpeed` | `number` | `StageBuilder` | `GameManager` Heartbeat | Sine frequency |
| `Spinning` | `bool` | `StageBuilder` | `GameManager.indexDynamicParts` | Adds to spinning-parts list |
| `SpinSpeed` | `number` | `StageBuilder` | `GameManager` Heartbeat | Degrees/second around Y |
| `StageNumber` | `number` | `StageBuilder` | `GameManager` checkpoint handler | Identifies which stage |

---

## Security Considerations

All authoritative game state lives **on the server**:

- `playerData` is never exposed to clients.
- `leaderstats` values are written only by the server.
- Coin collection is guarded by `collectedCoins[coin]` on the server; the client cannot duplicate-collect.
- Course completion (`data.completed`) is a server flag; a client cannot fire `ConfirmCompletion` twice to spam the times board (the server's `recordTime` will only update if the new time is better).

The client's only write channel is `ConfirmCompletion:FireServer(seconds)` and `GetFastestTimes:InvokeServer()` — neither can affect core game state, only the cosmetic fastest-times table.
