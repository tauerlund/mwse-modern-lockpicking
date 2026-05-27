--- SERVICES
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm
local pickSelector = require("tauer.modern-lockpicking.services.picks.pickSelector")
local pickSpawner = require("tauer.modern-lockpicking.services.picks.pickSpawner")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local CYCLE = require("tauer.modern-lockpicking.services.lockpicking.enums.CYCLE_DIRECTION")
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

---@private
---@type { [tes3.scanCode]: CYCLE_DIRECTION }
this.pickCycleDirections = nil

---@public
---@return boolean,string|nil
function this.initialize()
	this.applyKeybinds()
	event.register(EVENTS.keyBindsUpdated, this.onKeyBindsUpdated)
	event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	return true, nil
end

---@private
function this.onKeyBindsUpdated()
	this.applyKeybinds()
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.picks = e.session.picks
	this.lock = e.session.lock
	this.currentPick = e.session.pick
	this.enable()
end

---@private
---@param _ lockpickingEndEventData
function this.onLockpickingEnd(_)
	this.disable()
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.disable()
	this.picks = nil
	this.lock = nil
	this.currentPick = nil
end

---@private
function this.enable()
	if not event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.register(tes3.event.keyDown, this.onKeyDown)
	end
end

---@private
function this.disable()
	if event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.unregister(tes3.event.keyDown, this.onKeyDown)
	end
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if this.pickCycleDirections[e.keyCode] then
		this.cyclePick(this.pickCycleDirections[e.keyCode])
	end
end

---@private
---@param direction CYCLE_DIRECTION
function this.cyclePick(direction)
	local previousPick = this.currentPick

	local item = pickSelector.select(this.picks, direction)
	local pick = pickSpawner.spawn(this.lock, item)
	this.currentPick = pick

	---@type pickCycledEventData
	local eventData = {
		previousPick = previousPick,
		pick = pick,
	}
	event.trigger(EVENTS.pickCycled, eventData)
end

---@private
function this.applyKeybinds()
	this.pickCycleDirections = {
		[settings.keyBinds.cycleNextPick.keyCode] = CYCLE.next,
		[settings.keyBinds.cyclePreviousPick.keyCode] = CYCLE.previous,
	}
end

return this
