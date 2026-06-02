---@enum knifeConstants
local enum = {
	rotation = {
		original = tes3vector3.new(-1.65, -1.37, 0.85),
		target = tes3vector3.new(-1.07, -1.23, 1.04),
	},

	translation = {
		original = tes3vector3.new(-10.92, -51.87, -7.98),
		target = tes3vector3.new(-4.26, -15.73, -0.58),
	},

	angles = {
		counterClockwise = math.rad(40),
		clockwise = math.rad(-40),
	},

	animation = {
		startAnimationDuration = 1,
		phaseSpeed = 1.9,
	},

	paths = {
		daggerMesh = "w\\W_iron_dagger.nif",
	},
}

return enum
