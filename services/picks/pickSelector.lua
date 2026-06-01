--- ENUMS
local CYCLE = require("tauer.modern-lockpicking.services.lockpicking.enums.CYCLE_DIRECTION")
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

---@class pickSelector : initializedService
local this = {}

---@private
---@type integer
this.currentIndex = 1

---@public
---@return boolean, string|nil
function this.initialize()
    event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
    return true, nil
end

---@private
function this.onLockpickingEnded()
    this.currentIndex = this.getInitialIndex()
end

---@public
---@param picks tes3itemStack[]
---@param direction CYCLE_DIRECTION?
---@return tes3itemStack
function this.select(picks, direction)
    if not direction then
        this.currentIndex = this.getInitialIndex()
        return picks[this.currentIndex]
    end

    local startIndex = this.currentIndex
    repeat
        if direction == CYCLE.next then
            this.currentIndex = this.incrementIndex(picks)
        else
            this.currentIndex = this.decrementIndex(picks)
        end
    until picks[this.currentIndex].count > 0 or this.currentIndex == startIndex

    return picks[this.currentIndex]
end

---@private
---@param picks tes3itemStack[]
---@return integer
function this.incrementIndex(picks)
    if this.currentIndex >= #picks then
        return 1
    else
        return this.currentIndex + 1
    end
end

---@private
---@param picks tes3itemStack[]
---@return integer
function this.decrementIndex(picks)
    if this.currentIndex <= 1 then
        return #picks
    else
        return this.currentIndex - 1
    end
end

---@private
---@return integer
function this.getInitialIndex()
    return 1
end

return this
