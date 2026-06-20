-- FinishScreen: full-screen overlay displayed when the player completes the course.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local function buildFinishScreen(screenGui)
    local overlay = Instance.new("Frame")
    overlay.Name = "FinishScreen"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.35
    overlay.Visible = false
    overlay.ZIndex = 5
    overlay.Parent = screenGui

    -- Card
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(0, 420, 0, 320)
    card.Position = UDim2.new(0.5, -210, 0.5, -160)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    card.BorderSizePixel = 0
    card.ZIndex = 6
    card.Parent = overlay

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 16)
    title.BackgroundTransparency = 1
    title.Text = "COURSE COMPLETE!"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 7
    title.Parent = card

    local function makeStatLabel(name, defaultText, yOffset)
        local lbl = Instance.new("TextLabel")
        lbl.Name = name
        lbl.Size = UDim2.new(1, -40, 0, 40)
        lbl.Position = UDim2.new(0, 20, 0, yOffset)
        lbl.BackgroundTransparency = 1
        lbl.Text = defaultText
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamSemibold
        lbl.ZIndex = 7
        lbl.Parent = card
        return lbl
    end

    makeStatLabel("TimeLabel",   "Time: --",    90)
    makeStatLabel("DeathsLabel", "Deaths: --",  140)
    makeStatLabel("CoinsLabel",  "Coins: --",   190)

    -- Play Again button
    local btn = Instance.new("TextButton")
    btn.Name = "PlayAgainButton"
    btn.Size = UDim2.new(0, 180, 0, 48)
    btn.Position = UDim2.new(0.5, -90, 1, -70)
    btn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
    btn.BorderSizePixel = 0
    btn.Text = "Play Again"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 7
    btn.Parent = card

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        -- Trigger a respawn by killing the character
        local player = Players.LocalPlayer
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
        overlay.Visible = false
    end)

    -- Animate card in when shown
    overlay:GetPropertyChangedSignal("Visible"):Connect(function()
        if overlay.Visible then
            card.Position = UDim2.new(0.5, -210, 0.6, -160)
            card.BackgroundTransparency = 1
            TweenService:Create(card,
                TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Position = UDim2.new(0.5, -210, 0.5, -160), BackgroundTransparency = 0 }
            ):Play()
        end
    end)

    return overlay
end

return buildFinishScreen
