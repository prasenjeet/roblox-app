-- HUD: creates the heads-up display Frame shown during gameplay.
-- This ModuleScript returns the Frame so ObbyGui can parent it.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function makeLabel(name, text, position, parent)
    local frame = Instance.new("Frame")
    frame.Name = name .. "Frame"
    frame.Size = UDim2.new(0, 160, 0, 36)
    frame.Position = position
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.45
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    return label
end

local function buildHUD(screenGui)
    local hud = Instance.new("Frame")
    hud.Name = "HUD"
    hud.Size = UDim2.new(0, 170, 0, 170)
    hud.Position = UDim2.new(0, 12, 0, 12)
    hud.BackgroundTransparency = 1
    hud.Parent = screenGui

    makeLabel("StageLabel",  "Stage: 1",   UDim2.new(0, 0, 0, 0),   hud)
    makeLabel("DeathLabel",  "Deaths: 0",  UDim2.new(0, 0, 0, 44),  hud)
    makeLabel("CoinLabel",   "Coins: 0",   UDim2.new(0, 0, 0, 88),  hud)
    makeLabel("TimerLabel",  "Time: 0:00", UDim2.new(0, 0, 0, 132), hud)

    -- Keep labels in sync with leaderstats changes
    local function syncStats()
        local stats = player:FindFirstChild("leaderstats")
        if not stats then return end

        local function bind(valueName, labelName, prefix)
            local val = stats:FindFirstChild(valueName)
            if not val then return end
            local lbl = hud:FindFirstChild(labelName, true)
            if lbl then lbl.Text = prefix .. val.Value end
            val.Changed:Connect(function(v)
                local l = hud:FindFirstChild(labelName, true)
                if l then l.Text = prefix .. v end
            end)
        end

        bind("Stage",  "StageLabel", "Stage: ")
        bind("Deaths", "DeathLabel", "Deaths: ")
        bind("Coins",  "CoinLabel",  "Coins: ")
    end

    task.delay(1.5, syncStats)
    return hud
end

return buildHUD
