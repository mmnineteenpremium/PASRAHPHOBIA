local OwnerCheatConfig = {}

OwnerCheatConfig.DATASTORE_KEY = "OwnerCheatRoles:v1"
OwnerCheatConfig.DEFAULT_OWNER_USER_ID = 8603977492

OwnerCheatConfig.ROLES = {
	OWNER = "Owner",
	QA = "QA",
	NONE = "None",
}

OwnerCheatConfig.THROTTLE = {
	WINDOW_SECONDS = 0.35,
	BURST = 8,
}

OwnerCheatConfig.CANONICAL_GHOSTS = {
	"Pocong",
	"Kuntilanak",
	"Genderuwo",
	"Tuyul",
	"Leak",
	"Banaspati",
	"Jerangkong",
	"WeweGombel",
	"Palasik",
	"SilumanUlar",
	"SundelBolong",
	"HantuTanah",
}

OwnerCheatConfig.GHOST_ANIMATIONS = {
	"GhostIdle",
	"GhostRoam",
	"GhostManifest",
	"GhostHunt",
	"GhostAttack",
	"GhostCooldown",
	"GhostJumpscare",
}

OwnerCheatConfig.GHOST_SPAWN_LOCATIONS = {
	{
		id = "in_place",
		label = "Di tempat",
	},
	{
		id = "in_front",
		label = "Di depan karakter (1,2 m)",
	},
}

OwnerCheatConfig.GHOST_FRONT_SPAWN_DISTANCE_STUDS = 4.3

OwnerCheatConfig.OWNER_ONLY_ACTIONS = {
	AddQA = true,
	RemoveQA = true,
	TransferOwner = true,
	InspectRoleState = true,
}

OwnerCheatConfig.QA_ACTIONS = {
	RequestAuth = true,
	GhostSpawn = true,
	GhostDespawn = true,
	GhostAnimation = true,
	GhostScale = true,
	GhostResetScale = true,
	GhostFreeze = true,
	GhostChase = true,
	PreviewGhostSFX = true,
	GrantTestItem = true,
	EquipTestItem = true,
	StartSoloMatch = true,
	EndMatch = true,
	AdvanceInvestigationPhase = true,
	ForceManifest = true,
	ForceHunt = true,
	TriggerJumpscare = true,
	TriggerGhostAudio = true,
	CleanupOwnerTestState = true,
	GetCatalogSnapshot = true,
}

function OwnerCheatConfig.IsOwnerOnlyAction(action)
	return OwnerCheatConfig.OWNER_ONLY_ACTIONS[action] == true
end

function OwnerCheatConfig.IsAllowedAction(action)
	return OwnerCheatConfig.OWNER_ONLY_ACTIONS[action] == true or OwnerCheatConfig.QA_ACTIONS[action] == true
end

return OwnerCheatConfig
