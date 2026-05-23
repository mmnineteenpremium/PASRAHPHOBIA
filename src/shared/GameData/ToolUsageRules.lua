local ToolUsageRules = {}

local DEFAULT_RULE = {
	flashlight = "Allowed",
	holdStyle = "SingleHand",
	preferredHand = "Right",
	hudMode = "None",
}

local RULES = {
	Flashlight = {
		flashlight = "PrimaryOnly",
		holdStyle = "SingleHand",
		preferredHand = "Right",
		hudMode = "None",
	},
	JejakEnergi = {
		flashlight = "Allowed",
		holdStyle = "SingleHand",
		preferredHand = "Right",
		hudMode = "EMF",
	},
	SuhuMembeku = {
		flashlight = "Allowed",
		holdStyle = "SingleHand",
		preferredHand = "Right",
		hudMode = "Thermo",
	},
	KotakArwah = {
		flashlight = "Allowed",
		holdStyle = "SingleHand",
		preferredHand = "Right",
		hudMode = "SpiritBox",
	},
	Dupa = {
		flashlight = "Allowed",
		holdStyle = "SingleHand",
		preferredHand = "Right",
		hudMode = "None",
	},
	PilSanity = {
		flashlight = "Blocked",
		holdStyle = "SingleHand",
		preferredHand = "Right",
		hudMode = "None",
	},
	Garam = {
		flashlight = "Blocked",
		holdStyle = "SingleHand",
		preferredHand = "Right",
		hudMode = "None",
	},
	Salib = {
		flashlight = "Blocked",
		holdStyle = "TwoHanded",
		preferredHand = "Right",
		hudMode = "None",
	},
	BukuTerkutuk = {
		flashlight = "Blocked",
		holdStyle = "TwoHanded",
		preferredHand = "Left",
		hudMode = "Writing",
	},
	BolaArwah = {
		flashlight = "Blocked",
		holdStyle = "SingleHand",
		preferredHand = "Right",
		hudMode = "Camera",
	},
	GerakanGaib = {
		flashlight = "Blocked",
		holdStyle = "SingleHand",
		preferredHand = "Right",
		hudMode = "None",
	},
}

local function cloneRule(rule)
	return {
		flashlight = rule.flashlight,
		holdStyle = rule.holdStyle,
		preferredHand = rule.preferredHand,
		hudMode = rule.hudMode,
	}
end

local function normalizeToolType(toolType)
	if type(toolType) ~= "string" then
		return nil
	end
	local token = string.gsub(toolType, "^%s*(.-)%s*$", "%1")
	if token == "" then
		return nil
	end
	return token
end

function ToolUsageRules.GetRule(toolType)
	local normalized = normalizeToolType(toolType)
	local rule = normalized and RULES[normalized] or nil
	if type(rule) ~= "table" then
		return cloneRule(DEFAULT_RULE)
	end
	return cloneRule(rule)
end

function ToolUsageRules.CanUseWithFlashlight(toolType)
	local rule = ToolUsageRules.GetRule(toolType)
	return rule.flashlight == "Allowed"
end

function ToolUsageRules.IsFlashlightPrimary(toolType)
	local rule = ToolUsageRules.GetRule(toolType)
	return rule.flashlight == "PrimaryOnly"
end

return ToolUsageRules
