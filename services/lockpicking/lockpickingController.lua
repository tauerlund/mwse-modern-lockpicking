--- SERVICES
local pickSelector = require("tauer.modern-lockpicking.services.picks.pickSelector")
local lockSpawner = require("tauer.modern-lockpicking.services.locks.lockSpawner")
local knifeSpawner = require("tauer.modern-lockpicking.services.knives.knifeSpawner")
local pickSpawner = require("tauer.modern-lockpicking.services.picks.pickSpawner")
local timerManager = require("tauer.modern-lockpicking.services.timers.timerManager")
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm
local inventoryManager = require("tauer.modern-lockpicking.services.inventory.inventoryManager")
local strategyLoader = require("tauer.modern-lockpicking.services.strategies.strategyLoader")
local translations = require("tauer.modern-lockpicking.services.translations.translations")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.lockpicking.enums.CONSTANTS")
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local DIRECTION = require("tauer.modern-lockpicking.services.lockpicking.enums.ROTATION_DIRECTION")
local CYCLE = require("tauer.modern-lockpicking.services.lockpicking.enums.CYCLE_DIRECTION")
local TRANSLATION_KEY = require("tauer.modern-lockpicking.services.translations.enums.TRANSLATION_KEY")
---

---@class lockpickingController : initializedService
local this = {}

---@private
---@type tes3containerInstance|tes3door
this.activator = nil

---@private
---@type tes3itemStack[]
this.picks = nil

---@private
---@type lock
this.lock = nil

---@private
---@type knife
this.knife = nil

---@private
---@type pick
this.pick = nil

---@private
---@type tes3.scanCode
this.currentDirectionKey = nil

---@private
---@type { [tes3.scanCode]: ROTATION_DIRECTION }
this.rotationDirections = nil

---@private
---@type { [tes3.scanCode]: CYCLE_DIRECTION }
this.pickCycleDirections = nil

---@private
---@type { [string]: activationStrategy }
this.activationStrategies = nil

---@private
---@type activationStrategy
this.currentActivationStrategy = nil

---@public
---@return boolean,string|nil
function this.initialize()
	this.activationStrategies = strategyLoader.loadAll({
		directory = "tauer\\modern-lockpicking\\services\\lockpicking\\strategies",
		requireNotEmpty = true,
	}) --[[@as { [string]: activationStrategy }]]

	if not this.activationStrategies then
		return false, "Failed to load activation strategies"
	end

	this.applyKeybinds()
	this.applyActivationStrategy()

	this.registerEvents()

	return true, nil
end

---@public
---@param e lockpickingActivatedEventData
function this.onLockPickingActivated(e)
	local picks = inventoryManager.getLockpicks()
	if not picks then
		tes3.messageBox(translations.get(TRANSLATION_KEY.messageBoxNoLockpicks))
		return
	end

	this.picks = picks
	this.activator = e.activator

	this.lock = lockSpawner.spawn(this.activator)
	this.knife = knifeSpawner.spawn(this.lock)
	this.pick = this.selectPick()

	---@type lockpickingStartEventData
	local lockPickingStartEventData = {
		activator = this.activator,
		lock = this.lock,
		knife = this.knife,
		picks = picks,
		pick = this.pick,
	}
	event.trigger(EVENTS.lockpickingStart, lockPickingStartEventData)

	timerManager.start({
		durationInSeconds = 1.3,
		finishedCallback = this.enable,
		cancelOn = EVENTS.lockpickingEnded,
	})
end

---@public
function this.exit()
	this.stop({ success = false })
end

---@private
---@param e keyDownEventData
function this.onKeyDown(e)
	if this.rotationDirections[e.keyCode] then
		this.onRotationDirectionKeyDown(e)
		return
	end
	if this.pickCycleDirections[e.keyCode] then
		this.onPickCycleKeyDown(e)
		return
	end
end

---@private
---@param e keyUpEventData
function this.onKeyUp(e)
	if this.rotationDirections[e.keyCode] then
		this.onRotationDirectionKeyUp(e)
		return
	end
	if e.keyCode == settings.keyBinds.exit.keyCode then
		this.finish({ success = false })
		return
	end
end

---@private
---@param e keyDownEventData
function this.onRotationDirectionKeyDown(e)
	---@type rotationEventData
	local data = {
		direction = this.rotationDirections[e.keyCode],
	}
	event.trigger(EVENTS.rotationStarted, data)
	this.currentDirectionKey = e.keyCode
end

---@private
---@param e keyDownEventData
function this.onPickCycleKeyDown(e)
	local direction = this.pickCycleDirections[e.keyCode]
	this.pick = this.selectPick(direction)
end

---@private
---@param e keyUpEventData
function this.onRotationDirectionKeyUp(e)
	if this.directionKeyIsBlocked(e.keyCode) then
		return
	end

	---@type rotationEventData
	local data = {
		direction = this.rotationDirections[e.keyCode],
	}
	event.trigger(EVENTS.rotationEnded, data)
	this.currentDirectionKey = nil
end

---@private
---@param keyCode tes3.scanCode
---@return boolean
function this.directionKeyIsBlocked(keyCode)
	return this.currentDirectionKey and this.currentDirectionKey ~= keyCode
end

---@private
---@param _ enterFrameEventData
function this.onEnterFrame(_)
	local rotation = this.lock.cylinder.rotation:toEulerXYZ().y

	if rotation <= CONSTANTS.targetRotationLeft or rotation >= CONSTANTS.targetRotationRight then
		this.finish({ success = true })
		return
	end
end

---@private
---@param direction CYCLE_DIRECTION?
---@return pick
function this.selectPick(direction)
	if this.pick then
		---@type pickChangeEventData
		local pickChangedEventData = {
			pick = this.pick,
		}
		event.trigger(EVENTS.pickChange, pickChangedEventData)
	end

	local item = pickSelector.select(this.picks, direction)
	local pick = pickSpawner.spawn(this.lock, item)

	---@type pickSelectedEventData
	local pickSelectedEventData = {
		pick = pick,
	}
	event.trigger(EVENTS.pickSelected, pickSelectedEventData)

	return pick
end

---@private
---@param parameters stopLockpickingParameters
function this.finish(parameters)
	---@type lockpickingEndEventData
	local data = {
		lock = this.lock,
		knife = this.knife,
		pick = this.pick,
		activator = this.activator,
		success = parameters.success,
	}
	event.trigger(EVENTS.lockpickingEnd, data)

	timerManager.start({
		durationInSeconds = 1,
		finishedCallback = this.onEndTimerFinished,
		data = data --[[@as timerData]],
	})

	this.disable()
end

---@private
---@param data timerData
function this.onEndTimerFinished(data)
	---@cast data +lockpickingEndedEventData, -timerData
	this.stop({ success = data.success })
end

---@private
---@param parameters stopLockpickingParameters
function this.stop(parameters)
	---@type lockpickingEndedEventData
	local data = {
		lock = this.lock,
		knife = this.knife,
		pick = this.pick,
		activator = this.activator,
		success = parameters.success,
	}
	event.trigger(EVENTS.lockpickingEnded, data)

	local activator = this.activator

	if parameters.success then
		tes3.unlock({
			reference = activator --[[@as tes3reference]],
		})
		timer.delayOneFrame(function ()
			tes3.player:activate(activator --[[@as tes3reference]])
		end)
	end

	this.disable()
	this.resetFields()
end

function this.resetFields()
	this.activator = nil
	this.picks = nil
	this.lock = nil
	this.knife = nil
	this.pick = nil
	this.currentDirectionKey = nil
end

---@private
function this.onKeyBindsUpdated()
	this.applyKeybinds()
end

---@private
function this.applyActivationStrategy()
	if this.currentActivationStrategy then
		this.currentActivationStrategy.disable()
	end

	this.currentActivationStrategy = this.activationStrategies[settings.activationStrategy]
	this.currentActivationStrategy.enable()
end

---@private
function this.applyKeybinds()
	this.rotationDirections = {
		[settings.keyBinds.rotateLockClockwise.keyCode] = DIRECTION.clockwise,
		[settings.keyBinds.rotateLockCounterclockwise.keyCode] = DIRECTION.counterClockwise,
	}
	this.pickCycleDirections = {
		[settings.keyBinds.cycleNextPick.keyCode] = CYCLE.next,
		[settings.keyBinds.cyclePreviousPick.keyCode] = CYCLE.previous,
	}
end

---@private
function this.enable()
	if not event.isRegistered(tes3.event.keyDown, this.onKeyDown) then
		event.register(tes3.event.keyDown, this.onKeyDown)
	end
	if not event.isRegistered(tes3.event.keyUp, this.onKeyUp) then
		event.register(tes3.event.keyUp, this.onKeyUp)
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
	if event.isRegistered(tes3.event.keyUp, this.onKeyUp) then
		event.unregister(tes3.event.keyUp, this.onKeyUp)
	end
	if event.isRegistered(tes3.event.enterFrame, this.onEnterFrame) then
		event.unregister(tes3.event.enterFrame, this.onEnterFrame)
	end
end

---@private
function this.registerEvents()
	event.register(EVENTS.keyBindsUpdated, this.onKeyBindsUpdated)
	event.register(EVENTS.lockpickingActivated, this.onLockPickingActivated)
end

return this
