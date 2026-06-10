---@class timerManager
local this = {}

---@public
---@param params timerManager.start.params
---@return mwseTimer
function this.start(params)
	local cancellationHandlers = {}
	local pauseHandlers = {}
	local resumeHandlers = {}

	local function unregisterAllEvents()
		this.unregisterEvents(cancellationHandlers)
		this.unregisterEvents(pauseHandlers)
		this.unregisterEvents(resumeHandlers)
	end

	local t
	t = timer.start({
		type = timer.real,
		iterations = 1,
		duration = params.durationInSeconds,
		callback = function ()
			unregisterAllEvents()
			if params.callback then
				params.callback(params.data)
			end
		end,
	})

	if params.cancelOn then
		this.registerCancellationEvents(params.cancelOn, cancellationHandlers, unregisterAllEvents, t)
	end

	if params.pauseOn then
		this.registerPauseEvents(params.pauseOn, pauseHandlers, t)
	end

	if params.resumeOn then
		this.registerResumeEvents(params.resumeOn, resumeHandlers, t)
	end

	return t
end

---@private
---@param events string[]
---@param handlers { [string]: function }
---@param unregisterAllEvents function
---@param t mwseTimer
function this.registerCancellationEvents(events, handlers, unregisterAllEvents, t)
	for _, evt in ipairs(events) do
		handlers[evt] = function ()
			if not t or t.state == timer.expired then
				return
			end
			t:cancel()
			unregisterAllEvents()
		end
		event.register(evt, handlers[evt], { doOnce = true })
	end
end

---@private
---@param events string[]
---@param handlers { [string]: function }
---@param t mwseTimer
function this.registerPauseEvents(events, handlers, t)
	for _, evt in ipairs(events) do
		handlers[evt] = function ()
			if t and t.state == timer.active then
				t:pause()
			end
		end
		event.register(evt, handlers[evt])
	end
end

---@private
---@param events string[]
---@param handlers { [string]: function }
---@param t mwseTimer
function this.registerResumeEvents(events, handlers, t)
	for _, evt in ipairs(events) do
		handlers[evt] = function ()
			if t and t.state == timer.paused then
				t:resume()
			end
		end
		event.register(evt, handlers[evt])
	end
end

---@private
---@param handlers { [string]: function }
function this.unregisterEvents(handlers)
	for evt, callback in pairs(handlers) do
		if event.isRegistered(evt, callback) then
			event.unregister(evt, callback)
		end
	end
end

return this
