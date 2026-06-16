---@class pickOverrideResolver : initializedService
local this = {}

---@private
---@type { [string]: resolvedPickOverride }
this.overrides = {}

---@private
---@type fileHelper
this.fileHelper = nil

---@private
---@type enums
this.enums = nil

---@private
this.logger = mwse.Logger.new()

---@private
this.fullPath = "data files\\mwse\\config\\modern-lockpicking\\picks"

---@private
this.relativePath = "modern-lockpicking\\picks"

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.fileHelper = services.fileHelper
	this.enums = services.enums

	this.overrides = this.loadAll()
	return true, nil
end

---@private
---@return { [string]: resolvedPickOverride }
function this.loadAll()
	if lfs.attributes(this.fullPath, "mode") ~= "directory" then
		return {}
	end

	local files = this.fileHelper.getAllFilesInDirectory(this.fullPath, this.enums.fileTypes.json)
	if not files then
		return {}
	end

	local configurations = this.loadConfigurations(files)
	return this.loadOverrides(configurations)
end

---@private
---@param files string[]
---@return pickMeshOverrideConfiguration[]
function this.loadConfigurations(files)
	local configurations = {}
	for _, file in ipairs(files) do
		local path = string.format("%s\\%s", this.relativePath, this.removeExtension(file))
		local configuration = mwse.loadConfig(path) --[[@as pickMeshOverrideConfiguration]]
		if configuration then
			table.insert(configurations, configuration)
		else
			this.logger:warn("Configuration at '%s' not valid", file)
		end
	end
	return configurations
end

---@private
---@param configurations pickMeshOverrideConfiguration[]
---@return { [string]: resolvedPickOverride }
function this.loadOverrides(configurations)
	local overrides = {}
	local priorities = {}
	for _, configuration in ipairs(configurations) do
		for _, entry in ipairs(configuration) do
			for _, meshPath in ipairs(entry.pickMeshes) do
				local key = meshPath:lower()
				local priority = entry.priority or 0
				local existingPriority = priorities[key]

				if existingPriority ~= nil and priority < existingPriority then
					-- skip: existing override has higher priority
				else
					if existingPriority ~= nil and priority == existingPriority then
						this.logger:error("Pick mesh '%s' already has an override with equal priority, will be overwritten", meshPath)
					end
					overrides[key] = this.buildOverride(entry)
					priorities[key] = priority
				end
			end
		end
	end
	return overrides
end

---@private
---@param entry pickMeshOverrideEntry
---@return resolvedPickOverride
function this.buildOverride(entry)
	return {
		rotationTarget = entry.rotationTarget and
			tes3vector3.new(
				entry.rotationTarget.x,
				entry.rotationTarget.y,
				entry.rotationTarget.z
			) or nil,
		depthOffset = entry.depthOffset,
	}
end

---@private
---@param filePath string
---@return string, integer
function this.removeExtension(filePath)
	return filePath:gsub(string.format("%%%s$", this.enums.fileTypes.json), "")
end

---@public
---@param meshPath string
---@return resolvedPickOverride
function this.resolve(meshPath)
	local override = this.overrides[meshPath:lower()]
	local constants = this.enums.constants.picks

	local rotationTarget = constants.rotation.target
	local depthOffset = constants.translation.depthOffset

	if override then
		rotationTarget = override.rotationTarget or rotationTarget
		if override.depthOffset ~= nil then
			depthOffset = override.depthOffset
		end
	end

	return { rotationTarget = rotationTarget, depthOffset = depthOffset }
end

return this
