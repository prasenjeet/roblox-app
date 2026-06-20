-- Shared game constants used by both server and client scripts.
local Constants = {}

Constants.STAGE_COUNT = 10
Constants.COIN_VALUE = 5
Constants.RESPAWN_DELAY = 2.5     -- seconds before the character re-spawns
Constants.CHECKPOINT_COLOR = Color3.fromRGB(0, 200, 100)
Constants.CHECKPOINT_TOUCHED_COLOR = Color3.fromRGB(255, 215, 0)

-- Stage length along the X axis (studs per stage)
Constants.STAGE_LENGTH = 80
Constants.STAGE_WIDTH = 20
Constants.PLATFORM_Y = 0          -- base Y for platforms

-- Kill brick tag
Constants.KILL_TAG = "KillBrick"
Constants.CHECKPOINT_TAG = "Checkpoint"
Constants.COIN_TAG = "Coin"
Constants.FINISH_TAG = "Finish"

-- RemoteEvent names (must match ReplicatedStorage children)
Constants.EVENTS = {
    CHECKPOINT_REACHED = "CheckpointReached",
    PLAYER_DIED = "PlayerDied",
    COURSE_COMPLETED = "CourseCompleted",
    COIN_COLLECTED = "CoinCollected",
}

return Constants
