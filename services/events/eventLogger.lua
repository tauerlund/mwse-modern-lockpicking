local logger = mwse.Logger.new()

--- ENUMS
local EVENTS = require("mods.tauer.modern-lockpicking.services.events.enums.events")
---

---@class eventLogger : initializedService
local this = {}

---@public
---@return boolean, string|nil
function this.initialize()
    event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
    return true, nil
end

---@private
---@param _ lockpickingStartEventData
function this.onLockpickingStart(_)
    logger:debug("Lockpicking started")
end

return this
