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
---@type tes3itemStack[]
this.picks = nil

---@private
---@type lock
this.lock = nil

---@private
---@type pick
this.currentPick = nil

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
	this.picks = e.session.picks
	this.lock = e.session.lock
	this.currentPick = e.session.pick
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.picks = nil
	this.lock = nil
	this.currentPick = nil
end

---@private
---@param e pickCycleRequestedEventData
function this.onPickCycleRequested(e)
	local previousPick = this.currentPick

	local item = pickSelector.select(this.picks, e.direction)
	local pick = pickSpawner.spawn(this.lock, item)
	this.currentPick = pick

	---@type pickCycledEventData
	local eventData = {
		previousPick = previousPick,
		pick = pick,
	}
	event.trigger(EVENTS.pickCycled, eventData)
end

return this
