---@class pickSelector : initializedService
local this = {}

---@private
---@type integer
this.currentIndex = 1

---@private
---@type tes3itemStack[]
this.picks = nil

---@private
---@type { [string]: boolean }|nil
this.eligiblePicks = nil

---@private
---@type playerDataController
this.playerDataController = nil

---@private
---@type inventoryController
this.inventoryController = nil

---@private
---@type settings
this.settings = nil

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
    this.playerDataController = services.playerDataController
    this.inventoryController = services.inventoryController
    this.settings = services.mcmSettings.mcm
    this.enums = services.enums
    local events = services.enums.events

    event.register(events.lockpickingStarted, this.onLockpickingStarted)
    event.register(events.lockpickingEnded, this.onLockpickingEnded)
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
---@param params pickSelector.select.params
---@return tes3itemStack
function this.select(params)
    if params.eligiblePicks then
        this.eligiblePicks = params.eligiblePicks
    end

    local picks = params.picks
    local direction = params.direction

    if not direction then
        this.currentIndex = this.resolveInitialIndex(picks)
        return picks[this.currentIndex]
    end

    local startIndex = this.currentIndex
    repeat
        if direction == this.enums.cycleDirections.next then
            this.currentIndex = this.incrementIndex(picks)
        else
            this.currentIndex = this.decrementIndex(picks)
        end
    until (picks[this.currentIndex].count > 0 and this.isEligible(picks[this.currentIndex]))
        or this.currentIndex == startIndex

    return picks[this.currentIndex]
end

---@private
---@param pick tes3itemStack
---@return boolean
function this.isEligible(pick)
    return not this.eligiblePicks or this.eligiblePicks[pick.object.id] == true
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
    if pickId then
        for i, pick in ipairs(picks) do
            if pick.object.id == pickId and this.isEligible(pick) then
                return i
            end
        end
    end

    for i, pick in ipairs(picks) do
        if this.isEligible(pick) and pick.count > 0 then
            return i
        end
    end

    return 1
end

---@private
---@return string|nil
function this.tryResolvePickId()
    if this.settings.activationStrategy == this.enums.activationStrategyNames.attack then
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
