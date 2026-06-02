---@class pickSpawner : initializedService
local this = {}

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.enums = services.enums
	local events = services.enums.events

	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	event.register(events.pickCycled, this.onPickCycled)

	return true, nil
end

---@public
---@param lock lock
---@param pickItem tes3itemStack
---@return pick
function this.spawn(lock, pickItem)
	local pick = this.getMesh(pickItem.object --[[@as tes3lockpick]])
	local helper = lock.mesh:getObjectByName(this.enums.objectNames.pickHelper) --[[@as niNode]]

	helper:attachChild(pick)

	pick:updateProperties()
	pick:updateEffects()
	pick:update()

	helper:update()

	return {
		mesh = pick,
		item = pickItem,
		helper = helper,
	}
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	this.despawn(e.session.pick)
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	if not e.previousPick then
		return
	end
	this.despawn(e.previousPick)
end

---@public
---@param pick tes3lockpick
---@return niNode
function this.getMesh(pick)
	local mesh = tes3.loadMesh(pick.mesh, true):clone() --[[@as niNode]]

	mesh.name = this.enums.objectNames.pick
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

---@private
---@param pick pick
function this.despawn(pick)
	pick.helper:detachChild(pick.mesh)
end

return this
