---@class timerManager
local this = {}

---@public
---@param params timerManager.start.params
---@return mwseTimer
function this.start(params)
	local cancellationHandlers = {}

	local t
	t = timer.start({
		type = timer.real,
		iterations = 1,
		duration = params.durationInSeconds,
		callback = function ()
			this.unregisterCancellationEvents(cancellationHandlers)
			if params.callback then
				params.callback(params.data)
			end
		end,
	})

	if params.cancelOn then
		this.registerCancellationEvents(params.cancelOn, cancellationHandlers, t)
	end

	return t
end

---@private
---@param events string[]
---@param handlers { [string]: function }
---@param t mwseTimer
function this.registerCancellationEvents(events, handlers, t)
	for _, evt in ipairs(events) do
		handlers[evt] = function ()
			if not t or not t.state == timer.active then
				return
			end
			t:cancel()
			this.unregisterCancellationEvents(handlers)
		end
		event.register(evt, handlers[evt], { doOnce = true })
	end
end

---@private
---@param handlers { [string]: function }
function this.unregisterCancellationEvents(handlers)
	for evt, callback in pairs(handlers) do
		if event.isRegistered(evt, callback) then
			event.unregister(evt, callback)
		end
	end
end

return this
