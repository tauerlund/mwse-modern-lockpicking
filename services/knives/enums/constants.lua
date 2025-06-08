---@enum KNIFE_CONSTANTS
local enum = {
	rotation = {
		initial = tes3vector3.new(-1.65, -1.37, 0.85),
		target = tes3vector3.new(-1.07, -1.23, 1.04),
	},

	translation = {
		initial = tes3vector3.new(-10.92, -51.87, -7.98),
		target = tes3vector3.new(-4.26, -15.73, -0.58),
	},

	angles = {
		counterClockwise = math.rad(40),
		clockwise = math.rad(-40),
	},

	phase = {
		speed = 1.9,
	},
}

return enum
