local zBufferIndex = require("tauer.modern-lockpicking.shared.enums.zBufferIndex")
local objectNames = require("tauer.modern-lockpicking.shared.enums.objectNames")
local paths = require("tauer.modern-lockpicking.shared.enums.paths")
local events = require("tauer.modern-lockpicking.shared.enums.event")

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
---@return niNode
function this.spawn(lock)
	local knife = this.getMesh()
	local helper = lock.mesh:getObjectByName(objectNames.knifeHelper) --[[@as niNode]]

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
	local mesh = tes3.loadMesh(paths.daggerMesh, true):clone() --[[@as niNode]]

	mesh.name = objectNames.knife
	mesh:attachProperty(this.getZBufferProperty())

	return mesh
end

---@private
---@param mesh niNode
function this.getTranslation(mesh)
	local translation = mesh.translation:copy()

	local distance = -16
	local forward = mesh.rotation:getForwardVector() * distance

	return translation + forward
end

---@private
---@return niZBufferProperty
function this.getZBufferProperty()
	local property = niZBufferProperty.new()

	property:setFlag(true, zBufferIndex.test)
	property:setFlag(true, zBufferIndex.write)

	return property
end

---@private
function this.registerEvents()
	event.register(events.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
end

---@private
function this.unregisterEvents()
	if event.isRegistered(events.lockpickingEnded, this.onLockpickingEnded) then
		event.unregister(events.lockpickingEnded, this.onLockpickingEnded)
	end
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	local lock = e.lock

	local knifeHelper = lock.mesh:getObjectByName(objectNames.knifeHelper) --[[@as niNode]]
	knifeHelper:detachChild(lock.knife)

	this.unregisterEvents()
end

return this
