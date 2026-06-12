---@enum lockConstants
local enum = {
	targetDistance = 80,
	referenceVerticalTan = math.tan(math.rad(75) * 0.5) * (9 / 16),
	paths = {
		defaultLockMesh = "tauer\\lock_new.nif",
	},
	rootName = "ModernLockpicking:Root",
	cameraRootZBufferName = "ModernLockpicking:NoDepth",
	crimeGoldAmount = 5,
}

return enum
