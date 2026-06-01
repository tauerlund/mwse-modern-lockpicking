local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local CONSTANTS = require("tauer.modern-lockpicking.services.lockpicking.enums.CONSTANTS")
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm

local LINE_LENGTH = 0.5
local DEFAULT_MESH_LENGTH = 1000

---@class debuggingRenderer : initializedService
local this = {}

---@private
---@type niNode|nil
this.root = nil

---@private
---@type niNode|nil
this.linesContainer = nil

---@public
---@return boolean, string|nil
function this.initialize()
	event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
	event.register(EVENTS.sweetSpotUpdated, this.onSweetSpotUpdated)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	return true, nil
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.root = e.session.lock.mesh
end

---@private
---@param e sweetSpotUpdatedEventData
function this.onSweetSpotUpdated(e)
	this.clearLines()
	if not this.root or not settings.debugging.showSweetSpotRenderer then
		return
	end

	this.linesContainer = niNode.new()
	this.root:attachChild(this.linesContainer)

	local function clamp(angle)
		return math.max(CONSTANTS.targetRotationLeft, math.min(CONSTANTS.targetRotationRight, angle))
	end

	this.addLine(clamp(e.center - e.radius), false)
	this.addLine(clamp(e.center + e.radius), false)
	this.addLine(clamp(e.center - e.radius - e.gradientWidth), true)
	this.addLine(clamp(e.center + e.radius + e.gradientWidth), true)

	this.linesContainer:update()
	this.root:update()
end

---@private
---@param angle number
---@param yellow boolean
function this.addLine(angle, yellow)
	local mesh = tes3.loadMesh("mwse\\widgets.nif") --[[@as niNode]]
	local axes = mesh:getObjectByName("axisLines") --[[@as niSwitchNode]]
	local line = axes.children[2]:clone() --[[@as niTriShape]]

	if yellow then
		line = axes.children[1]:clone() --[[@as niTriShape]]
	end

	this.linesContainer:attachChild(line)

	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(0, angle, 0)
	line.rotation = rotation
	line.scale = LINE_LENGTH / DEFAULT_MESH_LENGTH

	local translation = line.translation:copy()
	local yaw = line.rotation:toEulerXYZ().y
	local dx = -math.sin(yaw) * 10
	local dz = math.cos(yaw) * 10
	line.translation = translation + tes3vector3.new(dx, 0, dz)

	line:update()
end

---@private
function this.clearLines()
	if this.root and this.linesContainer then
		this.root:detachChild(this.linesContainer)
		this.root:update()
	end
	this.linesContainer = nil
end

---@private
function this.onLockpickingEnded()
	this.clearLines()
	this.root = nil
end

return this
