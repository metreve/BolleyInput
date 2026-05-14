local State = {
	MaxPower = 15,
	Power = 15,

	MaxEnergy = 10,
	Energy = 10,

	Ready = true,
	Dived = false,
	Jumped = false,
	Spiked = false,
	JumpMode = true,
	JumpSetted = false,
	Spawned = false,

	BlockHolding = false,
	BlockHoldStarted = 0,
	BlockHoldDuration = 0.6,
	BlockJumpQueued = false,

	BarsConnection = nil,
	Stamina = 10,
	MaxStamina = nil,

	SetCooldown = false,
	PowerCooldown = false,

	SetCooldownTime = 0.25,
	PowerCooldownTime = 0.12,

	StaminaRegenRunning = false,

	SpaceHeld = false,
	GlideSlowRate = 3.5,
	MinGlideSpeedMultiplier = 0.15,
	ServeSpinConnection = nil,
	VPressStage = "Horiz",
	AutoServe = false,
	Spikable = true,
	Sprinting = false,
	Switchable = true,
	VPressed = false,
	Divable = true,
	Setable = true,

	HoldingPowerUp = false,
	HoldingPowerDown = false,

	AvailableRecAnim = nil,
	CurrentTilt = "None",

	BlockBarTween = nil,

	Spectator = false,
	PowerChangeable = true,
	FakeAping = false,

	UsingStepApproach = false,
	JumpHalf = false,
	GlideConnection = nil,

	ServeType = 1,
	Serve = 0,

	SetMode = false,
	SprintHeld = false,
	InAirTiltable = false,

	AvailableSpikeIdle = nil,
	AvailableJumpDelay = nil,
	AvailableBlockAnim = nil,
	LandingConnection = nil,

	CurrentDivingAnim = nil,
	DiveBounce = true,

	Character = nil,
	Humanoid = nil,
	RootPart = nil,

	BlockGui = nil,

	AvailableSideTiltAnim = nil,
	FovApplied = false,
	VBlocking = false,
	AwaitForState = nil,

	Connections = {},
	TouchConnections = {},
	DebounceList = {},
}

function State.ResetForCharacter(character)
	State.Character = character
	State.Humanoid = character:WaitForChild("Humanoid")
	State.RootPart = character:WaitForChild("HumanoidRootPart")

	State.Power = State.MaxPower
	State.Energy = State.MaxEnergy

	State.Ready = true
	State.Dived = false
	State.Jumped = false
	State.Spiked = false
	State.JumpMode = true
	State.JumpSetted = false
	State.Spawned = false
	State.Divable = true
	State.Setable = true
	State.Switchable = true
	State.SpaceHeld = false
	State.SprintHeld = false
	State.CurrentTilt = "None"
	State.InAirTiltable = false
	State.Serve = 0
end

return State
