--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

---@class inventoryController : initializedService
local this = {}

---@private
---@type settings
this.settings = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.settings = services.settings

	event.register(EVENTS.pickBreak, this.onPickBroken)
	event.register(EVENTS.settingsUpdated, this.onSettingsUpdated)
	this.applySettings()
	return true, nil
end

---@public
---@return tes3itemStack[]|nil
function this.getLockpicks()
	---@type tes3itemStack[]
	local lockpicks = {}

	for _, item in pairs(tes3.player.object.inventory.items) do
		if item.object.objectType == tes3.objectType.lockpick then
			table.insert(lockpicks, item)
		end
	end

	if #lockpicks == 0 then
		return nil
	end

	table.sort(lockpicks, this.sortByLowestQuality)

	return lockpicks
end

---@public
---@return tes3lockpick|nil
function this.tryGetEquippedPick()
	for _, item in ipairs(tes3.player.object.equipment) do
		if item.object.objectType == tes3.objectType.lockpick then
			return item.object --[[@as tes3lockpick]]
		end
	end
	return nil
end

---@private
---@param a tes3itemStack
---@param b tes3itemStack
function this.sortByLowestQuality(a, b)
	local pickA = a.object --[[@as tes3lockpick]]
	local pickB = b.object --[[@as tes3lockpick]]
	return pickA.quality < pickB.quality
end

---@private
---@param e pickBrokenEventData
function this.onPickBroken(e)
	tes3.removeItem({
		reference = tes3.player,
		item = e.pick.item.object --[[@as tes3lockpick]],
		itemData = e.itemData,
		updateGUI = true,
	})
end

---@private
function this.onSettingsUpdated()
	this.applySettings()
end

---@private
function this.applySettings()
	if this.settings.allowEquipPicks then
		this.enableLockpickEquip()
	else
		this.disableLockpickEquip()
	end
end

---@private
function this.disableLockpickEquip()
	if not event.isRegistered(tes3.event.equip, this.onEquip) then
		event.register(tes3.event.equip, this.onEquip)
	end
end

---@private
function this.enableLockpickEquip()
	if event.isRegistered(tes3.event.equip, this.onEquip) then
		event.unregister(tes3.event.equip, this.onEquip)
	end
end

---@private
---@param e equipEventData
function this.onEquip(e)
	if e.item.objectType ~= tes3.objectType.lockpick then
		return
	end
	e.block = true
end

return this
