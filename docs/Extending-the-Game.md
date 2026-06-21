# Extending the Game

This page explains how to add new content without touching existing game logic.

---

## Adding a New Stage

All stage geometry is defined in the `getStageConfigs()` table inside `StageBuilder.lua`. To add a Stage 11:

### 1. Increase the stage count

`src/ReplicatedStorage/Shared/Constants.lua`:
```lua
Constants.STAGE_COUNT = 11   -- was 10
```

### 2. Add a config entry

`src/ReplicatedStorage/Shared/StageBuilder.lua` — append to the table returned by `getStageConfigs()`:

```lua
-- Stage 11 – example: rotating platform ring
{
    platforms = {
        { size = V3(6,1,6),  offset = V3(0,0,0)  },
        { size = V3(4,1,4),  offset = V3(14,0,8),  moving = true },
        { size = V3(4,1,4),  offset = V3(28,0,-8), moving = true },
        { size = V3(6,1,6),  offset = V3(42,0,0)  },
        { size = V3(6,1,6),  offset = V3(56,0,0)  },
    },
    kills = {
        { size = V3(2,3,14), offset = V3(21,3,0), spin = true },
    },
    killY = -25,
},
```

That's it — `GameManager` will automatically build the stage and place coins there on the next server start.

### Platform config fields

| Field | Type | Required | Description |
|---|---|---|---|
| `size` | `Vector3` | Yes | Size of the platform Part |
| `offset` | `Vector3` | Yes | Offset from the stage origin (X = 0 is the spawn pad) |
| `moving` | `bool` | No | Enables sine-wave side-to-side motion on Z axis |

### Kill-brick config fields

| Field | Type | Required | Description |
|---|---|---|---|
| `size` | `Vector3` | Yes | Size of the kill brick Part |
| `offset` | `Vector3` | Yes | Offset from stage origin |
| `spin` | `bool` | No | Enables `SpinSpeed` rotation around Y axis |

---

## Changing Moving Platform Behaviour

Moving platform speed and range are stored as Part attributes set by `StageBuilder`:

| Attribute | Default | Description |
|---|---|---|
| `Moving` | `true` | Marks the part for the Heartbeat loop |
| `MoveRange` | `8` | Amplitude in studs (half the total travel) |
| `MoveSpeed` | `1.5 + stage × 0.15` | Sine frequency (cycles per second) |

To override per-platform in the config:
```lua
{ size = V3(4,1,4), offset = V3(14,0,0), moving = true, range = 12, speed = 3 }
```

Then in `StageBuilder.buildStage`, read the extra fields:
```lua
part:SetAttribute("MoveRange", pCfg.range or 8)
part:SetAttribute("MoveSpeed", pCfg.speed or (1.5 + stageNumber * 0.15))
```

---

## Changing Spinner Speed

Spinner speed is a Part attribute:
```lua
kill:SetAttribute("SpinSpeed", 45 + stageNumber * 5)   -- degrees/second
```

Override it in the kill config:
```lua
{ size = V3(2,2,12), offset = V3(10,2,0), spin = true, spinSpeed = 120 }
```

And update `StageBuilder`:
```lua
kill:SetAttribute("SpinSpeed", kCfg.spinSpeed or (45 + stageNumber * 5))
```

---

## Adding More Coins

`GameManager` currently places coins with:
```lua
for i = 1, Constants.STAGE_COUNT do
    local baseX = (i - 1) * STAGE_SPACING
    for _ = 1, 3 do   -- 3 coins per stage
        local x = baseX + math.random(5, Constants.STAGE_LENGTH - 5)
        local z = math.random(-6, 6)
        StageBuilder.placeCoin(Vector3.new(x, Constants.PLATFORM_Y + 3, z), coinsFolder)
    end
end
```

To add more coins per stage, increase the inner loop count. To add coins at fixed positions:
```lua
StageBuilder.placeCoin(Vector3.new(specificX, specificY, specificZ), coinsFolder)
```

To change coin value, edit `Constants.COIN_VALUE`.

---

## Adding a New Obstacle Type

### Example: Bouncing Platform

1. **Mark the part** in the config:
   ```lua
   { size = V3(6,1,6), offset = V3(14,0,0), bounce = true }
   ```

2. **Set an attribute** in `StageBuilder.buildStage`:
   ```lua
   if pCfg.bounce then
       part:SetAttribute("Bounce", true)
       part:SetAttribute("BounceForce", 80)
   end
   ```

3. **Handle it in `GameManager`** — in the `CharacterAdded` block or a new `Touched` listener:
   ```lua
   local function setupBounce()
       for _, part in ipairs(Workspace:GetDescendants()) do
           if part:IsA("BasePart") and part:GetAttribute("Bounce") then
               local force = part:GetAttribute("BounceForce") or 80
               part.Touched:Connect(function(hit)
                   local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
                   local hrp = hit.Parent:FindFirstChild("HumanoidRootPart")
                   if hum and hrp then
                       hrp.AssemblyLinearVelocity += Vector3.new(0, force, 0)
                   end
               end)
           end
       end
   end
   setupBounce()
   ```

---

## Adding a New HUD Element

`HUD.lua` exposes a `makeLabel(name, text, position, parent)` helper. To add a "Time Bonus" label:

```lua
makeLabel("BonusLabel", "Bonus: 0", UDim2.new(0, 0, 0, 176), hud)
```

Then bind it in `syncStats`:
```lua
-- BonusLabel doesn't come from leaderstats; update it via RemoteEvent instead
```

---

## Adding a New RemoteEvent

1. **Define the name** in `Constants.EVENTS`:
   ```lua
   Constants.EVENTS.BONUS_EARNED = "BonusEarned"
   ```

2. **Create it in `GameManager`**:
   ```lua
   local evBonus = makeRemote(Constants.EVENTS.BONUS_EARNED)
   ```

3. **Fire from server**:
   ```lua
   evBonus:FireClient(player, bonusAmount)
   ```

4. **Listen on client** in `ObbyClient.client.lua`:
   ```lua
   local evBonus = ReplicatedStorage:WaitForChild("BonusEarned", 15)
   evBonus.OnClientEvent:Connect(function(amount)
       showFloatingText("+" .. amount .. " bonus!", Color3.fromRGB(0, 200, 255))
   end)
   ```

---

## Adjusting Game Constants

All tunable values live in `Constants.lua`. Common tweaks:

```lua
Constants.STAGE_COUNT   = 15    -- extend the course
Constants.COIN_VALUE    = 10    -- double coin rewards
Constants.RESPAWN_DELAY = 1.0   -- faster respawn
```

Changes take effect on the next server start (no other files need editing).
