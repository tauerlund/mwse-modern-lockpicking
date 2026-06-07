---@class lockMeshLoader : initializedService
local this = {}

---@private
---@type string
this.fullPath = "data files\\mwse\\config\\modern-lockpicking\\meshes\\"

---@private
---@type string
this.relativePath = "modern-lockpicking\\meshes\\"

---@private
---@type fileHelper
this.fileHelper = nil

---@private
---@type enums
this.enums = nil

---@private
this.logger = mwse.Logger.new()

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
    this.fileHelper = services.fileHelper
    this.enums = services.enums

    return true, nil
end

---@public
---@return { [string]: string }|nil
function this.loadAll()
    local files = this.fileHelper.getAllFilesInDirectory(this.fullPath, this.enums.fileTypes.json)
    if not files then
        return nil
    end

    local configurations = this.loadConfigurations(files)

    return this.loadMeshes(configurations)
end

---@private
---@param files string[]
---@return lockMeshConfiguration[]
function this.loadConfigurations(files)
    local configurations = {}

    for _, file in ipairs(files) do
        local path = string.format("%s\\%s", this.relativePath, this.removeExtension(file))
        local configuration = mwse.loadConfig(path) --[[@as lockMeshConfiguration]]
        if configuration then
            table.insert(configurations, configuration)
        else
            this.logger:warn("Configuration at '%s' not valid", file)
        end
    end

    return configurations
end

---@private
---@param configurations lockMeshConfiguration[]
---@return { [string]: string }
function this.loadMeshes(configurations)
    ---@type { [string]: string }
    local meshes = {}

    for _, configuration in ipairs(configurations) do
        for _, entry in ipairs(configuration) do
            for _, activator in ipairs(entry.activatorMeshes) do
                if meshes[activator] then
                    this.logger:warn("Activator '%s' already has lock mesh assigned, will be overwritten", activator)
                end
                meshes[activator] = entry.lockMesh
            end
        end
    end

    return meshes
end

---@private
---@param filePath string
function this.removeExtension(filePath)
    return string.gsub(filePath, this.enums.fileTypes.json, "")
end

return this
