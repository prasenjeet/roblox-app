-- Race game constants shared by server and client.
local Constants = {}

-- Race rules
Constants.LAP_COUNT        = 3
Constants.CHECKPOINT_COUNT = 8

-- Vehicle speeds (studs / second)
Constants.CAR_MAX_SPEED    = 80
Constants.CAR_TURN_SPEED   = 1.2
Constants.TRAIN_MAX_SPEED  = 55
Constants.TRAIN_TURN_SPEED = 0.55

-- Track geometry (studs)
Constants.TRACK_STRAIGHT = 200   -- length of each straight
Constants.TRACK_SIDE     = 80    -- length of each side
Constants.TRACK_WIDTH    = 24    -- road width

-- Coin
Constants.COIN_VALUE = 10

-- CollectionService tags
Constants.CHECKPOINT_TAG = "Checkpoint"
Constants.FINISH_TAG     = "Finish"
Constants.CAR_TAG        = "RaceCar"
Constants.TRAIN_TAG      = "RaceTrain"
Constants.COIN_TAG       = "Coin"

-- RemoteEvent names
Constants.EVENTS = {
    CHECKPOINT_PASSED = "CheckpointPassed",
    LAP_COMPLETED     = "LapCompleted",
    RACE_FINISHED     = "RaceFinished",
    POSITION_UPDATE   = "PositionUpdate",
    VEHICLE_ASSIGNED  = "VehicleAssigned",
    COIN_COLLECTED    = "CoinCollected",
}

return Constants
