# Scripting Reference

Full API documentation for every script and module in the project.

---

## Constants (`ReplicatedStorage.Shared.Constants`)

Shared configuration consumed by both server and client scripts.

```lua
local Constants = require(game.ReplicatedStorage.Shared.Constants)
```

### Values

| Key | Type | Default | Description |
|---|---|---|---|
| `STAGE_COUNT` | `number` | `10` | Total number of stages in the course |
| `COIN_VALUE` | `number` | `5` | Points awarded per coin collected |
| `RESPAWN_DELAY` | `number` | `2.5` | Seconds between death and teleport to checkpoint |
| `CHECKPOINT_COLOR` | `Color3` | Green | Default color for untouched checkpoint flags |
| `CHECKPOINT_TOUCHED_COLOR` | `Color3` | Gold | Color after a player activates the checkpoint |
| `STAGE_LENGTH` | `number` | `80` | Studs along X per stage (used to space stages) |
| `STAGE_WIDTH` | `number` | `20` | Maximum Z width of a stage |
| `PLATFORM_Y` | `number` | `0` | Base Y for all spawn platforms |
| `KILL_TAG` | `string` | `"KillBrick"` | CollectionService tag for kill bricks |
| `CHECKPOINT_TAG` | `string` | `"Checkpoint"` | CollectionService tag for checkpoint flags |
| `COIN_TAG` | `string` | `"Coin"` | CollectionService tag for coin collectibles |
| `FINISH_TAG` | `string` | `"Finish"` | CollectionService tag for the finish trigger |

### `Constants.EVENTS`

RemoteEvent names expected in `ReplicatedStorage`:

| Key | Value | Direction | Payload |
|---|---|---|---|
| `CHECKPOINT_REACHED` | `"CheckpointReached"` | Server → Client | `stageNumber: number` |
| `PLAYER_DIED` | `"PlayerDied"` | Server → Client | _(none)_ |
| `COURSE_COMPLETED` | `"CourseCompleted"` | Server → Client | `seconds, deaths, coins` |
| `COIN_COLLECTED` | `"CoinCollected"` | Server → Client | `value: number` |

---

## StageBuilder (`ReplicatedStorage.Shared.StageBuilder`)

Procedural stage and coin generator. Called once at server startup by `GameManager`.

```lua
local StageBuilder = require(game.ReplicatedStorage.Shared.StageBuilder)
```

### `StageBuilder.buildStage(stageNumber, originX, parent)`

Builds one stage folder in `parent`.

| Parameter | Type | Description |
|---|---|---|
| `stageNumber` | `number` | Stage index 1–10; selects the config entry |
| `originX` | `number` | World X position for the stage start |
| `parent` | `Instance` | Where to parent the resulting `Folder` |

**Returns:** `Folder` containing all Parts for the stage, or `nil` if `stageNumber` is out of range.

**Created children:**

| Child name | Tag | Notable attributes |
|---|---|---|
| `SpawnPlatform` | — | Large green starting platform |
| `Checkpoint` | `Checkpoint` | `StageNumber: number` |
| `Platform` (×N) | — | `Moving: bool`, `MoveRange: number`, `MoveSpeed: number` |
| `KillBrick` (×N) | `KillBrick` | `Spinning: bool`, `SpinSpeed: number` |
| `KillFloor` | `KillBrick` | 90% transparent invisible kill floor |

---

### `StageBuilder.buildFinish(originX, parent)`

Builds the finish area after the last stage.

| Parameter | Type | Description |
|---|---|---|
| `originX` | `number` | World X position |
| `parent` | `Instance` | Parent for the `Folder` |

**Returns:** `Folder` with `FinishPlatform`, `FinishTrigger` (tagged `Finish`), and `Trophy`.

---

### `StageBuilder.placeCoin(position, parent)`

Places a single animated coin collectible.

| Parameter | Type | Description |
|---|---|---|
| `position` | `Vector3` | World position of the coin |
| `parent` | `Instance` | Parent instance |

**Returns:** The coin `Part` (tagged `Coin`, `CanCollide = false`).

---

## GameManager (`ServerScriptService.GameManager`)

Server script. Runs once on server start. Owns the entire game state.

### Responsibilities

- Builds the course via `StageBuilder`.
- Creates all `RemoteEvent` / `RemoteFunction` instances in `ReplicatedStorage`.
- Manages `playerData` table.
- Connects `Touched` listeners for checkpoints, kill bricks, coins, and the finish trigger.
- Drives moving platforms and spinning obstacles via `RunService.Heartbeat`.

### `playerData[player]`

```lua
{
    stage     = 1,      -- Current highest stage reached
    deaths    = 0,      -- Lifetime deaths this session
    coins     = 0,      -- Total coin points collected
    startTime = tick(), -- Server time when the player joined
    completed = false,  -- True once the finish trigger is touched
}
```

### Internal Functions

| Function | Description |
|---|---|
| `setupLeaderboard(player)` | Creates `leaderstats` folder with Stage, Deaths, Coins IntValues |
| `getSpawnForStage(stage)` | Returns the `Vector3` above the spawn platform for a given stage |
| `respawnAt(player, position)` | Teleports `HumanoidRootPart` to `position` |
| `onCheckpointTouched(checkpoint, otherPart)` | Validates and advances player stage |
| `onKillBrickTouched(_, otherPart)` | Sets `Humanoid.Health = 0` |
| `onCoinTouched(coin, otherPart)` | Awards points, hides coin, schedules respawn |
| `onFinishTouched(_, otherPart)` | Fires `CourseCompleted` to the player |
| `indexDynamicParts()` | Scans Workspace for Moving/Spinning attribute parts |

---

## CoinService (`ServerScriptService.CoinService`)

Server script. Animates all `Coin`-tagged parts every `Heartbeat`.

**Animation applied each frame:**
```
position.Y = origin.Y + sin(t × 2 + phase) × 0.4   -- bobbing
rotation   = CFrame.Angles(0, t×2 + phase, rad(90)) -- spinning
```

Coins that are invisible (collected) are skipped to avoid wasted computation.

---

## TimerService (`ServerScriptService.TimerService`)

Server script. Manages the completion timer and fastest-times leaderboard.

### RemoteEvent: `TimerTick`

Fires to all clients every 1 second with the total seconds since server start.  
Clients use their own `JoinTime` attribute to compute their personal elapsed time.

### RemoteFunction: `GetFastestTimes`

```lua
-- Client call:
local times = game.ReplicatedStorage.GetFastestTimes:InvokeServer()
-- Returns: { { name: string, time: number }, ... }  (sorted ascending, max 5 entries)
```

### RemoteEvent: `ConfirmCompletion`

Fired by the client when it receives `CourseCompleted`. Carries `seconds: number`.  
`TimerService` records this in the fastest-times table via `recordTime(playerName, seconds)`.

---

## ObbyClient (`StarterPlayerScripts.ObbyClient`)

LocalScript. Runs on each client. Handles all visual feedback.

### Remote Events Listened To

| Event | Handler |
|---|---|
| `CheckpointReached(stageNum)` | Floating "Checkpoint! Stage N" text, green flash, HUD update |
| `PlayerDied()` | Red screen flash, HUD death count update |
| `CoinCollected(value)` | Floating "+5 coins!" text, HUD coin count update |
| `CourseCompleted(seconds, deaths, coins)` | Shows FinishScreen, fires `ConfirmCompletion` |
| `TimerTick(_)` | Updates `TimerLabel` based on `JoinTime` attribute |

### Helper Functions

#### `showFloatingText(text, color)`

Creates a `BillboardGui` above the player's `HumanoidRootPart` that floats upward and fades out over 1.5 seconds via `TweenService`.

#### `screenFlash(color, duration)`

Creates a full-screen `Frame` overlay that fades from `0.3` transparency to `1.0` transparency over `duration` seconds, then destroys itself.

---

## HUD (`StarterGui.ObbyGui.HUD`)

ModuleScript. Returns a `buildHUD(screenGui)` function that creates the HUD `Frame` and binds it to `leaderstats` value changes.

### Labels

| Name | Default Text | Data Source |
|---|---|---|
| `StageLabel` | `"Stage: 1"` | `leaderstats.Stage` |
| `DeathLabel` | `"Deaths: 0"` | `leaderstats.Deaths` |
| `CoinLabel` | `"Coins: 0"` | `leaderstats.Coins` |
| `TimerLabel` | `"Time: 0:00"` | Client `JoinTime` attribute + `TimerTick` |

All labels use `TextScaled = true` and `Enum.Font.GothamSemibold`. They are housed in semi-transparent rounded `Frame` containers (8px corner radius).

---

## FinishScreen (`StarterGui.ObbyGui.FinishScreen`)

ModuleScript. Returns a `buildFinishScreen(screenGui)` function.

### Behaviour

- Hidden (`Visible = false`) until `ObbyClient` sets it to visible.
- On show: a card Frame animates in with `EasingStyle.Back` (springy overshoot).
- Displays `TimeLabel`, `DeathsLabel`, `CoinsLabel` populated by `ObbyClient`.
- **Play Again** button: sets `Humanoid.Health = 0` to trigger a respawn, then hides the overlay.
