---@enum PICK_CONSTANTS
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
		lerpSpeed = 9,
	},

	noise = {
		min = 0.001,
		max = 0.05,
		increase = 0.001,
	},
}

return enum
