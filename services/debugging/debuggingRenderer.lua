---@class debuggingRenderer : initializedService
local this = {}

---@private
---@type niNode|nil
this.root = nil

---@private
---@type niNode|nil
this.linesContainer = nil

---@private
---@type settings
this.settings = nil

---@private
---@type enums
this.enums = nil

---@private
---@type number
this.lineLength = 0.5

---@private
---@type number
this.defaultMeshLength = 1000

---@private
---@type eventHandlers
this.eventHandlers = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type lockpickingSession
this.session = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.eventRegistrar = services.eventRegistrar
	this.settings = services.settings
	this.enums = services.enums

	local events = services.enums.events

	this.eventHandlers = {
		[events.lockpickingStarted] = this.onLockpickingStarted,
		[events.sweetSpotUpdated] = this.onSweetSpotUpdated,
		[events.lockpickingEnded] = this.onLockpickingEnded,
	}

	this.eventRegistrar.register(this.eventHandlers)

	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.session = e.session
	this.root = e.session.lock.mesh
end

---@private
---@param e sweetSpotUpdatedEventData
function this.onSweetSpotUpdated(e)
	this.clearLines()
	if not this.root or not this.settings.debugging.showSweetSpotRenderer then
		return
	end

	this.linesContainer = niNode.new()
	this.linesContainer.translation = this.session.lock.cylinder.translation:copy()

	local property = niZBufferProperty.new()
	property:setFlag(true, this.enums.zBufferIndex.test)
	property:setFlag(true, this.enums.zBufferIndex.write)
	property.testFunction = ni.zBufferPropertyTestFunction.always
	this.linesContainer:attachProperty(property)
	this.linesContainer:updateProperties()

	this.root:attachChild(this.linesContainer)

	local constants = this.enums.constants.cylinder
	local function clamp(angle)
		return math.clamp(angle, constants.targetRotationLeft, constants.targetRotationRight)
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
	line.scale = this.lineLength / this.defaultMeshLength

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
