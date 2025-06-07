--- ENUMS
local Z_BUFFER_INDEX = require("tauer.modern-lockpicking.shared.enums.zBufferIndex")
local OBJECT_NAMES = require("tauer.modern-lockpicking.shared.enums.objectNames")
local PATHS = require("tauer.modern-lockpicking.shared.enums.paths")
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
---

---@class KnifeSpawner
local this = {}

---@public
---@param lock lock
function this.Spawn(lock)
	lock.knife = this.spawn(lock)
	this.registerEvents()
end

---@private
---@param lock lock
---@return knife
function this.spawn(lock)
	local knife = this.getMesh()
	local helper = lock.mesh:getObjectByName(OBJECT_NAMES.knifeHelper) --[[@as niNode]]

	helper:attachChild(knife)

	knife:updateProperties()
	knife:updateEffects()
	knife:update()

	helper:update()

	return knife
end

---@public
---@return niNode
function this.getMesh()
	local mesh = tes3.loadMesh(PATHS.daggerMesh, true):clone() --[[@as niNode]]

	mesh.name = OBJECT_NAMES.knife
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
	local lock = e.lock

	local knifeHelper = lock.mesh:getObjectByName(OBJECT_NAMES.knifeHelper) --[[@as niNode]]
	knifeHelper:detachChild(lock.knife)

	this.unregisterEvents()
end

---@private
function this.registerEvents()
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
end

---@private
function this.unregisterEvents()
	if event.isRegistered(EVENTS.lockpickingEnded, this.onLockpickingEnded) then
		event.unregister(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	end
end

return this
