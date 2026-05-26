--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.timers.enums.CONSTANTS")
---

---@class timerManager
local this = {}

---@package
---@class timerDataInner : timerData
---@field package callback fun(callbackData:mwseTimerCallbackData)?
---@field package finishedCallback fun(data:timerData)?
---@field package cancellationEvents { [string]: function }

---@public
---@param parameters timerParameters
---@return mwseTimer
function this.start(parameters)
	local data = parameters.data or {}

	---@cast data +timerDataInner, -timerData

	data.totalIterations = math.floor(parameters.durationInSeconds / CONSTANTS.tick)
	data.callback = parameters.callback
	data.finishedCallback = parameters.finishedCallback
	data.cancellationEvents = {}

	local timer = timer.start({
		type = timer.real,
		iterations = data.totalIterations,
		duration = CONSTANTS.tick,
		callback = this.callbackInner,
		---@type timerDataInner
		data = data,
	})

	if parameters.cancelOn then
		this.registerCancellationEvents(parameters.cancelOn, data, timer)
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
---@param events string|string[]
---@param data timerDataInner
---@param timer mwseTimer
function this.registerCancellationEvents(events, data, timer)
	if type(events) == "string" then
		this.registerCancellationEvent(events, data, timer)
		return
	end

	for _, event in pairs(events) do
		this.registerCancellationEvent(event, data, timer)
	end
end

---@private
---@param evt string
---@param data timerDataInner
---@param t mwseTimer
function this.registerCancellationEvent(evt, data, t)
	data.cancellationEvents[evt] = function ()
		if not t or not t.state == timer.active then
			return
		end
		t:cancel()
		this.unregisterCancellationEvents(data)
	end
	event.register(evt, data.cancellationEvents[evt], { doOnce = true })
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
