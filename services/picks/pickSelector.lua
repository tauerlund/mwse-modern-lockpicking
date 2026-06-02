--- ENUMS
local CYCLE = require("tauer.modern-lockpicking.services.lockpicking.enums.CYCLE_DIRECTION")
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local ACTIVATION_STRATEGY_NAMES = require(
    "tauer.modern-lockpicking.services.lockpicking.activation-strategies.enums.ACTIVATION_STRATEGY_NAMES")
---

---@class pickSelector : initializedService
local this = {}

---@private
---@type integer
this.currentIndex = 1

---@private
---@type tes3itemStack[]
this.picks = nil

---@private
---@type playerDataController
this.playerDataController = nil

---@private
---@type inventoryController
this.inventoryController = nil

---@private
---@type settings
this.settings = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
    this.playerDataController = services.playerDataController
    this.inventoryController = services.inventoryController
    this.settings = services.mcmSettings.mcm

    event.register(EVENTS.lockpickingStarted, this.onLockpickingStarted)
    event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
    return true, nil
end

---@private
---@param e lockpickingStartEventData
function this.onLockpickingStarted(e)
    this.picks = e.session.picks
end

---@private
function this.onLockpickingEnded()
    local data = this.playerDataController.resolve()
    data.lastPickId = this.picks[this.currentIndex].object.id
end

---@public
---@param picks tes3itemStack[]
---@param direction CYCLE_DIRECTION?
---@return tes3itemStack
function this.select(picks, direction)
    if not direction then
        this.currentIndex = this.resolveInitialIndex(picks)
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
    if this.currentIndex >= table.size(picks) then
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
        return table.size(picks)
    else
        return this.currentIndex - 1
    end
end

---@private
---@param picks tes3itemStack[]
---@return integer
function this.resolveInitialIndex(picks)
    local pickId = this.tryResolvePickId()
    if not pickId then
        return 1
    end

    for i, pick in ipairs(picks) do
        if pick.object.id == pickId then
            return i
        end
    end

    return 1
end

---@private
---@return string|nil
function this.tryResolvePickId()
    if this.settings.activationStrategy == ACTIVATION_STRATEGY_NAMES.attack then
        return this.tryResolveEquippedPickId()
    end
    return this.tryResolveLastPickId()
end

---@private
---@return string|nil
function this.tryResolveEquippedPickId()
    local pick = this.inventoryController.tryGetEquippedPick()
    return pick and pick.id
end

---@private
---@return string|nil
function this.tryResolveLastPickId()
    local data = this.playerDataController.resolve()
    return data.lastPickId
end

return this
