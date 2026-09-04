---@class knifeSpawner : initializedService
local this = {}

---@private
---@type enums
this.enums = nil

---@private
---@type inventoryController
this.inventoryController = nil

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
	this.enums = services.enums
	this.inventoryController = services.inventoryController
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
---@param lock lock
---@return knife
function this.spawn(lock)
	local knife = this.getMesh()
	local helper = lock.mesh:getObjectByName(this.enums.objectNames.knifeHelper) --[[@as niNode]]

	helper:attachChild(knife)

	knife:updateProperties()
	knife:updateEffects()
	knife:update()

	helper:update()

	return knife
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	local knifeHelper = e.session.lock.mesh:getObjectByName(this.enums.objectNames.knifeHelper) --[[@as niNode]]
	knifeHelper:detachChild(e.session.knife)
end

---@public
---@return niNode
function this.getMesh()
	local mesh = tes3.loadMesh(this.resolveMeshPath(), true):clone() --[[@as niNode]]

	mesh.name = this.enums.objectNames.knife
	mesh:attachProperty(this.getZBufferProperty())

	return mesh
end

---@private
---@return string
function this.resolveMeshPath()
	local default = this.enums.constants.knives.paths.daggerMesh
	local knife = this.inventoryController.getBestKnife()

	if not knife then
		return default
	end

	local mesh = knife.object.mesh
	if not mesh or mesh == "" then
		return default
	end

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
