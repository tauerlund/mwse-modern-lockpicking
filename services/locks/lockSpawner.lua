---@class lockSpawner : initializedService
local this = {}

---@private
---@type lockMeshResolver
this.lockMeshResolver = nil

---@private
---@type renderingStrategyController
this.renderingStrategyController = nil

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlers
this.eventHandlers = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.lockMeshResolver = services.lockMeshResolver
	this.renderingStrategyController = services.renderingStrategyController
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		[events.lockpickingEnded] = this.onLockpickingEnded,
	}

	this.eventRegistrar.register(this.eventHandlers)
	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers)
end

---@public
---@param activator tes3reference
---@return lock
function this.spawn(activator)
	local mesh = this.spawnMesh(activator)

	return {
		mesh = mesh,
		cylinder = mesh:getObjectByName(this.enums.objectNames.cylinderHelper),
		blocked = false,
		rotatingClockwise = false,
		rotatingCounterclockwise = false,
	}
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	this.renderingStrategyController.detachMesh(e.session.lock.mesh)
end

---@private
---@param activator tes3reference
---@return niNode
function this.spawnMesh(activator)
	local mesh = this.getMesh(activator)

	mesh:updateProperties()
	mesh:updateEffects()
	mesh:update()

	this.renderingStrategyController.attachMesh(mesh)

	return mesh
end

---@private
---@param activator tes3reference
---@return niNode
function this.getMesh(activator)
	local mesh = this.lockMeshResolver.resolve(activator)

	mesh.name = this.enums.constants.locks.rootName
	mesh.translation = tes3vector3.new(0, 5, 0)
	mesh.rotation = tes3matrix33.new(1, 0, 0, 0, 1, 0, 0, 0, 1)
	mesh:attachProperty(this.getZBufferProperty())

	return mesh
end

---@private
---@return niZBufferProperty
function this.getZBufferProperty()
	local property = niZBufferProperty.new()
	local zBufferIndex = this.enums.zBufferIndex

	property:setFlag(true, zBufferIndex.test)
	property:setFlag(true, zBufferIndex.write)

	return property
end

return this
