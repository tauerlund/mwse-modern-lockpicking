---@class inventoryController
local this = {}

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

---@private
---@param a tes3itemStack
function this.sortByLowestQuality(a, b)
	local pickA = a.object --[[@as tes3lockpick]]
	local pickB = b.object --[[@as tes3lockpick]]
	return pickA.quality < pickB.quality
end

return this
