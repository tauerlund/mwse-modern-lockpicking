local CONSTANTS = require("tauer.modern-lockpicking.services.locks.enums.constants")

---@class LockMeshResolver : IInitializedService
local this = {}

---@private
---@type niNode
this.defaultMesh = nil

---@private
---@type { [string]: niNode }
this.meshes = {}

---@public
function this.Initialize()
	this.defaultMesh = tes3.loadMesh(CONSTANTS.paths.defaultLockMesh, true):clone() --[[@as niNode]]
	return true
end

---@public
---@param activator tes3containerInstance|tes3door
---@return niNode
function this.Resolve(activator)
	return this.meshes[activator.mesh] or this.defaultMesh
end

return this
