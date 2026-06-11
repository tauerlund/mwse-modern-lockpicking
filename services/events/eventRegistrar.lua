---Provides abstractions for safely registering and unregistering multiple event handlers
---@class eventRegistrar : service
local this = {}

---@private
this.logger = mwse.Logger.new()

---Registers a collection of event handlers
---@public
---@param handlers eventHandlers The handlers to register
---@see event.register
---@see event.register.options
function this.register(handlers)
    for evt, entry in pairs(handlers) do
        local handler, options = this.resolveEntry(entry)

        if handler then
            if not event.isRegistered(evt, handler, options) then
                event.register(evt, handler, options)
            else
                this.logger:debug("Attempted to register handler for '%s' that is already registered", evt)
            end
        end
    end
end

---Unregisters a collection of event handlers
---@public
---@param handlers eventHandlers The handlers to unregister
---@see event.unregister
function this.unregister(handlers)
    for evt, entry in pairs(handlers) do
        local handler, options = this.resolveEntry(entry)

        if handler then
            if event.isRegistered(evt, handler, options) then
                event.unregister(evt, handler, options)
            else
                this.logger:debug("Attempted to unregister handler for '%s' that is already unregistered", evt)
            end
        end
    end
end

---@private
---@param entry callback|callbackWithOptions
---@return callback?, table?
function this.resolveEntry(entry)
    local entryType = type(entry)

    if entryType == "function" then
        return entry, nil
    elseif entryType == "table" then
        local handler = this.resolveType(entry[1], "function")
        local options = this.resolveType(entry[2], "table")

        return handler, options
    end

    this.logger:error("Invalid type '%s'", entryType)
end

---@generic T
---@private
---@param entry any
---@param expected `T`
---@return T|nil
function this.resolveType(entry, expected)
    if entry and type(entry) == expected then
        return entry
    end
    return nil
end

return this
