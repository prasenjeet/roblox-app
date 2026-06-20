-- TimerService: broadcasts elapsed time to all clients once per second,
-- and maintains a server-side fastest-times leaderboard (top 5).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteFunction so clients can request the fastest times table
local getTimesFunc = Instance.new("RemoteFunction")
getTimesFunc.Name = "GetFastestTimes"
getTimesFunc.Parent = ReplicatedStorage

local timerEvent = Instance.new("RemoteEvent")
timerEvent.Name = "TimerTick"
timerEvent.Parent = ReplicatedStorage

-- [{ name, time }] sorted ascending
local fastestTimes = {}
local MAX_RECORDS = 5

local function recordTime(playerName, seconds)
    -- Replace existing record for the same player if faster
    for i, entry in ipairs(fastestTimes) do
        if entry.name == playerName then
            if seconds < entry.time then
                entry.time = seconds
            end
            table.sort(fastestTimes, function(a, b) return a.time < b.time end)
            return
        end
    end
    table.insert(fastestTimes, { name = playerName, time = seconds })
    table.sort(fastestTimes, function(a, b) return a.time < b.time end)
    if #fastestTimes > MAX_RECORDS then
        table.remove(fastestTimes, MAX_RECORDS + 1)
    end
end

-- Listen for course completion to record time
local completedEvent = ReplicatedStorage:WaitForChild(
    "CourseCompleted", 10)

if completedEvent then
    -- The server fires this at the client; re-use the same event name
    -- but listen via a BindableEvent bridge if needed. Here we connect
    -- a simple wrapper: GameManager fires the RemoteEvent to clients, so
    -- we hook completion via a BindableEvent that GameManager can fire.
    -- For simplicity we expose a RemoteEvent the client echoes back.
    local confirmEvent = Instance.new("RemoteEvent")
    confirmEvent.Name = "ConfirmCompletion"
    confirmEvent.Parent = ReplicatedStorage

    confirmEvent.OnServerEvent:Connect(function(player, seconds)
        recordTime(player.DisplayName, seconds)
    end)
end

getTimesFunc.OnServerInvoke = function()
    return fastestTimes
end

-- Broadcast a tick every second with current server time (clients show their own delta)
local serverStartTime = tick()
while true do
    task.wait(1)
    local elapsed = math.floor(tick() - serverStartTime)
    timerEvent:FireAllClients(elapsed)
end
