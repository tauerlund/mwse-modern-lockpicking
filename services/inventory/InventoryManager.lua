Logger = require("tauer.modern-lockpicking.shared.Logger")

---@class InventoryManager
local this = {}

---@public
---@return tes3itemStack|nil
function this.GetLockpicks()
	local lockpicks = {}

	for _, item in pairs(tes3.player.object.inventory) do
		if item.object.objectType == tes3.objectType.lockpick then
			table.insert(lockpicks, item)
		end
	end

	if #lockpicks == 0 then
		return nil
	end

	table.sort(lockpicks, this.sortByLowestPrice)

	return lockpicks
end

---@private
---@param a tes3itemStack
function this.sortByLowestPrice(a, b)
	local pickA = a.object --[[@as tes3lockpick]]
	local pickB = b.object --[[@as tes3lockpick]]
	return pickA.value < pickB.value
end

return this
