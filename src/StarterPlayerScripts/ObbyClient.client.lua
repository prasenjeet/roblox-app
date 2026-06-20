-- RaceClient: handles all client-side race feedback —
-- builds the HUD, listens for server events, runs the live timer.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Wait for GUI and build HUD + FinishScreen ─────────────────────────────────
local obbyGui      = playerGui:WaitForChild("ObbyGui", 15)
local buildHUD     = require(obbyGui:WaitForChild("HUD"))
local buildFinish  = require(obbyGui:WaitForChild("FinishScreen"))

local hud    = buildHUD(obbyGui)
local finish = buildFinish(obbyGui)

-- ── Wait for remote events ────────────────────────────────────────────────────
local function waitEv(name) return ReplicatedStorage:WaitForChild(name, 15) end
local evCheckpoint = waitEv("CheckpointPassed")
local evLap        = waitEv("LapCompleted")
local evFinished   = waitEv("RaceFinished")
local evPosition   = waitEv("PositionUpdate")
local evVehicle    = waitEv("VehicleAssigned")
local evCoin       = waitEv("CoinCollected")

-- ── Live race state ───────────────────────────────────────────────────────────
local raceStartTime  = nil
local currentLap     = 0
local currentCP      = 0
local totalCP        = 8
local coins          = 0
local raceActive     = false
local lapCount       = 3

-- ── Notification helper ───────────────────────────────────────────────────────
local function showNotif(text, color, duration)
    local n = hud.notifLabel
    n.Text      = text
    n.TextColor3 = color or Color3.fromRGB(255, 220, 0)
    n.Visible   = true
    task.delay(duration or 2.5, function()
        TweenService:Create(n, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
        task.delay(0.4, function()
            n.Visible         = false
            n.TextTransparency = 0
        end)
    end)
end

-- ── Screen flash ──────────────────────────────────────────────────────────────
local function screenFlash(color, duration)
    local sg = Instance.new("ScreenGui")
    sg.Name = "Flash"; sg.ResetOnSpawn = false; sg.Parent = playerGui
    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1, 1)
    f.BackgroundColor3 = color
    f.BackgroundTransparency = 0.25
    f.BorderSizePixel = 0; f.Parent = sg
    TweenService:Create(f, TweenInfo.new(duration or 0.5),
        { BackgroundTransparency = 1 }):Play()
    task.delay(duration or 0.5, function() sg:Destroy() end)
end

-- ── Event handlers ────────────────────────────────────────────────────────────
if evVehicle then
    evVehicle.OnClientEvent:Connect(function(vehicleType)
        hud.vehicleLabel.Text = "Vehicle: " .. vehicleType
        showNotif("You are driving the " .. vehicleType .. "!", Color3.fromRGB(100, 200, 255), 3)
        -- Race starts when player crosses start line; begin timer on first lap event
    end)
end

if evCheckpoint then
    evCheckpoint.OnClientEvent:Connect(function(idx, total)
        currentCP = idx
        hud.cpLabel.Text = "CP " .. idx .. " / " .. (total or totalCP)
        screenFlash(Color3.fromRGB(0, 200, 100), 0.3)
    end)
end

if evLap then
    evLap.OnClientEvent:Connect(function(lapNum, lapTime)
        currentLap = lapNum
        local fmt = string.format("%d:%05.2f", math.floor(lapTime / 60), lapTime % 60)
        hud.bestLabel.Text = "Best: " .. fmt
        hud.lapLabel.Text  = "Lap " .. lapNum .. " / " .. lapCount

        if lapNum < lapCount then
            showNotif("Lap " .. lapNum .. " done! — " .. fmt, Color3.fromRGB(255, 210, 0), 3)
            screenFlash(Color3.fromRGB(255, 215, 0), 0.5)
        end
    end)
end

if evFinished then
    evFinished.OnClientEvent:Connect(function(totalTime, bestLap)
        raceActive = false
        screenFlash(Color3.fromRGB(255, 215, 0), 1.5)

        task.delay(1, function()
            -- Find race position from leaderboard
            local stats    = player:FindFirstChild("leaderstats")
            local posStr   = stats and stats:FindFirstChild("Position")
            local posNum   = 1
            if posStr then
                posNum = tonumber(posStr.Value:match("%d+")) or 1
            end
            finish.show(posNum, totalTime, bestLap, coins)
        end)
    end)
end

if evPosition then
    evPosition.OnClientEvent:Connect(function(pos, total)
        local suffixes = { "st", "nd", "rd", "th" }
        local suf = suffixes[math.min(pos, 4)]
        hud.posLabel.Text = pos .. suf
    end)
end

if evCoin then
    evCoin.OnClientEvent:Connect(function(value)
        coins += value
        showNotif("+" .. value .. " coins!", Color3.fromRGB(255, 215, 0), 1.5)
    end)
end

-- ── Live timer (counts up from race start) ────────────────────────────────────
-- We approximate start time locally: first time we see lap=1 from the server
-- the timer kicks off. We track it client-side to keep it smooth.
local localRaceStart = nil

-- When vehicle is assigned, show 0:00.00 and prepare timer
if evVehicle then
    evVehicle.OnClientEvent:Connect(function()
        hud.lapLabel.Text  = "Lap 0 / " .. lapCount
        hud.timerLabel.Text = "0:00.00"
    end)
end

-- Detect first lap event to start the timer
if evLap then
    evLap.OnClientEvent:Connect(function(lapNum)
        if lapNum == 1 and not localRaceStart then
            localRaceStart = tick()
            raceActive = true
        end
    end)
end

RunService.Heartbeat:Connect(function()
    -- Timer
    if localRaceStart and raceActive then
        local elapsed = tick() - localRaceStart
        local m = math.floor(elapsed / 60)
        local s = elapsed % 60
        hud.timerLabel.Text = string.format("%d:%05.2f", m, s)
    end

    -- Lap label stays in sync
    if currentLap > 0 then
        hud.lapLabel.Text = "Lap " .. currentLap .. " / " .. lapCount
    end
end)
