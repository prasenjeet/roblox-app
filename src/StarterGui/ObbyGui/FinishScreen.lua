-- RaceFinish: overlay shown when the player completes all laps.

local TweenService = game:GetService("TweenService")

local function buildFinishScreen(screenGui)
    local overlay = Instance.new("Frame")
    overlay.Name                   = "FinishScreen"
    overlay.Size                   = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.Visible                = false
    overlay.ZIndex                 = 10
    overlay.Parent                 = screenGui

    local card = Instance.new("Frame")
    card.Name               = "Card"
    card.Size               = UDim2.new(0, 440, 0, 340)
    card.Position           = UDim2.new(0.5, -220, 0.5, -170)
    card.BackgroundColor3   = Color3.fromRGB(14, 16, 34)
    card.BorderSizePixel    = 0
    card.ZIndex             = 11
    card.Parent             = overlay
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 18); cc.Parent = card
    local cs = Instance.new("UIStroke"); cs.Color = Color3.fromRGB(255, 200, 0); cs.Thickness = 3; cs.Parent = card

    local function lbl(text, y, size, color)
        local l = Instance.new("TextLabel")
        l.Size                  = UDim2.new(1, -30, 0, size + 6)
        l.Position              = UDim2.new(0, 15, 0, y)
        l.BackgroundTransparency = 1
        l.Text                  = text
        l.TextColor3            = color or Color3.fromRGB(220, 220, 220)
        l.Font                  = Enum.Font.GothamSemibold
        l.TextSize              = size
        l.ZIndex                = 12
        l.Parent                = card
        return l
    end

    local titleLbl  = lbl("RACE COMPLETE!", 18,  32, Color3.fromRGB(255, 210, 0))
    local posLbl    = lbl("",              68,  24, Color3.fromRGB(255, 255, 255))
    local totalLbl  = lbl("Total: --",    108,  20)
    local bestLbl   = lbl("Best Lap: --", 140,  20)
    local coinLbl   = lbl("Coins: 0",     172,  20)

    -- Divider
    local div = Instance.new("Frame")
    div.Size             = UDim2.new(1, -30, 0, 2)
    div.Position         = UDim2.new(0, 15, 0, 205)
    div.BackgroundColor3 = Color3.fromRGB(40, 48, 75)
    div.BorderSizePixel  = 0; div.ZIndex = 12; div.Parent = card

    -- Race Again button
    local btn = Instance.new("TextButton")
    btn.Name             = "RaceAgainButton"
    btn.Size             = UDim2.new(0, 200, 0, 52)
    btn.Position         = UDim2.new(0.5, -100, 0, 220)
    btn.BackgroundColor3 = Color3.fromRGB(38, 188, 72)
    btn.BorderSizePixel  = 0
    btn.Text             = "Race Again"
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.TextScaled       = true
    btn.Font             = Enum.Font.GothamBold
    btn.ZIndex           = 12
    btn.Parent           = card
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 12); bc.Parent = btn

    btn.MouseButton1Click:Connect(function()
        overlay.Visible = false
        -- Respawn player to restart
        local Players = game:GetService("Players")
        local char    = Players.LocalPlayer.Character
        local hum     = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end)

    -- Animate in when made visible
    overlay:GetPropertyChangedSignal("Visible"):Connect(function()
        if overlay.Visible then
            card.Position = UDim2.new(0.5, -220, 0.58, -170)
            card.BackgroundTransparency = 1
            TweenService:Create(card,
                TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Position = UDim2.new(0.5, -220, 0.5, -170),
                  BackgroundTransparency = 0 }):Play()
        end
    end)

    -- Public API used by RaceClient
    local refs = {
        overlay   = overlay,
        posLabel  = posLbl,
        totalLabel = totalLbl,
        bestLabel  = bestLbl,
        coinLabel  = coinLbl,
    }

    function refs.show(position, totalTime, bestLap, coins)
        local suffixes = { "1st", "2nd", "3rd", "4th", "5th", "6th" }
        posLbl.Text   = "You finished " .. (suffixes[position] or (position .. "th")) .. "!"
        local function fmt(s)
            return string.format("%d:%05.2f", math.floor(s / 60), s % 60)
        end
        totalLbl.Text = "Total:    " .. fmt(totalTime)
        bestLbl.Text  = "Best Lap: " .. fmt(bestLap)
        coinLbl.Text  = "Coins:    " .. (coins or 0)
        overlay.Visible = true
    end

    return refs
end

return buildFinishScreen
