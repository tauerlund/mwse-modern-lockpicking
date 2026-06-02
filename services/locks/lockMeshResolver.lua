--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.locks.enums.CONSTANTS")
---

---@class lockMeshResolver : initializedService
local this = {}

---@private
---@type niNode
this.defaultMesh = nil

---@private
---@type { [string]: niNode }
this.meshes = {}

---@public
---@param _ serviceCollection
---@return boolean,string|nil
function this.initialize(_)
	this.defaultMesh = tes3.loadMesh(CONSTANTS.paths.defaultLockMesh, true):clone() --[[@as niNode]]
	return true, nil
end

---@public
---@param activator tes3reference
---@return niNode
function this.resolve(activator)
	return this.meshes[activator.mesh] or this.defaultMesh
end

return this
