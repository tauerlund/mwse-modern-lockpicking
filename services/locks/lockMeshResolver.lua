---@class lockMeshResolver : initializedService
local this = {}

---@public
---@type fun(service:serviceCollection):initializedService[]
this.dependencies = function (services)
	return { services.lockMeshLoader }
end

---@private
---@type niNode
this.defaultMesh = nil

---@private
---@type { [string]: string }
this.meshes = {}

---@private
---@type lockMeshLoader
this.lockMeshLoader = nil

---@private
---@type lockMeshValidator
this.lockMeshValidator = nil

---@private
---@type enums
this.enums = nil

---@private
---@type mwseLogger
this.logger = mwse.Logger.new()

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.lockMeshLoader = services.lockMeshLoader
	this.lockMeshValidator = services.lockMeshValidator
	this.enums = services.enums

	local meshes = this.lockMeshLoader.loadAll()
	if not meshes then
		return false, "lock meshes could not be loaded"
	end

	this.meshes = meshes

	return true, nil
end

---@public
---@param activator tes3reference
---@return niNode
function this.resolve(activator)
	local meshPath = this.meshes[activator.mesh]

	if meshPath then
		local mesh = tes3.loadMesh(meshPath, true):clone() --[[@as niNode]]

		local valid, reason = this.lockMeshValidator.validate(mesh)
		if valid then
			return mesh
		end

		this.logger:warn("Mesh '%s' is invalid: %s", meshPath, reason)
	end

	return this.loadDefaultMesh()
end

---@private
---@return niNode
function this.loadDefaultMesh()
	return tes3.loadMesh(this.enums.constants.locks.paths.defaultLockMesh, true):clone() --[[@as niNode]]
end

return this
