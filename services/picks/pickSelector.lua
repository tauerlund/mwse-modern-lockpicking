local CYCLE = require("tauer.modern-lockpicking.shared.enums.cycleDirection")

---@class pickSelector
local this = {}

---@private
---@type integer
this.currentIndex = 1

---@public
---@param picks tes3itemStack[]
---@param direction CYCLE_DIRECTION?
---@return tes3itemStack
function this.select(picks, direction)
    if not direction then
        this.currentIndex = this.getInitialIndex()
    elseif direction == CYCLE.next then
        this.currentIndex = this.incrementIndex(picks)
    else
        this.currentIndex = this.decrementIndex(picks)
    end

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
