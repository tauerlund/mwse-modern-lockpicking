---@class initializer
local this = {}

---@private
---@type mwseLogger
this.logger = mwse.Logger.new()

---@private
---@type serviceCollection
this.services = nil

---@public
---@param services serviceCollection
---@param initializedServices initializedService[]
function this.initialize(services, initializedServices)
    this.services = services

    this.logger:info("Initializing...")

    this.assignServiceNames()

    local success, reason = this.initializeServices(initializedServices)

    if not success then
        this.logger:error("Initialization failed. Reason: %s", reason)
        this.uninitializeServices(initializedServices)
        return
    end

    this.logger:info("Initialized.")
end

---@private
function this.assignServiceNames()
    local services = this.services
    local unnamed = services.unnamedServices and services.unnamedServices() or {}

    for name, service in pairs(services) do
        if type(service) ~= "table" then
            this.logger:debug("'%s' is not a table - skipping name assignment", name)
        elseif table.contains(unnamed, service) then
            this.logger:debug("'%s' is unnamed - skipping name assignment", name)
        elseif service.name ~= nil then
            this.logger:warn("'%s' already has a service name assigned (%s)", name, service.name)
        else
            service.name = name
        end
    end
end

---@private
---@param initializedServices initializedService[]
---@return boolean, reason
function this.initializeServices(initializedServices)
    for _, service in ipairs(initializedServices) do
        if service.dependencies then
            local dependencies = service.dependencies(this.services)
            for _, dependency in ipairs(dependencies) do
                if not dependency.initialized then
                    return false, string.format("'%s' must be initialized before '%s'", dependency.name, service.name)
                end
            end
        end

        service.initialized = false

        local success, reason = service.initialize(this.services)
        if not success then
            return false, string.format("'%s' could not be initialized because %s", service.name, reason)
        end

        service.initialized = true
    end

    return true, nil
end

---@private
---@param initializedServices initializedService[]
function this.uninitializeServices(initializedServices)
    for _, service in ipairs(initializedServices) do
        if service.initialized and service.uninitialize then
            service.uninitialize()
        end
    end
end

return this
