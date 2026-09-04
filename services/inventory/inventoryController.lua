---@class inventoryController : initializedService
local this = {}

---@private
---@type settings
this.settings = nil

---@private
---@type enums
this.enums = nil

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
	this.enums = services.enums
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
	local blacklist = this.settings.pickBlacklist

	for _, item in pairs(tes3.player.object.inventory.items) do
		local object = item.object
		if object.objectType == tes3.objectType.lockpick and not blacklist[object.id:lower()] then
			table.insert(picks, item)
		end
	end

	table.sort(picks, this.sortByLowestQuality)

	return picks
end

---@public
---@return tes3itemStack[]
function this.getKnives()
	---@type tes3itemStack[]
	local knives = {}
	local whitelist = this.settings.knifeWhitelist

	for _, item in pairs(tes3.player.object.inventory.items) do
		if whitelist[item.object.id:lower()] then
			table.insert(knives, item)
		end
	end

	table.sort(knives, this.getKnifeComparer())

	return knives
end

---@public
---@return tes3itemStack|nil
function this.getBestKnife()
	local knives = this.getKnives()
	if #knives == 0 then
		return nil
	end

	return knives[1]
end

---@public
---@return boolean
function this.hasKnife()
	return this.getBestKnife() ~= nil
end

---@public
---@return tes3lockpick|nil
function this.tryGetEquippedPick()
	local blacklist = this.settings.pickBlacklist

	for _, item in ipairs(tes3.player.object.equipment) do
		local object = item.object
		if object.objectType == tes3.objectType.lockpick and not blacklist[object.id:lower()] then
			return object --[[@as tes3lockpick]]
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
---@return fun(a: tes3itemStack, b: tes3itemStack): boolean
function this.getKnifeComparer()
	local modes = this.enums.knifeSelectionModes
	local mode = this.settings.knifeSelection

	if mode == modes.lowestValue then
		return this.sortByLowestValue
	end

	if mode == modes.alphabetical then
		return this.sortAlphabetically
	end

	return this.sortByHighestValue
end

---@private
---@param a tes3itemStack
---@param b tes3itemStack
function this.sortByHighestValue(a, b)
	if a.object.value == b.object.value then
		return a.object.id:lower() < b.object.id:lower()
	end
	return a.object.value > b.object.value
end

---@private
---@param a tes3itemStack
---@param b tes3itemStack
function this.sortByLowestValue(a, b)
	if a.object.value == b.object.value then
		return a.object.id:lower() < b.object.id:lower()
	end
	return a.object.value < b.object.value
end

---@private
---@param a tes3itemStack
---@param b tes3itemStack
function this.sortAlphabetically(a, b)
	return a.object.id:lower() < b.object.id:lower()
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

	if this.settings.pickBlacklist[e.item.id:lower()] then
		return
	end

	e.block = true
end

return this
