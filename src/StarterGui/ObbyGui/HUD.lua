-- RaceHUD: heads-up display shown during the race.
-- Returns a table of label references used by RaceClient to update values.

local function buildHUD(screenGui)
    local hud = Instance.new("Frame")
    hud.Name                = "HUD"
    hud.Size                = UDim2.fromScale(1, 1)
    hud.BackgroundTransparency = 1
    hud.Parent              = screenGui

    -- Helper: pill badge
    local function badge(name, defaultText, position, size, textSize)
        local bg = Instance.new("Frame")
        bg.Name               = name .. "BG"
        bg.Size               = size or UDim2.new(0, 160, 0, 40)
        bg.Position           = position
        bg.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.45
        bg.BorderSizePixel    = 0
        bg.Parent             = hud
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 10); c.Parent = bg

        local lbl = Instance.new("TextLabel")
        lbl.Name                  = name
        lbl.Size                  = UDim2.new(1, -12, 1, 0)
        lbl.Position              = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text                  = defaultText
        lbl.TextColor3            = Color3.fromRGB(255, 255, 255)
        lbl.Font                  = Enum.Font.GothamSemibold
        lbl.TextSize              = textSize or 16
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Parent                = bg
        return lbl
    end

    -- Top-left: lap counter
    local lapLbl = badge("LapLabel", "Lap 0 / 3",
        UDim2.new(0, 12, 0, 12), UDim2.new(0, 160, 0, 40))

    -- Top-left below: checkpoint progress
    local cpLbl = badge("CPLabel", "CP 0 / 8",
        UDim2.new(0, 12, 0, 60), UDim2.new(0, 160, 0, 36))

    -- Top-left below: best lap
    local bestLbl = badge("BestLabel", "Best: --",
        UDim2.new(0, 12, 0, 104), UDim2.new(0, 160, 0, 36))

    -- Top-centre: position badge (bigger)
    local posBG = Instance.new("Frame")
    posBG.Name               = "PosBG"
    posBG.Size               = UDim2.new(0, 120, 0, 54)
    posBG.Position           = UDim2.new(0.5, -60, 0, 12)
    posBG.BackgroundColor3   = Color3.fromRGB(200, 40, 40)
    posBG.BackgroundTransparency = 0.25
    posBG.BorderSizePixel    = 0
    posBG.Parent             = hud
    local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 12); pc.Parent = posBG
    local posLbl = Instance.new("TextLabel")
    posLbl.Name               = "PosLabel"
    posLbl.Size               = UDim2.fromScale(1, 1)
    posLbl.BackgroundTransparency = 1
    posLbl.Text               = "--"
    posLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
    posLbl.Font               = Enum.Font.GothamBold
    posLbl.TextScaled         = true
    posLbl.Parent             = posBG

    -- Top-right: timer
    local timerLbl = badge("TimerLabel", "0:00.00",
        UDim2.new(1, -172, 0, 12), UDim2.new(0, 160, 0, 40), 18)

    -- Top-right below: vehicle type
    local vehicleLbl = badge("VehicleLabel", "",
        UDim2.new(1, -172, 0, 60), UDim2.new(0, 160, 0, 36))

    -- Notification banner (centre, hidden by default)
    local notif = Instance.new("TextLabel")
    notif.Name                  = "NotifLabel"
    notif.Size                  = UDim2.new(0, 420, 0, 50)
    notif.Position              = UDim2.new(0.5, -210, 0, 160)
    notif.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
    notif.BackgroundTransparency = 0.4
    notif.BorderSizePixel       = 0
    notif.Text                  = ""
    notif.TextColor3            = Color3.fromRGB(255, 220, 0)
    notif.Font                  = Enum.Font.GothamBold
    notif.TextScaled            = true
    notif.Visible               = false
    notif.ZIndex                = 6
    notif.Parent                = hud
    local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 10); nc.Parent = notif

    return {
        lapLabel     = lapLbl,
        cpLabel      = cpLbl,
        bestLabel    = bestLbl,
        posLabel     = posLbl,
        timerLabel   = timerLbl,
        vehicleLabel = vehicleLbl,
        notifLabel   = notif,
    }
end

return buildHUD
