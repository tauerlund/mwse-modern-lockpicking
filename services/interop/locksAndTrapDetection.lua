--- Interop with the Locks and Trap Detection mod
--- (https://www.nexusmods.com/morrowind/mods/48528). Every method returns nil when the mod is not installed.
---@class locksAndTrapDetection
local this = {}

---@private
---@type detectTrapLockDataModule|nil
this.module = include("AdituV.DetectTrap.LockData")


---@public
---@param activator tes3reference
---@return string|nil
function this.getLockLevelLabel(activator)
	local lockData = this.getLockData(activator)
	if not lockData then
		return
	end

	if lockData:getMinLock() == lockData:getMaxLock() then
		return tostring(lockData:getMinLock())
	elseif lockData:getMinLock() < lockData:getMaxLock() then
		return string.format("%d - %d", lockData:getMinLock(), lockData:getMaxLock())
	end

	return nil
end

---@public
---@param activator tes3reference
---@return integer|nil
function this.getMaxLockLevel(activator)
	local lockData = this.getLockData(activator)
	if not lockData then
		return
	end

	if lockData:getMinLock() <= lockData:getMaxLock() then
		return lockData:getMaxLock()
	end

	return nil
end

---@public
---@param activator tes3reference
function this.narrowLockRange(activator)
	local lockData = this.getLockData(activator)
	if not lockData then
		return
	end

	if lockData.locked and lockData:getMinLock() ~= lockData:getMaxLock() then
		lockData:attemptDetectLock()
		if lockData:getMinLock() > lockData:getMaxLock() then
			lockData:setMinLock(1)
			lockData:setMaxLock(100)
		end
	end
end

---@private
---@param activator tes3reference
---@return detectTrapLockData|nil
function this.getLockData(activator)
	if not this.module then
		return
	end

	return this.module.getForReference(activator)
end

return this
