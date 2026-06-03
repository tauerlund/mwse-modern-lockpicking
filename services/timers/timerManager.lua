---@class timerManager : initializedService
local this = {}

---@package
---@class timerDataInner : timerData
---@field package callback fun(callbackData:mwseTimerCallbackData)?
---@field package finishedCallback fun(data:timerData)?
---@field package cancellationEvents { [string]: function }

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.enums = services.enums
	return true, nil
end

---@public
---@param params timerManager.start.params
---@return mwseTimer
function this.start(params)
	local constants = this.enums.constants.timers
	local data = params.data or {}

	---@cast data +timerDataInner, -timerData

	data.totalIterations = math.floor(params.durationInSeconds / constants.tick)
	data.callback = params.callback
	data.finishedCallback = params.finishedCallback
	data.cancellationEvents = {}

	local timer = timer.start({
		type = timer.real,
		iterations = data.totalIterations,
		duration = constants.tick,
		callback = this.callbackInner,
		---@type timerDataInner
		data = data,
	})

	if params.cancelOn then
		this.registerCancellationEvents(params.cancelOn --[[@as string[] ]], data, timer)
	end

	return timer
end

---@private
---@param callback mwseTimerCallbackData
function this.callbackInner(callback)
	local data = callback.timer.data --[[@as timerDataInner]]

	if data.callback then
		data.callback(callback)
	end

	if callback.timer.iterations == 1 and data.finishedCallback then
		this.unregisterCancellationEvents(data)
		data.finishedCallback(data)
	end
end

---@private
---@param events string[]
---@param data timerDataInner
---@param t mwseTimer
function this.registerCancellationEvents(events, data, t)
	for _, evt in ipairs(events) do
		data.cancellationEvents[evt] = function ()
			if not t or not t.state == timer.active then
				return
			end
			t:cancel()
			this.unregisterCancellationEvents(data)
		end
		event.register(evt, data.cancellationEvents[evt], { doOnce = true })
	end
end

---@private
---@param data timerDataInner
function this.unregisterCancellationEvents(data)
	for evt, callback in pairs(data.cancellationEvents) do
		if event.isRegistered(evt, callback) then
			event.unregister(evt, callback)
		end
	end
end

return this
