local LockMeshResolver = require("tauer.modern-lockpicking.services.locks.LockMeshResolver")
local zBufferIndex = require("tauer.modern-lockpicking.shared.enums.zBufferIndex")

local events = require("tauer.modern-lockpicking.shared.enums.event")

---@class LockSpawner
local this = {}

---@public
---@param container tes3containerInstance
---@return lock
function this.Spawn(container)
	local mesh = this.getMesh(container)
	local root = this.getRootNode()

	root:attachChild(mesh)

	mesh:updateProperties()
	mesh:updateEffects()
	mesh:update()

	root:update()

	event.register(events.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })

	return {
		mesh = mesh,
		cylinder = mesh:getObjectByName("ModernLockpicking:CylinderHelper"),
		container = container,
	}
end

---@private
---@param container tes3containerInstance
---@return niNode
function this.getMesh(container)
	local mesh = LockMeshResolver.Resolve(container)

	mesh.name = "ModernLockpicking:Root"
	mesh.translation = tes3.getCameraPosition():copy()
	mesh.rotation = this.getLockRotation(mesh)
	mesh:attachProperty(this.getZBufferProperty())

	return mesh
end

---@private
---@return niNode
function this.getRootNode()
	return tes3.worldController.vfxManager.worldVFXRoot
end

---@private
---@param mesh niNode
---@return tes3matrix33
function this.getLockRotation(mesh)
	local rotation = mesh.rotation:copy()

	local forward = tes3.getCameraVector():copy()
	local up = tes3vector3.new(0, 0, 1)

	rotation:lookAt(forward, up)

	return rotation
end

---@private
---@return niZBufferProperty
function this.getZBufferProperty()
	local property = niZBufferProperty.new()

	property:setFlag(false, zBufferIndex.test)
	property:setFlag(true, zBufferIndex.write)
	property.testFunction = ni.zBufferPropertyTestFunction.always

	return property
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	local root = this.getRootNode()
	root:detachChild(e.lock.mesh)
end

return this
