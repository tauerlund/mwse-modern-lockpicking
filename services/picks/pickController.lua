--- SERVICES
local pickSelector = require("tauer.modern-lockpicking.services.picks.pickSelector")
local pickSpawner = require("tauer.modern-lockpicking.services.picks.pickSpawner")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

---@class pickController : initializedService
local this = {}

---@private
---@type lockpickingSession
this.session = nil

---@public
---@return boolean,string|nil
function this.initialize()
	event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	event.register(EVENTS.pickCycleRequested, this.onPickCycleRequested)
	return true, nil
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.session = e.session
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.session = nil
end

---@private
---@param e pickCycleRequestedEventData
function this.onPickCycleRequested(e)
	local previousPick = this.session.pick

	local item = pickSelector.select(this.session.picks, e.direction)
	local pick = pickSpawner.spawn(this.session.lock, item)

	---@type pickCycledEventData
	local eventData = {
		previousPick = previousPick,
		pick = pick,
	}
	event.trigger(EVENTS.pickCycled, eventData)
end

return this
