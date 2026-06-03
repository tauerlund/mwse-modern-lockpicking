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
---@type { [tes3.scanCode]: cycleDirections }
this.pickCycleDirections = nil

---@type tes3itemData|nil
this.currentPickItemData = nil

---@private
---@type settings
this.settings = nil

---@private
---@type pickSelector
this.pickSelector = nil

---@private
---@type pickSpawner
this.pickSpawner = nil

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.settings = services.settings
	this.pickSelector = services.pickSelector
	this.pickSpawner = services.pickSpawner
	this.enums = services.enums
	local events = services.enums.events

	this.applyKeybinds()
	event.register(events.settingsUpdated, this.onKeyBindsUpdated)
	event.register(events.lockpickingStarted, this.onLockpickingStarted)
	event.register(events.lockpickingEnd, this.onLockpickingEnd)
	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	event.register(events.sweetSpotUpdated, this.onSweetSpotUpdated)
	event.register(events.cylinderBlocked, this.onCylinderBlocked)
	event.register(events.rotationEnded, this.onRotationEnded)
	event.register(events.optionsMenuOpened, this.onOptionsMenuOpened)
	event.register(events.optionsMenuClosed, this.onOptionsMenuClosed)
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
	local settings = this.settings

	if not this.sweetSpotRadius or this.sweetSpotRadius <= 0 then
		return settings.difficulty.baseRate
	end
	local maxRadius = math.rad(settings.difficulty.maxSweetSpotRadius)
	return settings.difficulty.baseRate * math.sqrt(maxRadius / this.sweetSpotRadius)
end

---@private
function this.breakPick()
	---@type pickBrokenEventData|pickBreakEventData
	local eventData = {
		pick = this.currentPick,
		itemData = this.currentPickItemData
	}
	event.trigger(this.enums.events.pickBreak, eventData)
	event.trigger(this.enums.events.pickBroken, eventData)

	local direction = this.currentPick.item.count <= 0 and this.enums.cycleDirections.next or nil
	this.cyclePick(direction)
end

---@private
---@param direction? cycleDirections
function this.cyclePick(direction)
	local previousPick = this.currentPick

	local item = direction
		and this.pickSelector.select({
			picks = this.picks,
			direction = direction
		})
		or previousPick.item

	if direction and item == previousPick.item then
		return
	end

	local pick = this.pickSpawner.spawn(this.lock, item)

	this.damageAccumulator = 0
	this.currentPick = pick
	this.currentPickItemData = this.tryResolvePickItemData()

	---@type pickCycledEventData
	local eventData = {
		previousPick = previousPick,
		pick = pick,
	}
	event.trigger(this.enums.events.pickCycled, eventData)
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
		[this.settings.keyBinds.cycleNextPick.keyCode] = this.enums.cycleDirections.next,
		[this.settings.keyBinds.cyclePreviousPick.keyCode] = this.enums.cycleDirections.previous,
	}
end

return this
