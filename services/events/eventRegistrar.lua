---Provides abstractions for safely registering and unregistering multiple event handlers
---@class eventRegistrar : service
local this = {}

---@private
this.logger = mwse.Logger.new()

---Registers a collection of event handlers
---@public
---@param handlers eventHandlers The handlers to register
---@param options? event.register.options Options that apply to all the handlers. **Optional**.
---@see event.register
---@see event.register.options
function this.register(handlers, options)
    for evt, handler in pairs(handlers) do
        if not event.isRegistered(evt, handler) then
            event.register(evt, handler, options)
        else
            this.logger:debug("Attempted to register handler for '%s' that is already registered", evt)
        end
    end
end

---Unregisters a collection of event handlers
---@public
---@param handlers eventHandlers The handlers to unregister
---@see event.unregister
function this.unregister(handlers)
    for evt, handler in pairs(handlers) do
        if event.isRegistered(evt, handler) then
            event.unregister(evt, handler)
        else
            this.logger:debug("Attempted to unregister handler for '%s' that is already unregistered", evt)
        end
    end
end

return this
