--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.timers.enums.constants")
---

---@class TimerHelper
local this = {}

---@package
---@class timerDataInner : timerData
---@field package callback fun(callbackData:mwseTimerCallbackData)?
---@field package finishedCallback fun(configuration:timerData)?

---@public
---@param parameters timerParameters
function this.Start(parameters)
	local data = parameters.data or {}

	---@cast data +timerDataInner, -timerData

	data.totalIterations = math.floor(parameters.durationInSeconds / CONSTANTS.tick)
	data.callback = parameters.callback
	data.finishedCallback = parameters.finishedCallback

	timer.start({
		type = timer.real,
		iterations = data.totalIterations,
		duration = CONSTANTS.tick,
		callback = this.callbackInner,
		---@type timerDataInner
		data = data,
	})
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

return this
