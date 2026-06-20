-- CourseTemplate: a Module that documents expected Workspace layout.
-- At runtime the course is generated procedurally by StageBuilder
-- (called from GameManager.server.lua), so this file is informational.

--[[
Expected Workspace hierarchy after GameManager runs:

Workspace
├── Baseplate          (optional, can be deleted for a skybox-only look)
├── Obbycourse         Folder
│   ├── Stage_1        Folder
│   │   ├── SpawnPlatform   Part
│   │   ├── Checkpoint      Part  [tag: Checkpoint, attr: StageNumber=1]
│   │   ├── Platform        Part  (×N per stage)
│   │   ├── KillBrick       Part  [tag: KillBrick]  (optional)
│   │   └── KillFloor       Part  [tag: KillBrick]
│   ├── Stage_2 … Stage_10
│   └── Finish         Folder
│       ├── FinishPlatform  Part
│       ├── FinishTrigger   Part  [tag: Finish]
│       └── Trophy          Part
└── Coins              Folder
    └── Coin           Part (×30)  [tag: Coin]

ReplicatedStorage
├── Shared
│   ├── Constants      ModuleScript
│   └── StageBuilder   ModuleScript
├── CheckpointReached  RemoteEvent
├── PlayerDied         RemoteEvent
├── CourseCompleted    RemoteEvent
├── CoinCollected      RemoteEvent
├── ConfirmCompletion  RemoteEvent
├── GetFastestTimes    RemoteFunction
└── TimerTick          RemoteEvent
]]

return {}
