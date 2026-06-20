-- WorkspaceTemplate: documents the runtime Workspace hierarchy for the race game.
-- The track and vehicles are built procedurally by TrackBuilder (StageBuilder.lua)
-- and spawned by GameManager (RaceManager).

--[[
Expected Workspace hierarchy after RaceManager runs:

Workspace
├── Track               Folder
│   ├── TopStraight     Part   (road)
│   ├── BotStraight     Part   (road)
│   ├── LeftSide        Part   (road)
│   ├── RightSide       Part   (road)
│   ├── CornerTL/TR/BR/BL  Part (road)
│   ├── RailTop/Bot/Left/Right  Part  (metal rail strip)
│   ├── Dash*           Part   (lane dividers, Neon)
│   ├── OBar*/IBar*     Part   (outer/inner barriers, Neon)
│   ├── StartFinish     Part   [tag: Finish]
│   ├── Post/GantryBar  Part   (start gantry deco)
│   └── ...
│
├── Checkpoints         Folder
│   ├── CP_1 … CP_8    Part   [tag: Checkpoint, attr: CheckpointIndex]
│
├── Coins              Folder
│   └── Coin (×10)     Part   [tag: Coin]
│
├── RaceCar            Model
│   ├── Body           Part   [tag: RaceCar]  ← PrimaryPart
│   ├── VehicleSeat    VehicleSeat
│   ├── Wheel (×4)     Part   (cylinder, welded)
│   └── Windshield     Part   (welded)
│
└── RaceTrain          Model
    ├── Engine         Part   [tag: RaceTrain]  ← PrimaryPart
    ├── VehicleSeat    VehicleSeat
    ├── Car1 / Car2    Part   (welded)
    ├── TrainWheel (×4) Part  (cylinder, welded)
    └── Chimney        Part   (welded)

ReplicatedStorage
├── Shared
│   ├── Constants      ModuleScript
│   └── StageBuilder   ModuleScript   (TrackBuilder)
├── CheckpointPassed   RemoteEvent
├── LapCompleted       RemoteEvent
├── RaceFinished       RemoteEvent
├── PositionUpdate     RemoteEvent
├── VehicleAssigned    RemoteEvent
└── CoinCollected      RemoteEvent

Race rules:
  - 3 laps (Constants.LAP_COUNT)
  - 8 checkpoints per lap, must be hit in order 1→8 before finish line counts
  - First player to join drives the Car; second drives the Train
  - Clockwise track: +X along top → right side +Z → -X along bottom → left side -Z
]]

return {}
