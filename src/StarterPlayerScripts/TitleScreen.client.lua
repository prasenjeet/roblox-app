-- TitleScreen.client.lua
-- Full-screen title card shown on join. Two trains loop around the border.
-- Click PLAY to dismiss with a fade and start the game.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Root ─────────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name           = "TitleScreenGui"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = playerGui

local bg = Instance.new("Frame")
bg.Name             = "BG"
bg.Size             = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(8, 12, 28)
bg.BorderSizePixel  = 0
bg.Parent           = sg

local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Color    = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 18, 48)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(4,  7,  18)),
}
grad.Parent = bg

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function newFrame(parent, x, y, w, h, color, z)
    local f = Instance.new("Frame")
    f.Position         = UDim2.new(0, x, 0, y)
    f.Size             = UDim2.new(0, w, 0, h)
    f.BackgroundColor3 = color or Color3.new(1, 1, 1)
    f.BorderSizePixel  = 0
    f.ZIndex           = z or 2
    f.Parent           = parent
    return f
end

local function addCorner(f, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 4)
    c.Parent       = f
end

-- ── Track (rails + sleepers) ─────────────────────────────────────────────────
-- yScale positions the track vertically as a fraction of screen height.
local function makeTrack(yScale, z)
    for _, dy in ipairs({ 0, 22 }) do
        local rail = Instance.new("Frame")
        rail.Size             = UDim2.new(1, 0, 0, 4)
        rail.Position         = UDim2.new(0, 0, yScale, dy)
        rail.BackgroundColor3 = Color3.fromRGB(55, 62, 80)
        rail.BorderSizePixel  = 0
        rail.ZIndex           = z
        rail.Parent           = bg
    end
    for i = 0, 24 do
        local s = Instance.new("Frame")
        s.Size             = UDim2.new(0, 6, 0, 30)
        s.Position         = UDim2.new(0, i * 52, yScale, -4)
        s.BackgroundColor3 = Color3.fromRGB(46, 34, 22)
        s.BorderSizePixel  = 0
        s.ZIndex           = z - 1
        s.Parent           = bg
    end
end

-- ── Train builder ─────────────────────────────────────────────────────────────
-- Layout in container (left→right): [Car2][Car1][Engine] when engineLeft=false
--   → engine is rightmost → front when moving RIGHT.
-- When engineLeft=true:  [Engine][Car1][Car2]
--   → engine is leftmost → front when moving LEFT.
local EW, EH = 64, 32   -- engine width / height
local CW, CH = 52, 26   -- car width / height
local GAP    = 8
local TW     = CW + GAP + CW + GAP + EW   -- 192 px total

local function buildTrain(parent, yScale, engineLeft, z)
    local container = Instance.new("Frame")
    container.Size                   = UDim2.new(0, TW, 0, EH + 16)
    container.Position               = UDim2.new(engineLeft and 1.05 or -0.22, 0, yScale, -(EH + 8))
    container.BackgroundTransparency = 1
    container.ClipsDescendants       = false
    container.ZIndex                 = z
    container.Parent                 = parent

    -- Part helper (absolute coords inside container)
    local function p(px, py, pw, ph, color, r)
        local f = newFrame(container, px, py, pw, ph, color, z + 1)
        if r then addCorner(f, r) end
        return f
    end

    local function wheel(wx)
        p(wx,     EH + 4, 10, 10, Color3.fromRGB(15, 15, 15), 5)
        p(wx + 3, EH + 7,  4,  4, Color3.fromRGB(75, 75, 75), 2)
    end

    local eX, c1X, c2X
    if engineLeft then
        eX = 0; c1X = EW + GAP; c2X = EW + GAP + CW + GAP
    else
        c2X = 0; c1X = CW + GAP; eX = CW + GAP + CW + GAP
    end

    -- Car 2 (rearmost)
    p(c2X,      5, CW, CH, Color3.fromRGB(74, 42, 42), 5)
    p(c2X +  7, 9, 13,  9, Color3.fromRGB(80, 168, 222), 3)
    p(c2X + 29, 9, 13,  9, Color3.fromRGB(80, 168, 222), 3)
    wheel(c2X + 4); wheel(c2X + CW - 14)

    -- Car 1
    p(c1X,      5, CW, CH, Color3.fromRGB(94, 50, 50), 5)
    p(c1X +  7, 9, 13,  9, Color3.fromRGB(80, 168, 222), 3)
    p(c1X + 29, 9, 13,  9, Color3.fromRGB(80, 168, 222), 3)
    wheel(c1X + 4); wheel(c1X + CW - 14)

    -- Engine body
    p(eX, 0, EW, EH, Color3.fromRGB(22, 22, 28), 6)

    -- Cab window (on the trailing side)
    if engineLeft then
        p(eX + EW - 22, 5, 18, 13, Color3.fromRGB(80, 168, 222), 3)
    else
        p(eX + 4, 5, 18, 13, Color3.fromRGB(80, 168, 222), 3)
    end

    -- Chimney (on the leading nose)
    local chiX = engineLeft and (eX + 8) or (eX + EW - 18)
    p(chiX - 2, -15, 14,  5, Color3.fromRGB(14, 14, 18), 5)  -- chimney cap
    p(chiX,     -13, 10, 17, Color3.fromRGB(14, 14, 18), 5)  -- chimney barrel

    -- Headlight (nose)
    local hlX = engineLeft and eX or (eX + EW - 7)
    p(hlX, math.floor(EH / 2) - 5, 7, 10, Color3.fromRGB(255, 235, 90), 3)

    -- Boiler dome
    local domX = engineLeft and (eX + 22) or (eX + EW - 40)
    p(domX, -5, 18, 10, Color3.fromRGB(28, 28, 35), 5)

    wheel(eX + 4); wheel(eX + EW - 14)

    return container
end

-- ── Train animation ───────────────────────────────────────────────────────────
-- Loops a train container across the screen.
-- goRight=true → left-to-right; goRight=false → right-to-left.
local function loopTrain(container, goRight, duration, delayStart)
    local yS = container.Position.Y.Scale
    local yO = container.Position.Y.Offset
    task.delay(delayStart or 0, function()
        while container and container.Parent do
            container.Position = UDim2.new(goRight and -0.22 or 1.05, 0, yS, yO)
            TweenService:Create(container,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                { Position = UDim2.new(goRight and 1.05 or -0.22, 0, yS, yO) }
            ):Play()
            task.wait(duration)
        end
    end)
end

-- Track Y (scale): where rails sit.
-- Train container Y (scale): EH+8 px above track so engine base rests on the rail.
-- On a 720-px screen, 40 px / 720 ≈ 0.055 offset per train above its track Y.
local TOP_TRACK  = 0.13
local BOT_TRACK  = 0.83
local TOP_TRAIN  = TOP_TRACK - (EH + 8) / 720   -- ≈ 0.074
local BOT_TRAIN  = BOT_TRACK - (EH + 8) / 720

makeTrack(TOP_TRACK, 3)
makeTrack(BOT_TRACK, 3)

-- Top track: two trains going RIGHT (engine on right side, i.e. front)
local ta = buildTrain(bg, TOP_TRAIN, false, 4)
local tb = buildTrain(bg, TOP_TRAIN, false, 4)
loopTrain(ta, true,  10, 0)
loopTrain(tb, true,  10, 5)

-- Bottom track: two trains going LEFT (engine on left side, i.e. front)
local ba = buildTrain(bg, BOT_TRAIN, true, 4)
local bb = buildTrain(bg, BOT_TRAIN, true, 4)
loopTrain(ba, false, 12, 0)
loopTrain(bb, false, 12, 6)

-- ── Center card ───────────────────────────────────────────────────────────────
local CW2, CH2 = 440, 300

local card = Instance.new("Frame")
card.Name                   = "Card"
card.Size                   = UDim2.new(0, CW2, 0, CH2)
card.Position               = UDim2.new(0.5, -CW2 / 2, 0.55, -CH2 / 2)  -- starts low
card.BackgroundColor3       = Color3.fromRGB(14, 16, 34)
card.BackgroundTransparency = 1
card.BorderSizePixel        = 0
card.ZIndex                 = 8
card.Parent                 = bg
addCorner(card, 20)

local stroke = Instance.new("UIStroke")
stroke.Color     = Color3.fromRGB(255, 200, 0)
stroke.Thickness = 3
stroke.Parent    = card

-- Title
local titleLbl = Instance.new("TextLabel")
titleLbl.Size                  = UDim2.new(1, -20, 0, 82)
titleLbl.Position              = UDim2.new(0, 10, 0, 16)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                  = "RAIL RUSH"
titleLbl.TextColor3            = Color3.fromRGB(255, 208, 0)
titleLbl.Font                  = Enum.Font.GothamBold
titleLbl.TextScaled            = true
titleLbl.TextTransparency      = 1
titleLbl.ZIndex                = 9
titleLbl.Parent                = card

-- Subtitle
local subLbl = Instance.new("TextLabel")
subLbl.Size                  = UDim2.new(1, -20, 0, 34)
subLbl.Position              = UDim2.new(0, 10, 0, 102)
subLbl.BackgroundTransparency = 1
subLbl.Text                  = "TRAINS  \xE2\x80\xA2  CARS  \xE2\x80\xA2  3 LAPS"
subLbl.TextColor3            = Color3.fromRGB(148, 168, 228)
subLbl.Font                  = Enum.Font.Gotham
subLbl.TextScaled            = true
subLbl.TextTransparency      = 1
subLbl.ZIndex                = 9
subLbl.Parent                = card

-- Divider
newFrame(card, 20, 146, CW2 - 40, 2, Color3.fromRGB(40, 48, 75), 9)

-- Play button
local playBtn = Instance.new("TextButton")
playBtn.Name              = "PlayButton"
playBtn.Size              = UDim2.new(0, 200, 0, 52)
playBtn.Position          = UDim2.new(0.5, -100, 0, 164)
playBtn.BackgroundColor3  = Color3.fromRGB(38, 188, 72)
playBtn.Text              = "\xe2\x96\xb6  PLAY"
playBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
playBtn.Font              = Enum.Font.GothamBold
playBtn.TextSize          = 22
playBtn.BorderSizePixel   = 0
playBtn.ZIndex            = 9
playBtn.Parent            = card
addCorner(playBtn, 12)

-- Hint
local hintLbl = Instance.new("TextLabel")
hintLbl.Size                  = UDim2.new(1, -20, 0, 26)
hintLbl.Position              = UDim2.new(0, 10, 0, 260)
hintLbl.BackgroundTransparency = 1
hintLbl.Text                  = "Dodge obstacles \xc2\xb7 collect coins \xc2\xb7 beat your time"
hintLbl.TextColor3            = Color3.fromRGB(75, 88, 118)
hintLbl.Font                  = Enum.Font.Gotham
hintLbl.TextScaled            = true
hintLbl.TextTransparency      = 1
hintLbl.ZIndex                = 9
hintLbl.Parent                = card

-- Card + text entrance animation (slide up, fade in)
task.delay(0.15, function()
    local tweenInfo = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(card, tweenInfo, {
        Position            = UDim2.new(0.5, -CW2 / 2, 0.5, -CH2 / 2),
        BackgroundTransparency = 0,
    }):Play()
    TweenService:Create(titleLbl, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
    TweenService:Create(subLbl,   TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
    TweenService:Create(hintLbl,  TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
end)

-- ── Play-click transition: large train + car sweep across screen ──────────────
local CEW, CEH   = 120, 60    -- centre-train engine size
local CCW2, CCH2 = 100, 50    -- centre-train car size
local CGAP2      = 10
local CTW        = CCW2 + CGAP2 + CCW2 + CGAP2 + CEW   -- 340 px

local function buildCenterTrain()
    local c = Instance.new("Frame")
    c.Size                   = UDim2.new(0, CTW, 0, CEH + 18)
    c.BackgroundTransparency = 1
    c.ClipsDescendants       = false
    c.ZIndex                 = 12
    c.Parent                 = bg

    local function p(px, py, pw, ph, color, r)
        local f = newFrame(c, px, py, pw, ph, color, 13)
        if r then addCorner(f, r) end
        return f
    end
    local function whl(wx)
        p(wx,     CEH + 5, 18, 18, Color3.fromRGB(15, 15, 15), 9)
        p(wx + 4, CEH + 9, 10, 10, Color3.fromRGB(75, 75, 75), 5)
    end

    -- Engine on RIGHT (front for rightward motion), cars trailing on left
    local c2X = 0
    local c1X = CCW2 + CGAP2
    local eX  = CCW2 + CGAP2 + CCW2 + CGAP2

    -- Car 2
    p(c2X,       8, CCW2, CCH2, Color3.fromRGB(74, 42, 42), 6)
    p(c2X + 12, 14,   22,   16, Color3.fromRGB(80, 168, 222), 3)
    p(c2X + 44, 14,   22,   16, Color3.fromRGB(80, 168, 222), 3)
    p(c2X + 74, 14,   16,   16, Color3.fromRGB(80, 168, 222), 3)
    whl(c2X + 6); whl(c2X + CCW2 - 24)

    -- Car 1
    p(c1X,       8, CCW2, CCH2, Color3.fromRGB(94, 50, 50), 6)
    p(c1X + 12, 14,   22,   16, Color3.fromRGB(80, 168, 222), 3)
    p(c1X + 44, 14,   22,   16, Color3.fromRGB(80, 168, 222), 3)
    p(c1X + 74, 14,   16,   16, Color3.fromRGB(80, 168, 222), 3)
    whl(c1X + 6); whl(c1X + CCW2 - 24)

    -- Engine body
    p(eX, 0, CEW, CEH, Color3.fromRGB(22, 22, 28), 8)
    -- Cab window (trailing left side)
    p(eX + 6,  8, 28, 22, Color3.fromRGB(80, 168, 222), 4)
    -- Red accent stripe along bottom of engine
    p(eX, CEH - 10, CEW, 10, Color3.fromRGB(180, 40, 40), 0)
    -- Chimney (leading right nose)
    p(eX + CEW - 28, -20, 24,  8, Color3.fromRGB(14, 14, 18), 4)
    p(eX + CEW - 22, -18, 16, 26, Color3.fromRGB(14, 14, 18), 6)
    -- Headlight
    p(eX + CEW - 10, CEH / 2 - 9, 10, 18, Color3.fromRGB(255, 235, 90), 4)
    -- Boiler dome
    p(eX + 36, -8, 28, 14, Color3.fromRGB(30, 30, 38), 6)
    whl(eX + 8); whl(eX + CEW - 26)

    return c
end

local function buildCenterCar()
    local BW, BH = 180, 42   -- body width / height
    local RW, RH = 112, 34   -- roof/cabin width / height

    local c = Instance.new("Frame")
    c.Size                   = UDim2.new(0, BW, 0, RH + BH + 22)
    c.BackgroundTransparency = 1
    c.ClipsDescendants       = false
    c.ZIndex                 = 12
    c.Parent                 = bg

    local function p(px, py, pw, ph, color, r)
        local f = newFrame(c, px, py, pw, ph, color, 13)
        if r then addCorner(f, r) end
        return f
    end
    local function whl(wx)
        local wy = RH + BH + 2
        p(wx,     wy,     24, 24, Color3.fromRGB(18, 18, 18), 12)
        p(wx + 5, wy + 5, 14, 14, Color3.fromRGB(65, 65, 65),  7)
    end

    -- Body
    p(0, RH, BW, BH, Color3.fromRGB(55, 105, 175), 8)
    -- Roof/cabin (slightly inset from body edges)
    p(34, 0, RW, RH + 10, Color3.fromRGB(44, 88, 155), 8)
    -- Front windshield (right side = leading for rightward motion)
    p(BW - 36, RH - 20, 32, 30, Color3.fromRGB(140, 210, 255), 5)
    -- Rear window
    p(4, RH - 16, 26, 26, Color3.fromRGB(140, 210, 255), 4)
    -- Side windows
    p(44, 4, 32, 22, Color3.fromRGB(140, 210, 255), 3)
    p(86, 4, 32, 22, Color3.fromRGB(140, 210, 255), 3)
    -- Door seam
    p(70, RH + 4, 2, BH - 8, Color3.fromRGB(38, 80, 145), 0)
    -- Headlights (front = right)
    p(BW - 8, RH + 8, 8, 14, Color3.fromRGB(255, 248, 200), 2)
    -- Taillights (rear = left)
    p(0, RH + 8, 6, 14, Color3.fromRGB(255, 55, 55), 2)
    -- Bumpers
    p(BW - 12, RH + BH - 14, 12, 10, Color3.fromRGB(155, 155, 165), 3)
    p(0,       RH + BH - 14, 10, 10, Color3.fromRGB(155, 155, 165), 3)
    -- Wheels
    whl(12); whl(BW - 36)

    return c
end

-- Button hover
playBtn.MouseEnter:Connect(function()
    TweenService:Create(playBtn, TweenInfo.new(0.12),
        { BackgroundColor3 = Color3.fromRGB(50, 215, 85) }):Play()
end)
playBtn.MouseLeave:Connect(function()
    TweenService:Create(playBtn, TweenInfo.new(0.12),
        { BackgroundColor3 = Color3.fromRGB(38, 188, 72) }):Play()
end)

-- Dismiss: card fades, train + car sweep across, then black fade
playBtn.MouseButton1Click:Connect(function()
    playBtn.Active = false

    -- 1. Card fades out
    TweenService:Create(card,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, -CW2 / 2, 0.58, -CH2 / 2),
          BackgroundTransparency = 1 }):Play()
    TweenService:Create(titleLbl, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
    TweenService:Create(subLbl,   TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
    TweenService:Create(hintLbl,  TweenInfo.new(0.2), { TextTransparency = 1 }):Play()

    -- 2. Large train sweeps left → right across the upper-centre of the screen
    local cTrain = buildCenterTrain()
    cTrain.Position = UDim2.new(-0.32, 0, 0.34, 0)
    TweenService:Create(cTrain,
        TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(1.05, 0, 0.34, 0) }
    ):Play()

    -- 3. Car follows slightly behind, faster (overtakes on exit)
    task.delay(0.15, function()
        local cCar = buildCenterCar()
        cCar.Position = UDim2.new(-0.20, 0, 0.60, 0)
        TweenService:Create(cCar,
            TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(1.05, 0, 0.60, 0) }
        ):Play()
    end)

    -- 4. Black fade once vehicles have passed through centre
    task.delay(0.85, function()
        local fade = Instance.new("Frame")
        fade.Size                   = UDim2.fromScale(1, 1)
        fade.BackgroundColor3       = Color3.new(0, 0, 0)
        fade.BackgroundTransparency = 1
        fade.BorderSizePixel        = 0
        fade.ZIndex                 = 20
        fade.Parent                 = sg
        TweenService:Create(fade, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
        task.delay(0.45, function() sg:Destroy() end)
    end)
end)
