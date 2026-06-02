---@class knifeSpawner : initializedService
local this = {}

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.enums = services.enums
	local events = services.enums.events

	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	return true, nil
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
	local mesh = tes3.loadMesh(this.enums.constants.knives.paths.daggerMesh, true):clone() --[[@as niNode]]

	mesh.name = this.enums.objectNames.knife
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
