local lockMeshResolver = require("tauer.modern-lockpicking.services.locks.lockMeshResolver")
local zBufferIndex = require("tauer.modern-lockpicking.shared.enums.zBufferIndex")

local objectNames = require("tauer.modern-lockpicking.shared.enums.objectNames")
local events = require("tauer.modern-lockpicking.shared.enums.events")

---@class lockSpawner
local this = {}

---@public
---@param activator tes3containerInstance|tes3door
---@return lock
function this.spawn(activator)
	local mesh = this.spawnMesh(activator)

	event.register(events.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })

	return {
		mesh = mesh,
		cylinder = mesh:getObjectByName(objectNames.cylinderHelper),
		container = activator,
	}
end

---@private
---@param activator tes3containerInstance|tes3door
---@return niNode
function this.spawnMesh(activator)
	local mesh = this.getMesh(activator)
	local root = this.getRootNode()

	root:attachChild(mesh)

	mesh:updateProperties()
	mesh:updateEffects()
	mesh:update()

	root:update()

	return mesh
end

---@private
---@param activator tes3containerInstance|tes3door
---@return niNode
function this.getMesh(activator)
	local mesh = lockMeshResolver.resolve(activator)

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
