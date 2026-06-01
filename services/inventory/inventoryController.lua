--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

local logger = mwse.Logger.new()

---@class inventoryController : initializedService
local this = {}

---@public
---@return boolean, string|nil
function this.initialize()
	event.register(EVENTS.pickBreak, this.onPickBroken)
	return true, nil
end

---@public
---@return tes3itemStack[]|nil
function this.getLockpicks()
	---@type tes3itemStack[]
	local lockpicks = {}

	for _, item in pairs(tes3.player.object.inventory.items) do
		if item.object.objectType == tes3.objectType.lockpick then
			logger:info("Found %s", item.object.name)
			table.insert(lockpicks, item)
		end
	end

	if #lockpicks == 0 then
		return nil
	end

	table.sort(lockpicks, this.sortByLowestQuality)

	return lockpicks
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

return this
