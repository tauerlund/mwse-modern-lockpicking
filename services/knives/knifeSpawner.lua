--- ENUMS
local Z_BUFFER_INDEX = require("tauer.modern-lockpicking.shared.enums.zBufferIndex")
local OBJECT_NAMES = require("tauer.modern-lockpicking.shared.enums.objectNames")
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local COSNTANTS = require("tauer.modern-lockpicking.services.knives.enums.constants")
---

---@class knifeSpawner
local this = {}

---@public
---@param lock lock
---@return knife
function this.Spawn(lock)
	this.registerEvents()

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
	local mesh = tes3.loadMesh(COSNTANTS.paths.daggerMesh, true):clone() --[[@as niNode]]

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
	local knife = e.knife

	local knifeHelper = lock.mesh:getObjectByName(OBJECT_NAMES.knifeHelper) --[[@as niNode]]
	knifeHelper:detachChild(knife)
end

---@private
function this.registerEvents()
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
end

return this
