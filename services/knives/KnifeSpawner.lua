local KnifeAnimator = require("tauer.modern-lockpicking.services.knives.KnifeAnimator")
local zBufferIndex = require("tauer.modern-lockpicking.shared.enums.zBufferIndex")

local objectNames = require("tauer.modern-lockpicking.shared.enums.objectNames")
local paths = require("tauer.modern-lockpicking.shared.enums.paths")
local events = require("tauer.modern-lockpicking.shared.enums.event")

---@class KnifeSpawner
local this = {}

-- TODO Remove when debugging is not needed anymore
---@private
---@type niNode
this.knife = nil

---@private
---@type tes3vector3
this.knifeRotation = tes3vector3.new(-1.07, -1.23, 1.04)

---@public
---@param lock lock
function this.Spawn(lock)
	local knife = this.getMesh()
	local helper = lock.mesh:getObjectByName(objectNames.knifeHelper) --[[@as niNode]]

	helper:attachChild(knife)

	knife:updateProperties()
	knife:updateEffects()
	knife:update()

	helper:update()

	KnifeAnimator.Play(knife)

	lock.knife = knife

	this.registerEvents()
end

---@public
---@return niNode
function this.getMesh()
	local mesh = tes3.loadMesh(paths.daggerMesh, true):clone() --[[@as niNode]]

	mesh.name = objectNames.knife
	mesh.rotation = this.getRotation(mesh)
	-- mesh.translation = this.getTranslation(mesh)
	mesh:attachProperty(this.getZBufferProperty())

	return mesh
end

---@private
---@param mesh niNode
---@return tes3matrix33
function this.getRotation(mesh)
	local rotation = tes3matrix33.new()
	rotation:fromEulerXYZ(this.knifeRotation.x, this.knifeRotation.y, this.knifeRotation.z)
	return rotation
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
