-- CoinService: animates coins (rotation + bob) on the server side.
-- Coins are tagged "Coin" via CollectionService by StageBuilder.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local coins = {}

local function registerCoin(coin)
    table.insert(coins, {
        part = coin,
        origin = coin.Position,
        phase = math.random() * math.pi * 2,
    })
end

for _, coin in ipairs(CollectionService:GetTagged("Coin")) do
    registerCoin(coin)
end

CollectionService:GetInstanceAddedSignal("Coin"):Connect(registerCoin)

RunService.Heartbeat:Connect(function()
    local t = tick()
    for _, c in ipairs(coins) do
        if c.part and c.part.Parent and c.part.Transparency == 0 then
            -- Gentle bobbing motion
            c.part.Position = c.origin + Vector3.new(0, math.sin(t * 2 + c.phase) * 0.4, 0)
            -- Spin around Y axis
            c.part.CFrame = CFrame.new(c.part.Position) * CFrame.Angles(0, t * 2 + c.phase, math.rad(90))
        end
    end
end)
