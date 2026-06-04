---@class lockMeshResolver : initializedService
local this = {}

---@private
---@type niNode
this.defaultMesh = nil

---@private
---@type { [string]: niNode }
this.meshes = {}

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	if services.lockMeshValidator.initalized == false then
		return false, "lockMeshValidator must be initialized before lockMeshResolver"
	end

	local constants = services.enums.constants.locks
	this.defaultMesh = tes3.loadMesh(constants.paths.defaultLockMesh, true):clone() --[[@as niNode]]
	return true, nil
end

---@public
---@param activator tes3reference
---@return niNode
function this.resolve(activator)
	return this.meshes[activator.mesh] or this.defaultMesh
end

return this
