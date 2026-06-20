-- ObbyClient: handles client-side feedback for checkpoints, deaths,
-- coin collection, and course completion.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remote events to be created by the server
local evCheckpoint = ReplicatedStorage:WaitForChild(Constants.EVENTS and Constants.EVENTS.CHECKPOINT_REACHED or "CheckpointReached", 15)
local evDied       = ReplicatedStorage:WaitForChild("PlayerDied", 15)
local evCompleted  = ReplicatedStorage:WaitForChild("CourseCompleted", 15)
local evCoin       = ReplicatedStorage:WaitForChild("CoinCollected", 15)
local confirmEvent = ReplicatedStorage:WaitForChild("ConfirmCompletion", 15)
local timerEvent   = ReplicatedStorage:WaitForChild("TimerTick", 15)

-- ── HUD refs (set after GUI loads) ──────────────────────────────────────────
local hudGui, stageLabel, deathLabel, coinLabel, timerLabel

local function findHud()
    hudGui = playerGui:WaitForChild("ObbyGui", 10)
    if not hudGui then return end
    local hud = hudGui:FindFirstChild("HUD")
    if hud then
        stageLabel = hud:FindFirstChild("StageLabel")
        deathLabel = hud:FindFirstChild("DeathLabel")
        coinLabel  = hud:FindFirstChild("CoinLabel")
        timerLabel = hud:FindFirstChild("TimerLabel")
    end
end

-- Run after a short delay to let GUIs load
task.delay(1, findHud)

-- ── Floating text helper ─────────────────────────────────────────────────────
local function showFloatingText(text, color)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = false
    billboard.Adornee = hrp
    billboard.Parent = hrp

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    local tween = TweenService:Create(billboard,
        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { StudsOffset = Vector3.new(0, 7, 0) })
    tween:Play()

    task.delay(1.5, function()
        billboard:Destroy()
    end)
end

-- ── Screen flash helper ──────────────────────────────────────────────────────
local function screenFlash(color, duration)
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = color
    overlay.BackgroundTransparency = 0.3
    overlay.ZIndex = 10
    overlay.BorderSizePixel = 0

    local sg = Instance.new("ScreenGui")
    sg.Name = "FlashGui"
    sg.ResetOnSpawn = false
    sg.Parent = playerGui
    overlay.Parent = sg

    local tween = TweenService:Create(overlay,
        TweenInfo.new(duration or 0.5, Enum.EasingStyle.Linear),
        { BackgroundTransparency = 1 })
    tween:Play()
    tween.Completed:Connect(function() sg:Destroy() end)
end

-- ── Event handlers ───────────────────────────────────────────────────────────
if evCheckpoint then
    evCheckpoint.OnClientEvent:Connect(function(stageNum)
        showFloatingText("Checkpoint! Stage " .. stageNum, Color3.fromRGB(0, 220, 120))
        screenFlash(Color3.fromRGB(0, 200, 100), 0.4)
        if stageLabel then stageLabel.Text = "Stage: " .. stageNum end
    end)
end

if evDied then
    evDied.OnClientEvent:Connect(function()
        screenFlash(Color3.fromRGB(200, 0, 0), 0.6)
        local stats = player:FindFirstChild("leaderstats")
        local deaths = stats and stats:FindFirstChild("Deaths")
        if deathLabel and deaths then
            deathLabel.Text = "Deaths: " .. deaths.Value
        end
    end)
end

if evCoin then
    evCoin.OnClientEvent:Connect(function(value)
        showFloatingText("+" .. value .. " coins!", Color3.fromRGB(255, 215, 0))
        local stats = player:FindFirstChild("leaderstats")
        local coins = stats and stats:FindFirstChild("Coins")
        if coinLabel and coins then
            coinLabel.Text = "Coins: " .. coins.Value
        end
    end)
end

if evCompleted then
    evCompleted.OnClientEvent:Connect(function(seconds, deaths, coins)
        -- Echo to server for leaderboard recording
        if confirmEvent then
            confirmEvent:FireServer(seconds)
        end

        -- Show finish screen (GUI script handles the actual UI)
        local finishGui = playerGui:FindFirstChild("ObbyGui")
        if finishGui then
            local finishScreen = finishGui:FindFirstChild("FinishScreen")
            if finishScreen then
                local timeLabel  = finishScreen:FindFirstChild("TimeLabel")
                local deathsLbl  = finishScreen:FindFirstChild("DeathsLabel")
                local coinsLbl   = finishScreen:FindFirstChild("CoinsLabel")
                if timeLabel  then timeLabel.Text  = "Time: "   .. math.floor(seconds / 60) .. "m " .. (seconds % 60) .. "s" end
                if deathsLbl  then deathsLbl.Text  = "Deaths: " .. deaths end
                if coinsLbl   then coinsLbl.Text   = "Coins: "  .. coins end
                finishScreen.Visible = true
            end
        end

        showFloatingText("COURSE COMPLETE!", Color3.fromRGB(255, 215, 0))
        screenFlash(Color3.fromRGB(255, 215, 0), 1.5)
    end)
end

if timerEvent then
    timerEvent.OnClientEvent:Connect(function(_)
        -- Update local timer relative to when this player joined
        local joinTime = player:GetAttribute("JoinTime") or tick()
        local elapsed = math.floor(tick() - joinTime)
        local m = math.floor(elapsed / 60)
        local s = elapsed % 60
        if timerLabel then
            timerLabel.Text = string.format("Time: %d:%02d", m, s)
        end
    end)
end

-- Store join time as an attribute for the timer
player:SetAttribute("JoinTime", tick())
