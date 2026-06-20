-- GameManager: server authority for checkpoints, leaderboard, kill bricks,
-- moving platforms, and spinning obstacles.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local StageBuilder = require(Shared:WaitForChild("StageBuilder"))

-- ── Remote events ────────────────────────────────────────────────────────────
local function makeRemote(name)
    local e = Instance.new("RemoteEvent")
    e.Name = name
    e.Parent = ReplicatedStorage
    return e
end

local evCheckpoint = makeRemote(Constants.EVENTS.CHECKPOINT_REACHED)
local evDied       = makeRemote(Constants.EVENTS.PLAYER_DIED)
local evCompleted  = makeRemote(Constants.EVENTS.COURSE_COMPLETED)
local evCoin       = makeRemote(Constants.EVENTS.COIN_COLLECTED)

-- ── Build the course ─────────────────────────────────────────────────────────
local courseFolder = Instance.new("Folder")
courseFolder.Name = "Obbycourse"
courseFolder.Parent = Workspace

local STAGE_SPACING = Constants.STAGE_LENGTH + 20
for i = 1, Constants.STAGE_COUNT do
    StageBuilder.buildStage(i, (i - 1) * STAGE_SPACING, courseFolder)
end
StageBuilder.buildFinish(Constants.STAGE_COUNT * STAGE_SPACING, courseFolder)

-- Scatter coins
local coinsFolder = Instance.new("Folder")
coinsFolder.Name = "Coins"
coinsFolder.Parent = Workspace

math.randomseed(12345)
for i = 1, Constants.STAGE_COUNT do
    local baseX = (i - 1) * STAGE_SPACING
    for _ = 1, 3 do
        local x = baseX + math.random(5, Constants.STAGE_LENGTH - 5)
        local z = math.random(-6, 6)
        StageBuilder.placeCoin(Vector3.new(x, Constants.PLATFORM_Y + 3, z), coinsFolder)
    end
end

-- ── Per-player state ─────────────────────────────────────────────────────────
local playerData = {}   -- [player] = { stage, deaths, coins, startTime, completed }

local function getSpawnForStage(stage)
    local stageFolder = courseFolder:FindFirstChild("Stage_" .. stage)
    if stageFolder then
        local spawn = stageFolder:FindFirstChild("SpawnPlatform")
        if spawn then
            return spawn.Position + Vector3.new(0, 3, 0)
        end
    end
    return Vector3.new(0, 5, 0)
end

local function setupLeaderboard(player)
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"

    local stage = Instance.new("IntValue")
    stage.Name = "Stage"
    stage.Value = 1
    stage.Parent = stats

    local deaths = Instance.new("IntValue")
    deaths.Name = "Deaths"
    deaths.Value = 0
    deaths.Parent = stats

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = stats

    stats.Parent = player
    return stats
end

local function respawnAt(player, position)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(position)
    end
end

-- ── Player lifecycle ─────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    local stats = setupLeaderboard(player)
    playerData[player] = {
        stage = 1,
        deaths = 0,
        coins = 0,
        startTime = tick(),
        completed = false,
    }

    player.CharacterAdded:Connect(function(character)
        local data = playerData[player]
        if not data then return end

        -- Teleport to last checkpoint after a brief spawn delay
        task.wait(0.1)
        respawnAt(player, getSpawnForStage(data.stage))

        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            data.deaths += 1
            stats.Deaths.Value = data.deaths
            evDied:FireClient(player)
        end)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player] = nil
end)

-- ── Checkpoint touch detection ───────────────────────────────────────────────
local function onCheckpointTouched(checkpoint, otherPart)
    local stageNum = checkpoint:GetAttribute("StageNumber")
    if not stageNum then return end

    local player = Players:GetPlayerFromCharacter(otherPart.Parent)
    if not player then return end

    local data = playerData[player]
    if not data then return end

    if stageNum > data.stage then
        data.stage = stageNum
        local stats = player:FindFirstChild("leaderstats")
        if stats then
            stats.Stage.Value = stageNum
        end
        checkpoint.Color = Constants.CHECKPOINT_TOUCHED_COLOR
        evCheckpoint:FireClient(player, stageNum)
    end
end

for _, checkpoint in ipairs(CollectionService:GetTagged(Constants.CHECKPOINT_TAG)) do
    checkpoint.Touched:Connect(function(hit) onCheckpointTouched(checkpoint, hit) end)
end

CollectionService:GetInstanceAddedSignal(Constants.CHECKPOINT_TAG):Connect(function(checkpoint)
    checkpoint.Touched:Connect(function(hit) onCheckpointTouched(checkpoint, hit) end)
end)

-- ── Kill brick touch detection ───────────────────────────────────────────────
local function onKillBrickTouched(_, otherPart)
    local character = otherPart.Parent
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        humanoid.Health = 0
    end
end

for _, brick in ipairs(CollectionService:GetTagged(Constants.KILL_TAG)) do
    brick.Touched:Connect(function(hit) onKillBrickTouched(brick, hit) end)
end

CollectionService:GetInstanceAddedSignal(Constants.KILL_TAG):Connect(function(brick)
    brick.Touched:Connect(function(hit) onKillBrickTouched(brick, hit) end)
end)

-- ── Coin collection ──────────────────────────────────────────────────────────
local collectedCoins = {}   -- [coin] = true once collected

local function onCoinTouched(coin, otherPart)
    if collectedCoins[coin] then return end

    local player = Players:GetPlayerFromCharacter(otherPart.Parent)
    if not player then return end

    collectedCoins[coin] = true
    coin.Transparency = 1
    coin.CanCollide = false

    local data = playerData[player]
    if data then
        data.coins += Constants.COIN_VALUE
        local stats = player:FindFirstChild("leaderstats")
        if stats then
            stats.Coins.Value = data.coins
        end
        evCoin:FireClient(player, Constants.COIN_VALUE)
    end

    -- Respawn coin after 30 seconds
    task.delay(30, function()
        if coin and coin.Parent then
            collectedCoins[coin] = nil
            coin.Transparency = 0
            coin.CanCollide = false
        end
    end)
end

for _, coin in ipairs(CollectionService:GetTagged(Constants.COIN_TAG)) do
    coin.Touched:Connect(function(hit) onCoinTouched(coin, hit) end)
end

CollectionService:GetInstanceAddedSignal(Constants.COIN_TAG):Connect(function(coin)
    coin.Touched:Connect(function(hit) onCoinTouched(coin, hit) end)
end)

-- ── Finish line ──────────────────────────────────────────────────────────────
local function onFinishTouched(_, otherPart)
    local player = Players:GetPlayerFromCharacter(otherPart.Parent)
    if not player then return end

    local data = playerData[player]
    if not data or data.completed then return end

    data.completed = true
    local elapsed = math.floor(tick() - data.startTime)
    evCompleted:FireClient(player, elapsed, data.deaths, data.coins)
end

for _, finish in ipairs(CollectionService:GetTagged(Constants.FINISH_TAG)) do
    finish.Touched:Connect(function(hit) onFinishTouched(finish, hit) end)
end

CollectionService:GetInstanceAddedSignal(Constants.FINISH_TAG):Connect(function(finish)
    finish.Touched:Connect(function(hit) onFinishTouched(finish, hit) end)
end)

-- ── Moving platform & spinning obstacle loop ─────────────────────────────────
local movingParts = {}
local spinningParts = {}

local function indexDynamicParts()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            if part:GetAttribute("Moving") then
                local range = part:GetAttribute("MoveRange") or 8
                local speed = part:GetAttribute("MoveSpeed") or 2
                table.insert(movingParts, {
                    part = part,
                    origin = part.Position,
                    range = range,
                    speed = speed,
                    phase = math.random() * math.pi * 2,
                })
            end
            if part:GetAttribute("Spinning") then
                local spinSpeed = part:GetAttribute("SpinSpeed") or 60
                table.insert(spinningParts, {
                    part = part,
                    speed = spinSpeed,
                })
            end
        end
    end
end

indexDynamicParts()

RunService.Heartbeat:Connect(function(dt)
    local t = tick()
    for _, m in ipairs(movingParts) do
        if m.part and m.part.Parent then
            local offset = math.sin(t * m.speed + m.phase) * m.range
            m.part.Position = m.origin + Vector3.new(0, 0, offset)
        end
    end

    for _, s in ipairs(spinningParts) do
        if s.part and s.part.Parent then
            s.part.CFrame = s.part.CFrame * CFrame.Angles(0, math.rad(s.speed * dt), 0)
        end
    end
end)

print("[GameManager] Obby course ready with " .. Constants.STAGE_COUNT .. " stages.")
