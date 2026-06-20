-- TrackBuilder: constructs the race track, vehicles, checkpoints, and coins.
-- Required by GameManager as "StageBuilder" (filename unchanged for Rojo compat).

local Constants       = require(script.Parent.Constants)
local CollectionService = game:GetService("CollectionService")

local TrackBuilder = {}

-- ── Geometry helpers ──────────────────────────────────────────────────────────
local L  = Constants.TRACK_STRAIGHT   -- 200   (half = 100)
local S  = Constants.TRACK_SIDE       -- 80    (half = 40)
local W  = Constants.TRACK_WIDTH      -- 24    (half = 12)
local HL = L / 2   -- 100
local HS = S / 2   -- 40
local HW = W / 2   -- 12

-- Track centre lines (Y=0 is ground; parts are 1 stud thick, centred at Y=0):
--   Top straight    Z = -(HS + HW) = -52
--   Bottom straight Z =  (HS + HW) =  52
--   Left side       X = -(HL + HW) = -112
--   Right side      X =  (HL + HW) =  112
local TOP_Z  = -(HS + HW)   -- -52
local BOT_Z  =  (HS + HW)   --  52
local LEFT_X = -(HL + HW)   -- -112
local RIGHT_X =  (HL + HW)  --  112

local function makePart(name, size, cf, color, material, anchored)
    local p = Instance.new("Part")
    p.Name          = name
    p.Size          = size
    p.CFrame        = cf
    p.Color         = color or Color3.fromRGB(100, 100, 100)
    p.Material      = material or Enum.Material.SmoothPlastic
    p.Anchored      = anchored ~= false
    p.TopSurface    = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    return p
end

-- ── Track ─────────────────────────────────────────────────────────────────────
function TrackBuilder.buildTrack(parent)
    local folder = Instance.new("Folder")
    folder.Name   = "Track"
    folder.Parent = parent

    local roadCol    = Color3.fromRGB(52, 52, 58)
    local railCol    = Color3.fromRGB(150, 130, 90)
    local barrierCol = Color3.fromRGB(220, 45, 45)
    local lineCol    = Color3.fromRGB(255, 255, 255)

    local function road(name, size, cf)
        local p = makePart(name, size, cf, roadCol, Enum.Material.SmoothPlastic)
        p.Parent = folder
        return p
    end

    local function barrier(name, size, cf)
        local p = makePart(name, size, cf, barrierCol, Enum.Material.Neon)
        p.Parent = folder
        return p
    end

    local function rail(name, size, cf)
        local p = makePart(name, size, cf, railCol, Enum.Material.Metal)
        p.Parent = folder
        return p
    end

    -- ── Road sections ─────────────────────────────────────────────────────────
    road("TopStraight",    Vector3.new(L, 1, W),  CFrame.new(0,      0, TOP_Z))
    road("BotStraight",    Vector3.new(L, 1, W),  CFrame.new(0,      0, BOT_Z))
    road("LeftSide",       Vector3.new(W, 1, S),  CFrame.new(LEFT_X, 0, 0))
    road("RightSide",      Vector3.new(W, 1, S),  CFrame.new(RIGHT_X,0, 0))
    road("CornerTL",       Vector3.new(W, 1, W),  CFrame.new(LEFT_X, 0, TOP_Z))
    road("CornerTR",       Vector3.new(W, 1, W),  CFrame.new(RIGHT_X,0, TOP_Z))
    road("CornerBR",       Vector3.new(W, 1, W),  CFrame.new(RIGHT_X,0, BOT_Z))
    road("CornerBL",       Vector3.new(W, 1, W),  CFrame.new(LEFT_X, 0, BOT_Z))

    -- ── Rail line (train guide, runs along the outer edge of each section) ────
    local RH = 0.5   -- rail height above road
    local RW = 0.5   -- rail strip width
    local RY = 0.5 + RH / 2  -- rail centre Y above ground

    rail("RailTop",   Vector3.new(L + W * 2, RH, RW), CFrame.new(0,      RY, TOP_Z - HW + 3))
    rail("RailBot",   Vector3.new(L + W * 2, RH, RW), CFrame.new(0,      RY, BOT_Z + HW - 3))
    rail("RailLeft",  Vector3.new(RW, RH, S),          CFrame.new(LEFT_X  - HW + 3, RY, 0))
    rail("RailRight", Vector3.new(RW, RH, S),          CFrame.new(RIGHT_X + HW - 3, RY, 0))

    -- ── Lane divider (dashed centre line on straights) ────────────────────────
    for i = -4, 4 do
        if math.abs(i) % 2 == 0 then
            local dash = makePart("Dash", Vector3.new(12, 0.1, 1),
                CFrame.new(i * 24, 0.51, TOP_Z), lineCol, Enum.Material.Neon)
            dash.Parent = folder
            local dash2 = makePart("Dash", Vector3.new(12, 0.1, 1),
                CFrame.new(i * 24, 0.51, BOT_Z), lineCol, Enum.Material.Neon)
            dash2.Parent = folder
        end
    end

    -- ── Outer barriers ────────────────────────────────────────────────────────
    local BH = 4   -- barrier height
    local BY = BH / 2

    -- Long outer walls (extend past corners)
    barrier("OBarTop",   Vector3.new(L + W * 2 + 2, BH, 2), CFrame.new(0,       BY, TOP_Z  - HW - 1))
    barrier("OBarBot",   Vector3.new(L + W * 2 + 2, BH, 2), CFrame.new(0,       BY, BOT_Z  + HW + 1))
    barrier("OBarLeft",  Vector3.new(2, BH, S),               CFrame.new(LEFT_X  - HW - 1, BY, 0))
    barrier("OBarRight", Vector3.new(2, BH, S),               CFrame.new(RIGHT_X + HW + 1, BY, 0))

    -- ── Inner barriers ────────────────────────────────────────────────────────
    barrier("IBarTop",   Vector3.new(L - 4, BH, 2), CFrame.new(0,       BY, TOP_Z  + HW + 1))
    barrier("IBarBot",   Vector3.new(L - 4, BH, 2), CFrame.new(0,       BY, BOT_Z  - HW - 1))
    barrier("IBarLeft",  Vector3.new(2, BH, S - 4), CFrame.new(LEFT_X  + HW + 1, BY, 0))
    barrier("IBarRight", Vector3.new(2, BH, S - 4), CFrame.new(RIGHT_X - HW - 1, BY, 0))

    -- ── Start / finish line (white stripe across top straight) ────────────────
    local sf = makePart("StartFinish", Vector3.new(4, 0.2, W),
        CFrame.new(0, 0.51, TOP_Z), lineCol, Enum.Material.Neon)
    CollectionService:AddTag(sf, Constants.FINISH_TAG)
    sf.CanCollide = false
    sf.Transparency = 0.3
    sf.Parent = folder

    -- ── Start gantry ─────────────────────────────────────────────────────────
    local function post(x)
        makePart("Post", Vector3.new(1, BH + 3, 1),
            CFrame.new(x, (BH + 3) / 2, TOP_Z - HW + 1),
            Color3.fromRGB(20, 20, 20)).Parent = folder
    end
    post(-HW); post(HW)
    makePart("GantryBar", Vector3.new(W + 2, 1, 1),
        CFrame.new(0, BH + 3, TOP_Z - HW + 1),
        Color3.fromRGB(200, 40, 40), Enum.Material.Neon).Parent = folder

    return folder
end

-- ── Checkpoints ───────────────────────────────────────────────────────────────
-- 8 invisible triggers placed clockwise around the oval.
function TrackBuilder.buildCheckpoints(parent)
    local folder = Instance.new("Folder")
    folder.Name   = "Checkpoints"
    folder.Parent = parent

    local cpDefs = {
        -- { x, y_ctr, z, sx, sy, sz, index }   (Y centre at 3 to span vehicles)
        { 70,      3, TOP_Z,    4,  6, W,   1 },   -- right of start, top straight
        { RIGHT_X, 3, TOP_Z,    W,  6, W,   2 },   -- top-right corner
        { RIGHT_X, 3, 0,        W,  6, 4,   3 },   -- mid right side
        { RIGHT_X, 3, BOT_Z,    W,  6, W,   4 },   -- bottom-right corner
        { 0,       3, BOT_Z,    4,  6, W,   5 },   -- mid bottom straight
        { LEFT_X,  3, BOT_Z,    W,  6, W,   6 },   -- bottom-left corner
        { LEFT_X,  3, 0,        W,  6, 4,   7 },   -- mid left side
        { LEFT_X,  3, TOP_Z,    W,  6, W,   8 },   -- top-left corner
    }

    for _, d in ipairs(cpDefs) do
        local cp = Instance.new("Part")
        cp.Name         = "CP_" .. d[7]
        cp.Size         = Vector3.new(d[4], d[5], d[6])
        cp.CFrame       = CFrame.new(d[1], d[2], d[3])
        cp.Anchored     = true
        cp.CanCollide   = false
        cp.Transparency = 0.88
        cp.Color        = Color3.fromRGB(0, 200, 100)
        cp.Material     = Enum.Material.Neon
        cp:SetAttribute("CheckpointIndex", d[7])
        CollectionService:AddTag(cp, Constants.CHECKPOINT_TAG)
        cp.Parent = folder
    end

    return folder
end

-- ── Car ───────────────────────────────────────────────────────────────────────
function TrackBuilder.buildCar(spawnCF, parent)
    local model = Instance.new("Model")
    model.Name  = "RaceCar"

    -- Body
    local body = makePart("Body", Vector3.new(12, 2.5, 6), spawnCF,
        Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic, false)
    body.CanCollide = true
    body.Parent     = model

    -- VehicleSeat (welded on top)
    local seat = Instance.new("VehicleSeat")
    seat.Name      = "VehicleSeat"
    seat.Size      = Vector3.new(4, 1, 4)
    seat.MaxSpeed  = Constants.CAR_MAX_SPEED
    seat.TurnSpeed = Constants.CAR_TURN_SPEED
    seat.Torque    = 1500
    seat.Color     = Color3.fromRGB(25, 25, 25)
    seat.CFrame    = spawnCF * CFrame.new(0, 2, 0)
    seat.Parent    = model
    local sw = Instance.new("Weld")
    sw.Part0 = body; sw.Part1 = seat; sw.C0 = CFrame.new(0, 2, 0); sw.Parent = body

    -- Wheels (visual cylinders, welded)
    for _, off in ipairs({ Vector3.new(4,  -1,  3.5),
                           Vector3.new(4,  -1, -3.5),
                           Vector3.new(-4, -1,  3.5),
                           Vector3.new(-4, -1, -3.5) }) do
        local w = makePart("Wheel", Vector3.new(1.5, 2, 1.5),
            spawnCF * CFrame.new(off),
            Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, false)
        w.Shape  = Enum.PartType.Cylinder
        w.Parent = model
        local ww = Instance.new("Weld")
        ww.Part0 = body; ww.Part1 = w
        ww.C0 = CFrame.new(off) * CFrame.Angles(0, 0, math.pi / 2)
        ww.Parent = body
    end

    -- Windshield
    local wind = makePart("Windshield", Vector3.new(5, 1.8, 0.3),
        spawnCF * CFrame.new(2, 2, 0),
        Color3.fromRGB(130, 200, 255), Enum.Material.Glass, false)
    wind.Transparency = 0.5; wind.Parent = model
    local ww2 = Instance.new("Weld")
    ww2.Part0 = body; ww2.Part1 = wind
    ww2.C0 = CFrame.new(2, 2, 0) * CFrame.Angles(0, 0, math.rad(25)); ww2.Parent = body

    CollectionService:AddTag(body, Constants.CAR_TAG)
    model.PrimaryPart = body
    model.Parent      = parent
    return model
end

-- ── Train ─────────────────────────────────────────────────────────────────────
function TrackBuilder.buildTrain(spawnCF, parent)
    local model = Instance.new("Model")
    model.Name  = "RaceTrain"

    -- Engine
    local eng = makePart("Engine", Vector3.new(16, 5, 8), spawnCF,
        Color3.fromRGB(25, 25, 30), Enum.Material.Metal, false)
    eng.CanCollide = true; eng.Parent = model

    -- VehicleSeat
    local seat = Instance.new("VehicleSeat")
    seat.Name      = "VehicleSeat"
    seat.Size      = Vector3.new(4, 1, 5)
    seat.MaxSpeed  = Constants.TRAIN_MAX_SPEED
    seat.TurnSpeed = Constants.TRAIN_TURN_SPEED
    seat.Torque    = 1200
    seat.Color     = Color3.fromRGB(35, 35, 45)
    seat.CFrame    = spawnCF * CFrame.new(0, 3.5, 0)
    seat.Parent    = model
    local sw = Instance.new("Weld")
    sw.Part0 = eng; sw.Part1 = seat; sw.C0 = CFrame.new(0, 3.5, 0); sw.Parent = eng

    -- Weld helper
    local function weldChild(part, offset)
        local w = Instance.new("Weld")
        w.Part0 = eng; w.Part1 = part; w.C0 = CFrame.new(offset); w.Parent = eng
    end

    -- Car 1
    local c1 = makePart("Car1", Vector3.new(13, 4, 8),
        spawnCF * CFrame.new(-17, -0.5, 0),
        Color3.fromRGB(100, 50, 50), Enum.Material.Metal, false)
    c1.Parent = model; weldChild(c1, Vector3.new(-17, -0.5, 0))

    -- Car 2
    local c2 = makePart("Car2", Vector3.new(13, 4, 8),
        spawnCF * CFrame.new(-32, -0.5, 0),
        Color3.fromRGB(78, 40, 40), Enum.Material.Metal, false)
    c2.Parent = model; weldChild(c2, Vector3.new(-32, -0.5, 0))

    -- Decorative wheels on engine
    for _, zOff in ipairs({ 3.5, -3.5 }) do
        for _, xOff in ipairs({ 5, -5 }) do
            local tw = makePart("TrainWheel", Vector3.new(1.5, 2, 1.5),
                spawnCF * CFrame.new(xOff, -2, zOff),
                Color3.fromRGB(15, 15, 15), Enum.Material.Metal, false)
            tw.Shape = Enum.PartType.Cylinder; tw.Parent = model
            local ww = Instance.new("Weld")
            ww.Part0 = eng; ww.Part1 = tw
            ww.C0 = CFrame.new(xOff, -2, zOff) * CFrame.Angles(0, 0, math.pi / 2)
            ww.Parent = eng
        end
    end

    -- Chimney
    local chi = makePart("Chimney", Vector3.new(1.5, 3, 1.5),
        spawnCF * CFrame.new(7, 3.5, 0),
        Color3.fromRGB(14, 14, 18), Enum.Material.Metal, false)
    chi.Parent = model; weldChild(chi, Vector3.new(7, 3.5, 0))

    CollectionService:AddTag(eng, Constants.TRAIN_TAG)
    model.PrimaryPart = eng
    model.Parent      = parent
    return model
end

-- ── Coins (scattered around the track) ───────────────────────────────────────
function TrackBuilder.placeCoins(parent)
    local folder = Instance.new("Folder")
    folder.Name   = "Coins"
    folder.Parent = parent

    local positions = {
        Vector3.new(-60, 2, TOP_Z),  Vector3.new(0,   2, TOP_Z),  Vector3.new(60,  2, TOP_Z),
        Vector3.new(-60, 2, BOT_Z),  Vector3.new(0,   2, BOT_Z),  Vector3.new(60,  2, BOT_Z),
        Vector3.new(LEFT_X,  2,  25), Vector3.new(LEFT_X,  2, -25),
        Vector3.new(RIGHT_X, 2,  25), Vector3.new(RIGHT_X, 2, -25),
    }

    for _, pos in ipairs(positions) do
        local coin = makePart("Coin", Vector3.new(2, 0.4, 2), CFrame.new(pos),
            Color3.fromRGB(255, 200, 0), Enum.Material.Neon)
        coin.Shape     = Enum.PartType.Cylinder
        coin.CanCollide = false
        CollectionService:AddTag(coin, Constants.COIN_TAG)
        coin.Parent = folder
    end

    return folder
end

return TrackBuilder
