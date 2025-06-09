local LockpickingController = require("tauer.modern-lockpicking.services.lockpicking.LockpickingController")

local events = require("tauer.modern-lockpicking.shared.enums.events")

---@class LockpickingStarter
local this = {}

---@private
---@type boolean
this.lockpickModeActive = false

---@private
---@type lock
this.lock = nil

---@public
function this.Start()
	event.register(tes3.event.activate, this.onActivate)
end

---@private
---@param e activateEventData
function this.onActivate(e)
	if e.activator ~= tes3.player then
		return
	end

	if
		not e.target.object.objectType == tes3.objectType.container
		and not e.target.objectType == tes3.objectType.door
	then
		return
	end

	local target = e.target --[[@as tes3reference]]
	if not tes3.getLocked({ reference = target }) then
		return
	end

	this.activateLockpickMode(target --[[@as tes3containerInstance]])
end

---@private
function this.onMenuExit()
	LockpickingController.Stop()
	this.lockpickModeActive = false
end

function this.onLockpickingEnded()
	tes3ui.leaveMenuMode()
	this.lockpickModeActive = false
end

---@private
---@param container tes3containerInstance
function this.activateLockpickMode(container)
	local started = LockpickingController.Start(container)
	if not started then
		return
	end

	this.lockpickModeActive = true

	tes3ui.enterMenuMode("ModernLockpicking")

	event.register(tes3.event.menuExit, this.onMenuExit, { doOnce = true })
	event.register(events.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
end

return this
