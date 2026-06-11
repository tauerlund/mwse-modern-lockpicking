--- Generic class responsible for loading strategy implementations from Lua files.
---@class strategyLoader : initializedService
local this = {}

---@private
this.logger = mwse.Logger.new()

---@private
---@type serviceCollection
this.services = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
    this.services = services
    return true, nil
end

--- Loads all strategy implementations from the specified directory.
---@public
---@param params strategyLoader.loadAll.params The parameters for loading the strategies.
---@return { [string]: strategy }|nil strategies The loaded strategies, indexed by their name, or nil if an error occurred during loading.
function this.loadAll(params)
    local path = string.format("data files\\mwse\\mods\\%s", params.directory)

    local files = this.services.fileHelper.getAllFilesInDirectory(path, this.services.enums.fileTypes.lua)
    if not files then
        if params.requireNotEmpty then
            this.logger:error("No strategies found in directory '%s'.", params.directory)
            return nil
        end
        return {}
    end

    ---@type { [string]: strategy }
    local strategies = {}

    for _, file in pairs(files) do
        local strategy, reason = this.load(file, params.directory)
        if not strategy then
            this.logger:error("Strategy file '%s' could not be loaded: %s", file, reason or "unknown")
            return nil
        end

        local validator = params.validator

        if validator then
            local valid, validationReason = validator.validate(strategy)
            if not valid then
                this.logger:error("Strategy '%s' invalid! Reason: %s.", file, validationReason or "unknown")
                return nil
            end
        end

        strategy.initialize(this.services)

        if not strategy.name then
            this.logger:error("Strategy file '%s' did not set a name during initialization.", file)
            return nil
        end

        strategies[strategy.name] = strategy
    end

    if params.requireNotEmpty and table.size(strategies) == 0 then
        this.logger:error("No strategies found in directory '%s'.", params.directory)
        return nil
    end

    return strategies
end

---@private
---@param file string
---@param directory string
---@return strategy|nil strategy, string|nil reason
function this.load(file, directory)
    local packageDirectory = directory:gsub("\\", ".")
    local packageName = this.removeExtension(file)

    local package = string.format("%s.%s", packageDirectory, packageName)

    local success, result = pcall(require, package)
    if not success then
        return nil, result
    end

    if type(result) ~= "table" or type(result.initialize) ~= "function" then
        return nil, "file did not return a strategy table with an 'initialize' function"
    end

    return result, nil
end

---@private
---@param filePath string
function this.removeExtension(filePath)
    return filePath:gsub(string.format("%%%s$", this.services.enums.fileTypes.lua), "")
end

return this
