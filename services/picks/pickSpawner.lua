--- ENUMS
local Z_BUFFER_INDEX = require("tauer.modern-lockpicking.shared.enums.zBufferIndex")
local OBJECT_NAMES = require("tauer.modern-lockpicking.shared.enums.objectNames")
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
---

---@class pickSpawner
local this = {}

---@public
---@param lock lock
---@param pickItem tes3itemStack
---@return pick
function this.Spawn(lock, pickItem)
	this.registerEvents()

	local pick = this.getMesh(pickItem.object --[[@as tes3lockpick]])
	local helper = lock.mesh:getObjectByName(OBJECT_NAMES.pickHelper) --[[@as niNode]]

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

---@public
---@param pick tes3lockpick
---@return niNode
function this.getMesh(pick)
	local mesh = tes3.loadMesh(pick.mesh, true):clone() --[[@as niNode]]

	mesh.name = OBJECT_NAMES.pick
	mesh:attachProperty(this.getZBufferProperty())

	return mesh
end

---@private
---@return niZBufferProperty
function this.getZBufferProperty()
	local property = niZBufferProperty.new()

	property:setFlag(true, Z_BUFFER_INDEX.test)
	property:setFlag(true, Z_BUFFER_INDEX.write)

	return property
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	this.despawn(e.pick)
end

---@private
---@param e pickChangeEventData
function this.onPickChange(e)
	this.despawn(e.pick)
end

---@private
---@param pick pick
function this.despawn(pick)
	pick.helper:detachChild(pick.mesh)
	this.unregisterEvents()
end

---@private
function this.registerEvents()
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	event.register(EVENTS.pickChange, this.onPickChange)
end

---@private
function this.unregisterEvents()
	if event.isRegistered(EVENTS.lockpickingEnded, this.onLockpickingEnded) then
		event.unregister(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	end
	if event.isRegistered(EVENTS.pickChange, this.onPickChange) then
		event.unregister(EVENTS.pickChange, this.onPickChange)
	end
end

return this
