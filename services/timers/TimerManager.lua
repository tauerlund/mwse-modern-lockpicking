--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.timers.enums.constants")
---

---@class TimerManager
local this = {}

---@package
---@class timerDataInner : timerData
---@field package callback fun(callbackData:mwseTimerCallbackData)?
---@field package finishedCallback fun(data:timerData)?

---@public
---@param parameters timerParameters
---@return mwseTimer
function this.Start(parameters)
	local data = parameters.data or {}

	---@cast data +timerDataInner, -timerData

	data.totalIterations = math.floor(parameters.durationInSeconds / CONSTANTS.tick)
	data.callback = parameters.callback
	data.finishedCallback = parameters.finishedCallback

	local timer = timer.start({
		type = timer.real,
		iterations = data.totalIterations,
		duration = CONSTANTS.tick,
		callback = this.callbackInner,
		---@type timerDataInner
		data = data,
	})

	if parameters.cancelOn then
		this.registerCancellationEvents(parameters.cancelOn, timer)
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
		data.finishedCallback(data)
	end
end

---@private
---@param events string|string[]
---@param timer mwseTimer
function this.registerCancellationEvents(events, timer)
	if type(events) == "string" then
		this.registerCancellationEvent(events, timer)
		return
	end

	for _, event in pairs(events) do
		this.registerCancellationEvent(event, timer)
	end
end

---@private
---@param evt string
---@param t mwseTimer
function this.registerCancellationEvent(evt, t)
	event.register(evt, function()
		if not t or not t.state == timer.active then
			return
		end
		t:cancel()
	end, { doOnce = true })
end

return this
