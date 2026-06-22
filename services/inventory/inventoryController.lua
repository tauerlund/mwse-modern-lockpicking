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
	equipBlocking = {}
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
			[events.settingsUpdated] = this.onSettingsUpdated,
		},
		equipBlocking = {
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
	if #picks == 0 then
		return nil
	end

	return picks[#picks]
end

---@public
---@return tes3itemStack[]
function this.getLockpicks()
	---@type tes3itemStack[]
	local picks = {}

	for _, item in pairs(tes3.player.object.inventory.items) do
		if item.object.objectType == tes3.objectType.lockpick then
			table.insert(picks, item)
		end
	end

	table.sort(picks, this.sortByLowestQuality)

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

---@public
---@param key tes3misc
---@return boolean
function this.hasKey(key)
	for _, item in pairs(tes3.player.object.inventory.items) do
		if item.object == key then
			return true
		end
	end
	return false
end

---@private
---@param a tes3itemStack
---@param b tes3itemStack
function this.sortByLowestQuality(a, b)
	local pickA = a.object --[[@as tes3lockpick]]
	local pickB = b.object --[[@as tes3lockpick]]
	return pickA.quality < pickB.quality
end

---@public
---@param pick pick
---@param itemData tes3itemData|nil
function this.removePick(pick, itemData)
	tes3.removeItem({
		reference = tes3.player,
		item = pick.item.object --[[@as tes3lockpick]],
		itemData = itemData,
		updateGUI = true,
	})
end

---@private
function this.onSettingsUpdated()
	this.applySettings()
end

---@private
function this.applySettings()
	if this.settings.enabled and not this.settings.allowEquipPicks then
		this.blockEquip()
	else
		this.unblockEquip()
	end
end

---@private
function this.blockEquip()
	this.eventRegistrar.register(this.eventHandlers.equipBlocking)
end

---@private
function this.unblockEquip()
	this.eventRegistrar.unregister(this.eventHandlers.equipBlocking)
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
