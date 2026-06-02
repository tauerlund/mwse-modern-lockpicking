--- ENUMS
local Z_BUFFER_INDEX = require("tauer.modern-lockpicking.services.rendering.enums.Z_BUFFER_INDEX")
local OBJECT_NAMES = require("tauer.modern-lockpicking.services.nodes.enums.OBJECT_NAMES")
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

---@class pickSpawner : initializedService
local this = {}

---@public
---@param _ serviceCollection
---@return boolean,string|nil
function this.initialize(_)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	event.register(EVENTS.pickCycled, this.onPickCycled)

	return true, nil
end

---@public
---@param lock lock
---@param pickItem tes3itemStack
---@return pick
function this.spawn(lock, pickItem)
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
---@param pick pick
function this.despawn(pick)
	pick.helper:detachChild(pick.mesh)
end

return this
