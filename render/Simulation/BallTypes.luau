local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Snapshot = require(ReplicatedStorage.Modules.Ball.Snapshot)
local Cleanup = require(ReplicatedStorage.Modules.Packages.Cleanup)
local DrasticSignal = require(ReplicatedStorage.Modules.DrasticSignal)

local module = {}

type ServerState = {
	LastReplicatedState: number,
	LastReplicationTime: number,
	BufferPool: {},
	PoolIndex: number,
}

export type BallData = {
	Position: Vector3,
	Velocity: Vector3,
	Spin: Vector3,
	TrailColor: Color3,
	BallModel: string,
	LastTime: number,
	LastSpikeTime: number,
	LastSpikePlayer: Player?,
	LastHit: {
		Player: Player?,
		Action: string,
	},
	SpinForceSTOP: number?,
	BallSnapshots: Snapshot.Snapshot,
	IgnoreList: {},
	DebounceList: {},
	IsActive: boolean,
	IsAlive: boolean,
	HitBeforeFeint: boolean,
	HitBeforeStop: boolean,
	Connection: RBXScriptConnection?,
	SpinMode: string,
	BallCleaner: Cleanup.Cleaner,
	BallModelInstance: Model,
	StillTimer: number,
	OldPositionMagnitude: number,
	RaycastParameters: RaycastParams,
	ServerState: ServerState,
	OldSend: {}?,
	HitRemote: RemoteEvent,
	BallSize: number,
	HitSignal: DrasticSignal.Signal,
	Misc: {
		MinusTempoOnSet: boolean,
		Orchestrator: boolean,
	},
}
return module
