-- RaceManager: server authority for vehicle physics, checkpoint/lap logic,
-- race position ranking, and coin collection.

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Constants    = require(Shared:WaitForChild("Constants"))
local TrackBuilder = require(Shared:WaitForChild("StageBuilder"))

-- ── Remote events ─────────────────────────────────────────────────────────────
local function makeRemote(name)
    local e = Instance.new("RemoteEvent")
    e.Name = name; e.Parent = ReplicatedStorage; return e
end
local evCheckpoint = makeRemote(Constants.EVENTS.CHECKPOINT_PASSED)
local evLap        = makeRemote(Constants.EVENTS.LAP_COMPLETED)
local evFinished   = makeRemote(Constants.EVENTS.RACE_FINISHED)
local evPosition   = makeRemote(Constants.EVENTS.POSITION_UPDATE)
local evVehicle    = makeRemote(Constants.EVENTS.VEHICLE_ASSIGNED)
local evCoin       = makeRemote(Constants.EVENTS.COIN_COLLECTED)

-- ── Build world ───────────────────────────────────────────────────────────────
TrackBuilder.buildTrack(Workspace)
TrackBuilder.buildCheckpoints(Workspace)
TrackBuilder.placeCoins(Workspace)

-- Vehicle spawn CFrames: just before the start/finish line on the top straight,
-- facing +X (clockwise). Car on outer lane (Z≈-56), train on inner (Z≈-48).
local HL = Constants.TRACK_STRAIGHT / 2   -- 100
local HS = Constants.TRACK_SIDE     / 2   -- 40
local HW = Constants.TRACK_WIDTH    / 2   -- 12
local TOP_Z = -(HS + HW)                  -- -52

local CAR_SPAWN   = CFrame.new(-20, 2.5, TOP_Z - 4) * CFrame.Angles(0,  math.pi / 2, 0)
local TRAIN_SPAWN = CFrame.new(-20, 4,   TOP_Z + 4) * CFrame.Angles(0,  math.pi / 2, 0)

local carModel   = TrackBuilder.buildCar(CAR_SPAWN,   Workspace)
local trainModel = TrackBuilder.buildTrain(TRAIN_SPAWN, Workspace)

-- Queue: first joiner gets the car, second gets the train
local vehicleSlots = { carModel, trainModel }
local slotIndex    = 0

-- ── Per-player data ───────────────────────────────────────────────────────────
local playerData = {}

local function setupLeaderboard(player)
    local stats = Instance.new("Folder")
    stats.Name  = "leaderstats"

    local pos = Instance.new("StringValue")
    pos.Name = "Position"; pos.Value = "--"; pos.Parent = stats

    local lap = Instance.new("IntValue")
    lap.Name = "Lap"; lap.Value = 0; lap.Parent = stats

    local best = Instance.new("StringValue")
    best.Name = "BestLap"; best.Value = "--"; best.Parent = stats

    stats.Parent = player
    return stats
end

Players.PlayerAdded:Connect(function(player)
    local stats = setupLeaderboard(player)
    playerData[player] = {
        stats         = stats,
        vehicle       = nil,
        vehicleType   = nil,
        checkpointIdx = 1,      -- next required checkpoint (1–8)
        allCPsDone    = false,  -- set true when CP8 is hit; cleared on finish
        lap           = 0,      -- 0 = pre-race, 1–LAP_COUNT = racing, LAP_COUNT+1 = done
        lapStart      = nil,
        raceStart     = nil,
        bestLap       = nil,
        finished      = false,
    }

    player.CharacterAdded:Connect(function(character)
        local data = playerData[player]
        if not data then return end

        data.checkpointIdx = 1
        data.allCPsDone    = false

        task.wait(1)

        -- Assign the next available vehicle slot
        slotIndex += 1
        local model = vehicleSlots[slotIndex]
        if not model then return end

        local iscar = slotIndex == 1
        data.vehicle     = model
        data.vehicleType = iscar and "Car" or "Train"

        -- Teleport vehicle to its spawn and seat the player
        model:SetPrimaryPartCFrame(iscar and CAR_SPAWN or TRAIN_SPAWN)

        local seat = model:FindFirstChild("VehicleSeat", true)
        local hrp  = character:FindFirstChild("HumanoidRootPart")
        if seat and hrp then
            hrp.CFrame = seat.CFrame * CFrame.new(0, 4, 0)
        end

        evVehicle:FireClient(player, data.vehicleType)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player] = nil
end)

-- ── Vehicle physics (server-driven via BodyVelocity / BodyAngularVelocity) ────
RunService.Heartbeat:Connect(function()
    for _, data in pairs(playerData) do
        local model = data.vehicle
        if not model or not model.Parent then continue end

        local seat = model:FindFirstChild("VehicleSeat", true)
        local body = model.PrimaryPart
        if not body then continue end

        if not (seat and seat.Occupant) then
            -- No driver: dampen motion
            local bv = body:FindFirstChildOfClass("BodyVelocity")
            if bv then bv.Velocity = Vector3.zero end
            continue
        end

        local throttle = seat.Throttle   -- -1, 0, 1
        local steer    = seat.Steer      -- -1, 0, 1
        local iscar    = data.vehicleType == "Car"
        local maxSpd   = iscar and Constants.CAR_MAX_SPEED   or Constants.TRAIN_MAX_SPEED
        local turnSpd  = iscar and Constants.CAR_TURN_SPEED  or Constants.TRAIN_TURN_SPEED

        -- Linear
        local bv = body:FindFirstChildOfClass("BodyVelocity")
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e5, 0, 1e5)
            bv.Parent   = body
        end
        bv.Velocity = body.CFrame.LookVector * (throttle * maxSpd)

        -- Angular
        local bav = body:FindFirstChildOfClass("BodyAngularVelocity")
        if not bav then
            bav = Instance.new("BodyAngularVelocity")
            bav.MaxTorque = Vector3.new(0, 1e5, 0)
            bav.Parent    = body
        end
        bav.AngularVelocity = Vector3.new(0, -steer * turnSpd * (throttle ~= 0 and 1 or 0.4), 0)
    end
end)

-- ── Utility: find the racing player from a vehicle/character touch ────────────
local function playerFromHit(hit)
    local p = Players:GetPlayerFromCharacter(hit.Parent)
    if p then return p end
    local model = hit.Parent
    if model and model:IsA("Model") then
        local seat = model:FindFirstChild("VehicleSeat", true)
        if seat and seat.Occupant then
            return Players:GetPlayerFromCharacter(seat.Occupant.Parent)
        end
    end
    return nil
end

-- ── Checkpoints ───────────────────────────────────────────────────────────────
local function onCheckpointTouched(cp, hit)
    local idx = cp:GetAttribute("CheckpointIndex")
    if not idx then return end

    local player = playerFromHit(hit)
    if not player then return end

    local data = playerData[player]
    if not data or data.finished or data.lap == 0 then return end
    if idx ~= data.checkpointIdx then return end

    data.checkpointIdx += 1
    evCheckpoint:FireClient(player, idx, Constants.CHECKPOINT_COUNT)

    if data.checkpointIdx > Constants.CHECKPOINT_COUNT then
        data.checkpointIdx = 1
        data.allCPsDone    = true
    end
end

for _, cp in ipairs(CollectionService:GetTagged(Constants.CHECKPOINT_TAG)) do
    cp.Touched:Connect(function(hit) onCheckpointTouched(cp, hit) end)
end
CollectionService:GetInstanceAddedSignal(Constants.CHECKPOINT_TAG):Connect(function(cp)
    cp.Touched:Connect(function(hit) onCheckpointTouched(cp, hit) end)
end)

-- ── Start / finish line ───────────────────────────────────────────────────────
local function fmt(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%05.2f", m, s)
end

local function onFinishTouched(_, hit)
    local player = playerFromHit(hit)
    if not player then return end

    local data = playerData[player]
    if not data or data.finished then return end

    if data.lap == 0 then
        -- First crossing: start the race
        data.lap       = 1
        data.lapStart  = tick()
        data.raceStart = tick()
        data.stats.Lap.Value = 1
        return
    end

    if not data.allCPsDone then return end
    data.allCPsDone = false

    -- Record lap time
    local lapTime = tick() - data.lapStart
    data.lapStart = tick()
    if not data.bestLap or lapTime < data.bestLap then
        data.bestLap = lapTime
        data.stats.BestLap.Value = fmt(lapTime)
    end

    evLap:FireClient(player, data.lap, lapTime)

    if data.lap >= Constants.LAP_COUNT then
        data.finished = true
        local total   = tick() - data.raceStart
        evFinished:FireClient(player, total, data.bestLap or total)
    else
        data.lap += 1
        data.stats.Lap.Value = data.lap
    end
end

for _, f in ipairs(CollectionService:GetTagged(Constants.FINISH_TAG)) do
    f.Touched:Connect(function(hit) onFinishTouched(f, hit) end)
end
CollectionService:GetInstanceAddedSignal(Constants.FINISH_TAG):Connect(function(f)
    f.Touched:Connect(function(hit) onFinishTouched(f, hit) end)
end)

-- ── Race position ranking (every 2 s) ─────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(2)
        local racers = {}
        for pl, d in pairs(playerData) do
            if d.lap > 0 then
                local progress = (d.lap - 1) * Constants.CHECKPOINT_COUNT
                                 + (d.checkpointIdx - 1)
                table.insert(racers, { player = pl, progress = progress, data = d })
            end
        end
        table.sort(racers, function(a, b) return a.progress > b.progress end)
        local suffixes = { "st", "nd", "rd", "th" }
        for i, r in ipairs(racers) do
            local suf = suffixes[math.min(i, 4)]
            r.data.stats.Position.Value = i .. suf
            evPosition:FireClient(r.player, i, #racers)
        end
    end
end)

-- ── Coins ─────────────────────────────────────────────────────────────────────
local collectedCoins = {}

local function onCoinTouched(coin, hit)
    if collectedCoins[coin] then return end
    local player = playerFromHit(hit)
    if not player then return end

    collectedCoins[coin] = true
    coin.Transparency = 1

    evCoin:FireClient(player, Constants.COIN_VALUE)

    task.delay(15, function()
        if coin and coin.Parent then
            collectedCoins[coin] = nil
            coin.Transparency = 0
        end
    end)
end

for _, coin in ipairs(CollectionService:GetTagged(Constants.COIN_TAG)) do
    coin.Touched:Connect(function(hit) onCoinTouched(coin, hit) end)
end
CollectionService:GetInstanceAddedSignal(Constants.COIN_TAG):Connect(function(coin)
    coin.Touched:Connect(function(hit) onCoinTouched(coin, hit) end)
end)

-- ── Coin animation ────────────────────────────────────────────────────────────
local coinAnims = {}
for _, coin in ipairs(CollectionService:GetTagged(Constants.COIN_TAG)) do
    table.insert(coinAnims, { part = coin, origin = coin.Position, phase = math.random() * math.pi * 2 })
end
CollectionService:GetInstanceAddedSignal(Constants.COIN_TAG):Connect(function(coin)
    table.insert(coinAnims, { part = coin, origin = coin.Position, phase = math.random() * math.pi * 2 })
end)

RunService.Heartbeat:Connect(function()
    local t = tick()
    for _, c in ipairs(coinAnims) do
        if c.part and c.part.Parent and c.part.Transparency == 0 then
            c.part.CFrame = CFrame.new(c.origin + Vector3.new(0, math.sin(t * 2 + c.phase) * 0.4, 0))
                          * CFrame.Angles(0, t * 2 + c.phase, math.rad(90))
        end
    end
end)

print("[RaceManager] Track ready — " .. Constants.LAP_COUNT .. "-lap race. Car + Train spawned.")
