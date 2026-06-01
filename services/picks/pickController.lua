--- SERVICES
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm
local pickSelector = require("tauer.modern-lockpicking.services.picks.pickSelector")
local pickSpawner = require("tauer.modern-lockpicking.services.picks.pickSpawner")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local CYCLE = require("tauer.modern-lockpicking.services.lockpicking.enums.CYCLE_DIRECTION")
local CONSTANTS = require("tauer.modern-lockpicking.services.picks.enums.CONSTANTS")
---

---@class pickController : initializedService
local this = {}

---@private
---@type lock
this.lock = nil

---@private
---@type lockpickingSession
this.session = nil

---@private
---@type tes3itemStack[]
this.picks = nil

---@private
---@type pick
this.currentPick = nil

---@private
---@type number
this.sweetSpotRadius = nil

---@private
---@type boolean
this.damaging = false

---@private
---@type number
this.damageAccumulator = 0

---@private
---@type { [tes3.scanCode]: CYCLE_DIRECTION }
this.pickCycleDirections = nil

---@type tes3itemData|nil
this.currentPickItemData = nil

---@public
---@return boolean,string|nil
function this.initialize()
	this.applyKeybinds()
	event.register(EVENTS.settingsUpdated, this.onKeyBindsUpdated)
	event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	event.register(EVENTS.sweetSpotUpdated, this.onSweetSpotUpdated)
	event.register(EVENTS.cylinderBlocked, this.onCylinderBlocked)
	event.register(EVENTS.rotationEnded, this.onRotationEnded)
	event.register(EVENTS.optionsMenuOpened, this.onOptionsMenuOpened)
	event.register(EVENTS.optionsMenuClosed, this.onOptionsMenuClosed)
	return true, nil
end

---@private
function this.onOptionsMenuOpened()
	this.paused = true
end

---@private
function this.onOptionsMenuClosed()
	this.paused = false
end

---@private
function this.onKeyBindsUpdated()
	this.applyKeybinds()
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.session = e.session
	this.picks = e.session.picks
	this.lock = e.session.lock
	this.currentPick = e.session.pick
	this.currentPickItemData = this.tryResolvePickItemData()
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
	this.session = nil
	this.picks = nil
	this.lock = nil
	this.currentPick = nil
	this.sweetSpotRadius = nil
	this.damaging = false
	this.damageAccumulator = 0
end

---@private
---@param e sweetSpotUpdatedEventData
function this.onSweetSpotUpdated(e)
	this.sweetSpotRadius = e.radius
end

---@private
function this.enable()
	if not event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.register(tes3.event.keyDown, this.onKeyDown)
	end
	if not event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.register(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
function this.disable()
	if event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.unregister(tes3.event.keyDown, this.onKeyDown)
	end
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if this.paused then
		return
	end

	if this.pickCycleDirections[e.keyCode] then
		this.cyclePick(this.pickCycleDirections[e.keyCode])
	end
end

---@private
function this.onCylinderBlocked()
	this.damaging = true
end

---@private
function this.onRotationEnded()
	this.damaging = false
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	if this.paused then
		return
	end

	if this.damaging then
		this.damagePick(e.delta)
	end
end

---@private
---@param delta number
function this.damagePick(delta)
	local itemData = this.ensurePickItemData()
	local rate = this.computeDamageRate()
	this.damageAccumulator = this.damageAccumulator + rate * delta

	local intDamage = math.floor(this.damageAccumulator)
	if intDamage >= 1 then
		this.damageAccumulator = this.damageAccumulator - intDamage
		itemData.condition = itemData.condition - intDamage
		if itemData.condition <= 0 then
			this.breakPick()
		end
	end
end

---@private
---@return tes3itemData
function this.ensurePickItemData()
	if not this.currentPickItemData then
		this.currentPickItemData = tes3.addItemData({
			to = tes3.player,
			item = this.currentPick.item.object --[[@as tes3lockpick]],
			updateGUI = true
		})
	end
	return this.currentPickItemData
end

---@private
---@return number
function this.computeDamageRate()
	return CONSTANTS.damage.baseRate
end

---@private
function this.breakPick()
	---@type pickBrokenEventData|pickBreakEventData
	local eventData = {
		pick = this.currentPick,
		itemData = this.currentPickItemData
	}
	event.trigger(EVENTS.pickBreak, eventData)
	event.trigger(EVENTS.pickBroken, eventData)

	local direction = this.currentPick.item.count <= 0 and CYCLE.next or nil
	this.cyclePick(direction)
end

---@private
---@param direction? CYCLE_DIRECTION
function this.cyclePick(direction)
	local previousPick = this.currentPick

	local item = direction
		and pickSelector.select(this.picks, direction)
		or previousPick.item

	local pick = pickSpawner.spawn(this.lock, item)

	this.damageAccumulator = 0
	this.currentPick = pick
	this.currentPickItemData = this.tryResolvePickItemData()

	---@type pickCycledEventData
	local eventData = {
		previousPick = previousPick,
		pick = pick,
	}
	event.trigger(EVENTS.pickCycled, eventData)
end

---@private
function this.tryResolvePickItemData()
	local item = this.currentPick.item

	if item.variables then
		local data = item.variables[1]
		for _, variable in ipairs(item.variables) do
			if variable.condition < data.condition then
				data = variable
			end
		end
		return data
	end

	return nil
end

---@private
function this.applyKeybinds()
	this.pickCycleDirections = {
		[settings.keyBinds.cycleNextPick.keyCode] = CYCLE.next,
		[settings.keyBinds.cyclePreviousPick.keyCode] = CYCLE.previous,
	}
end

return this
