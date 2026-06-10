---@class inventoryController : initializedService
local this = {}

---@private
---@type settings
this.settings = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlerGroups
this.eventHandlers = {
	lifetime = {},
	settings = {}
}

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.settings = services.settings
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.pickBreak] = this.onPickBreak,
			[events.settingsUpdated] = this.onSettingsUpdated,
		},
		settings = {
			[tes3.event.equip] = this.onEquip,
		}
	}

	this.eventRegistrar.register(this.eventHandlers.lifetime)

	this.applySettings()
	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
end

---@public
---@return tes3itemStack|nil
function this.getBestLockpick()
	local picks = this.getLockpicks()
	if not picks then
		return nil
	end

	return picks[#picks]
end

---@public
---@return tes3itemStack[]|nil
function this.getLockpicks()
	---@type tes3itemStack[]
	local picks = {}

	for _, item in pairs(tes3.player.object.inventory.items) do
		if item.object.objectType == tes3.objectType.lockpick then
			table.insert(picks, item)
		end
	end

	table.sort(picks, this.sortByLowestQuality)

	if #picks == 0 then
		return nil
	end

	return picks
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
function this.onPickBreak(e)
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
	this.eventRegistrar.register(this.eventHandlers.settings)
end

---@private
function this.enableLockpickEquip()
	this.eventRegistrar.unregister(this.eventHandlers.settings)
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
