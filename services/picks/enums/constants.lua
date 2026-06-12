---@enum pickConstants
local enum = {
	rotation = {
		original = tes3vector3.new(-0.19, 1.41, 0.10),
		target = tes3vector3.new(0.96, 0.97, -0.00),
	},

	translation = {
		original = tes3vector3.new(-0.42, -57.06, 6.90),
		target = tes3vector3.new(0.18, -6.00, 8.22),
	},

	animation = {
		startAnimationDuration = 1.2,
		cycleAnimationDuration = 0.5,
		lerpSpeed = 9,
		jiggleSpeed = 65,
		jiggleAmplitude = math.rad(1),
		jiggleDamageFactor = 2.5,
		jiggleNoise = 0.5,
	},

	breakAnimation = {
		duration = 0.75,
		cycleDelay = 0.5,
		snapAngle = math.rad(-120),
		snapAngleVariance = 0.45,
		snapAngleSideMax = math.rad(20),
		snapTranslation = tes3vector3.new(0, 0, -2),
		handleKickAngle = math.rad(8),
		handleKickAngleVariance = 0.3,
		handleKickAngleSideMax = math.rad(5),
		fallDistance = 30,
		bounceHeight = 8,
	},
}

return enum
