-- Procedurally generates obby stages in the Workspace at runtime.
-- Each stage is a folder containing platforms, kill bricks, a checkpoint,
-- and optional coins. The difficulty scales with the stage number.

local Constants = require(script.Parent.Constants)
local CollectionService = game:GetService("CollectionService")

local StageBuilder = {}

local function makePart(name, size, position, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.Color = color or Color3.fromRGB(163, 162, 165)
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    return part
end

-- Returns a table of stage configs. Each entry drives buildStage().
local function getStageConfigs()
    return {
        -- Stage 1 – simple stepping stones
        { platforms = { {size=V3(8,1,8), offset=V3(0,0,0)}, {size=V3(8,1,8), offset=V3(12,0,0)}, {size=V3(8,1,8), offset=V3(24,0,0)}, {size=V3(8,1,8), offset=V3(36,0,0)} }, killY = -20 },
        -- Stage 2 – narrow planks
        { platforms = { {size=V3(4,1,4), offset=V3(0,0,0)}, {size=V3(4,1,4), offset=V3(10,0,0)}, {size=V3(4,1,4), offset=V3(20,0,2)}, {size=V3(4,1,4), offset=V3(30,0,-2)}, {size=V3(4,1,4), offset=V3(40,0,0)} }, killY = -20 },
        -- Stage 3 – staircase
        { platforms = { {size=V3(8,1,8), offset=V3(0,0,0)}, {size=V3(8,1,8), offset=V3(10,4,0)}, {size=V3(8,1,8), offset=V3(20,8,0)}, {size=V3(8,1,8), offset=V3(30,12,0)}, {size=V3(8,1,8), offset=V3(40,16,0)} }, killY = -20 },
        -- Stage 4 – moving platforms (marked with attribute)
        { platforms = { {size=V3(6,1,6), offset=V3(0,0,0)}, {size=V3(6,1,6), offset=V3(14,0,0), moving=true}, {size=V3(6,1,6), offset=V3(28,0,0), moving=true}, {size=V3(6,1,6), offset=V3(42,0,0)} }, killY = -25 },
        -- Stage 5 – kill bricks on the sides
        { platforms = { {size=V3(20,1,6), offset=V3(0,0,0)}, {size=V3(20,1,6), offset=V3(24,0,0)}, {size=V3(20,1,6), offset=V3(48,0,0)} }, kills = { {size=V3(4,1,4), offset=V3(10,0,3)}, {size=V3(4,1,4), offset=V3(10,0,-3)}, {size=V3(4,1,4), offset=V3(34,0,3)}, {size=V3(4,1,4), offset=V3(34,0,-3)} }, killY = -20 },
        -- Stage 6 – zigzag
        { platforms = { {size=V3(6,1,6), offset=V3(0,0,0)}, {size=V3(6,1,6), offset=V3(10,0,8)}, {size=V3(6,1,6), offset=V3(20,0,0)}, {size=V3(6,1,6), offset=V3(30,0,-8)}, {size=V3(6,1,6), offset=V3(40,0,0)}, {size=V3(6,1,6), offset=V3(50,0,8)} }, killY = -20 },
        -- Stage 7 – lava floor (kill brick floor, narrow path)
        { platforms = { {size=V3(4,1,4), offset=V3(0,0,0)}, {size=V3(4,1,4), offset=V3(8,0,0)}, {size=V3(4,1,4), offset=V3(16,0,0)}, {size=V3(4,1,4), offset=V3(24,0,0)}, {size=V3(4,1,4), offset=V3(32,0,0)}, {size=V3(4,1,4), offset=V3(40,0,0)}, {size=V3(4,1,4), offset=V3(48,0,0)} }, kills = { {size=V3(60,1,30), offset=V3(24,-2,0)} }, killY = -30 },
        -- Stage 8 – bouncy pads (SpringConstraint) placeholders
        { platforms = { {size=V3(8,1,8), offset=V3(0,0,0)}, {size=V3(4,1,4), offset=V3(14,10,0)}, {size=V3(4,1,4), offset=V3(28,20,0)}, {size=V3(8,1,8), offset=V3(42,30,0)} }, killY = -20 },
        -- Stage 9 – spinner kill bricks (rotating handled server-side)
        { platforms = { {size=V3(10,1,10), offset=V3(0,0,0)}, {size=V3(10,1,10), offset=V3(20,0,0)}, {size=V3(10,1,10), offset=V3(40,0,0)}, {size=V3(10,1,10), offset=V3(60,0,0)} }, kills = { {size=V3(2,2,12), offset=V3(10,2,0), spin=true}, {size=V3(2,2,12), offset=V3(30,2,0), spin=true} }, killY = -25 },
        -- Stage 10 – final gauntlet (narrow + moving + kills)
        { platforms = { {size=V3(4,1,4), offset=V3(0,0,0)}, {size=V3(4,1,4), offset=V3(10,0,0), moving=true}, {size=V3(4,1,4), offset=V3(20,4,0)}, {size=V3(4,1,4), offset=V3(30,8,0), moving=true}, {size=V3(4,1,4), offset=V3(40,12,0)}, {size=V3(4,1,4), offset=V3(50,16,0), moving=true}, {size=V3(6,1,6), offset=V3(62,20,0)} }, kills = { {size=V3(2,2,10), offset=V3(15,6,0), spin=true}, {size=V3(2,2,10), offset=V3(35,10,0), spin=true} }, killY = -30 },
    }
end

-- Vector3 shorthand used only inside this module
function V3(x, y, z) return Vector3.new(x, y, z) end

-- Builds one stage folder in the given parent at the given world X origin.
function StageBuilder.buildStage(stageNumber, originX, parent)
    local config = getStageConfigs()[stageNumber]
    if not config then return end

    local folder = Instance.new("Folder")
    folder.Name = "Stage_" .. stageNumber
    folder.Parent = parent

    local originY = Constants.PLATFORM_Y
    local originPos = Vector3.new(originX, originY, 0)

    -- Spawn platform at the very start of this stage
    local spawn = makePart("SpawnPlatform", Vector3.new(12, 1, 12), originPos, Color3.fromRGB(80, 180, 80))
    spawn.Parent = folder

    -- Checkpoint flag at the start
    local checkpoint = makePart("Checkpoint", Vector3.new(2, 6, 2),
        originPos + Vector3.new(0, 3.5, 0), Constants.CHECKPOINT_COLOR)
    checkpoint:SetAttribute("StageNumber", stageNumber)
    CollectionService:AddTag(checkpoint, Constants.CHECKPOINT_TAG)
    checkpoint.Parent = folder

    -- Obstacle platforms
    for _, pCfg in ipairs(config.platforms) do
        local part = makePart("Platform", pCfg.size,
            originPos + pCfg.offset + Vector3.new(16, pCfg.size.Y / 2, 0),
            Color3.fromRGB(100, 149, 237))
        if pCfg.moving then
            part:SetAttribute("Moving", true)
            part:SetAttribute("MoveRange", 8)
            part:SetAttribute("MoveSpeed", 1.5 + stageNumber * 0.15)
            part:SetAttribute("MoveOrigin", (originPos + pCfg.offset + Vector3.new(16, pCfg.size.Y / 2, 0)):toXml and tostring(originPos + pCfg.offset) or "")
        end
        part.Parent = folder
    end

    -- Kill bricks
    if config.kills then
        for _, kCfg in ipairs(config.kills) do
            local kill = makePart("KillBrick", kCfg.size,
                originPos + kCfg.offset + Vector3.new(16, kCfg.size.Y / 2, 0),
                Color3.fromRGB(200, 50, 50), Enum.Material.Neon)
            CollectionService:AddTag(kill, Constants.KILL_TAG)
            if kCfg.spin then
                kill:SetAttribute("Spinning", true)
                kill:SetAttribute("SpinSpeed", 45 + stageNumber * 5)
            end
            kill.Parent = folder
        end
    end

    -- Kill floor (invisible)
    local killFloor = makePart("KillFloor", Vector3.new(200, 1, 200),
        Vector3.new(originX + 40, config.killY, 0),
        Color3.fromRGB(255, 0, 0))
    killFloor.Transparency = 0.9
    killFloor.CanCollide = true
    CollectionService:AddTag(killFloor, Constants.KILL_TAG)
    killFloor.Parent = folder

    return folder
end

-- Builds the finish platform at the end of the course.
function StageBuilder.buildFinish(originX, parent)
    local folder = Instance.new("Folder")
    folder.Name = "Finish"
    folder.Parent = parent

    local finishPos = Vector3.new(originX, Constants.PLATFORM_Y, 0)
    local platform = makePart("FinishPlatform", Vector3.new(20, 1, 20), finishPos,
        Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
    platform.Parent = folder

    local trigger = makePart("FinishTrigger", Vector3.new(20, 10, 20),
        finishPos + Vector3.new(0, 5, 0), Color3.fromRGB(255, 215, 0))
    trigger.Transparency = 0.8
    trigger.CanCollide = false
    CollectionService:AddTag(trigger, Constants.FINISH_TAG)
    trigger.Parent = folder

    -- Trophy decoration
    local trophy = makePart("Trophy", Vector3.new(4, 8, 4),
        finishPos + Vector3.new(0, 5, 0), Color3.fromRGB(255, 200, 0), Enum.Material.Neon)
    trophy.Shape = Enum.PartType.Cylinder
    trophy.Parent = folder

    return folder
end

-- Places a coin at `position` inside `parent`.
function StageBuilder.placeCoin(position, parent)
    local coin = makePart("Coin", Vector3.new(2, 0.4, 2), position,
        Color3.fromRGB(255, 200, 0), Enum.Material.Neon)
    coin.Shape = Enum.PartType.Cylinder
    coin.CanCollide = false
    CollectionService:AddTag(coin, Constants.COIN_TAG)
    coin.Parent = parent
    return coin
end

return StageBuilder
