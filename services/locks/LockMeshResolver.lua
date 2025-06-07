local paths = require("tauer.modern-lockpicking.shared.enums.paths")

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
	this.defaultMesh = tes3.loadMesh(paths.defaultLockMesh, true):clone() --[[@as niNode]]
	return true
end

---@public
---@param container tes3containerInstance
---@return niNode
function this.Resolve(container)
	return this.meshes[container.mesh] or this.defaultMesh
end

return this
