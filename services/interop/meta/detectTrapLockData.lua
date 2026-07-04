---@meta

--- A subset of the Locks and Trap Detection mod's `AdituV.DetectTrap.LockData`
---@class detectTrapLockData
---@field public locked boolean
---@field public getMinLock fun(self: detectTrapLockData): integer
---@field public getMaxLock fun(self: detectTrapLockData): integer
---@field public setMinLock fun(self: detectTrapLockData, value: integer)
---@field public setMaxLock fun(self: detectTrapLockData, value: integer)
---@field public attemptDetectLock fun(self: detectTrapLockData)

--- The mod's `AdituV.DetectTrap.LockData` module.
---@class detectTrapLockDataModule
---@field public getForReference fun(reference: tes3reference): detectTrapLockData|nil
