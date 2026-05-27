--- SERVICES
local fileHelper = require("tauer.modern-lockpicking.services.files.fileHelper")
---

--- ENUMS
local FILE_TYPE = require("tauer.modern-lockpicking.services.files.enums.FILE_TYPE")
---

local logger = mwse.Logger.new()

--- Generic class responsible for loading strategy implementations from Lua files.
---@class strategyLoader
local this = {}

--- Loads all strategy implementations from the specified directory.
---@public
---@param params strategyLoader.loadAll.params The parameters for loading the strategies.
---@return { [string]: strategy }|nil strategies The loaded strategies, indexed by their name, or nil if an error occurred during loading.
function this.loadAll(params)
    local path = string.format("data files\\mwse\\mods\\%s", params.directory)

    local files = fileHelper.getAllFilesInDirectory(path, FILE_TYPE.lua)
    if not files then
        return params.requireNotEmpty and nil or {}
    end

    ---@type { [string]: strategy }
    local strategies = {}

    for _, file in pairs(files) do
        local strategy = this.load(file, params.directory)
        local validator = params.validator

        if validator then
            local valid, reason = validator.validate(strategy)
            if not valid then
                logger:error("Strategy '%s' invalid! Reason: %s.", strategy.name, reason or "unknown")
                return nil
            end
        end

        if strategy.registerEvents then
            strategy.registerEvents()
        end

        strategies[strategy.name] = strategy
    end

    if params.requireNotEmpty and table.size(strategies) == 0 then
        logger:error("No strategies found in directory '%s'.", params.directory)
        return nil
    end

    return strategies
end

---@private
---@param file string
---@param directory string
---@return strategy
function this.load(file, directory)
    local packageDirectory = directory:gsub("\\", ".")
    local packageName = file:gsub(FILE_TYPE.lua, "")

    local package = string.format("%s.%s", packageDirectory, packageName)

    return require(package)
end

return this
