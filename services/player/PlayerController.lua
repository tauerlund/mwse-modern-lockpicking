--- SERVICES
local InventoryManager = require("tauer.modern-lockpicking.services.inventory.InventoryManager")
local LockpickingController = require("tauer.modern-lockpicking.services.lockpicking.LockpickingController")
local Translations = require("tauer.modern-lockpicking.shared.Translations")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
---

---@class PlayerController
local this = {}

---@public
function this.Start()
	this.registerEvents()
end

function this.Stop()
	this.unregisterEvents()
end

---@private
---@param e activateEventData
function this.onActivate(e)
	if e.activator ~= tes3.player then
		return
	end

	local activator = this.validateActivator(e.target)
	if not activator then
		return
	end

	if not this.isLocked(activator) then
		return
	end

	this.startLockpicking(activator)
end

---@private
---@param target tes3reference
---@return tes3containerInstance|tes3door|nil
function this.validateActivator(target)
	local type = target.object.objectType
	if type == tes3.objectType.container or type == tes3.objectType.door then
		return target --[[@as tes3containerInstance|tes3door]]
	end
	return nil
end

---@private
---@param activator tes3containerInstance|tes3door
---@return boolean
function this.isLocked(activator)
	return tes3.getLocked({
		reference = activator --[[@as tes3reference]],
	})
end

---@private
---@param activator tes3containerInstance|tes3door
function this.startLockpicking(activator)
	local picks = InventoryManager.GetLockpicks()
	if not picks then
		tes3.messageBox(Translations.Get("messageBox.noLockpicks"))
		return
	end

	LockpickingController.Start(activator, picks)

	tes3ui.enterMenuMode("ModernLockpicking")

	event.register(tes3.event.menuExit, this.onMenuExit, { doOnce = true })
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
end

---@private
---@param _ menuExitEventData
function this.onMenuExit(_)
	LockpickingController.Stop()
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	tes3ui.leaveMenuMode()
	if e.success then
		tes3.unlock({
			reference = e.activator --[[@as tes3reference]],
		})
		timer.delayOneFrame(function ()
			tes3.player:activate(e.activator --[[@as tes3reference]])
		end)
	end
end

---@private
function this.registerEvents()
	event.register(tes3.event.activate, this.onActivate)
end

---@private
function this.unregisterEvents()
	if event.isRegistered(tes3.event.activate, this.onActivate) then
		event.unregister(tes3.event.activate, this.onActivate)
	end
	if event.isRegistered(tes3.event.menuExit, this.onMenuExit) then
		event.unregister(tes3.event.menuExit, this.onMenuExit)
	end
	if event.isRegistered(EVENTS.lockpickingEnded, this.onLockpickingEnded) then
		event.unregister(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	end
end

return this
