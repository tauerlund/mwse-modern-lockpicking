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
		snapAngle = math.rad(-80),
		snapAngleVariance = 1.25,
		snapAngleSideMax = math.rad(20),
		snapTranslation = tes3vector3.new(0, 0, -2),
		handleKickAngle = math.rad(8),
		handleKickAngleVariance = 0.3,
		handleKickAngleSideMax = math.rad(5),
		fallDistance = 25,
		bounceHeight = 6,
	},

	damage = {
		baseRate = 20,
	},
}

return enum
