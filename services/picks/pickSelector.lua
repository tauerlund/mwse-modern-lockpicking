---@class pickSelector : initializedService
local this = {}

---@private
---@type lockpickingSession
this.session = nil

---@private
---@type integer
this.currentIndex = 1

---@private
---@type { [string]: boolean }|nil
this.eligiblePicks = nil

---@private
---@type playerController
this.playerController = nil

---@private
---@type inventoryController
this.inventoryController = nil

---@private
---@type settings
this.settings = nil

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlers
this.eventHandlers = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
    this.playerController = services.playerController
    this.inventoryController = services.inventoryController
    this.settings = services.settings
    this.enums = services.enums
    this.eventRegistrar = services.eventRegistrar

    local events = services.enums.events

    this.eventHandlers = {
        [events.lockpickingStarted] = this.onLockpickingStarted,
        [events.lockpickingEnded] = this.onLockpickingEnded,
    }

    this.eventRegistrar.register(this.eventHandlers)
    return true, nil
end

---@public
function this.uninitialize()
    this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
---@param e lockpickingStartEventData
function this.onLockpickingStarted(e)
    this.session = e.session
end

---@private
function this.onLockpickingEnded()
    local picks = this.session and this.session.picks

    local lastPick = picks
        and picks[this.currentIndex]
        and picks[this.currentIndex].object

    this.session = nil

    if not lastPick or not lastPick:isValid() then
        return
    end

    local data = this.playerController.data()
    data.lastPickId = lastPick.id
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

    -- Clamp in case picks array shrank after a break (e.g. last element was the broken pick)
    if this.currentIndex > #picks then
        this.currentIndex = 1
    end

    local startIndex = this.currentIndex
    for _ = 1, #picks do
        if direction == this.enums.cycleDirections.next then
            this.currentIndex = this.incrementIndex(picks)
        else
            this.currentIndex = this.decrementIndex(picks)
        end
        if (picks[this.currentIndex].count > 0 and this.isEligible(picks[this.currentIndex]))
            or this.currentIndex == startIndex then
            break
        end
    end

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
    local data = this.playerController.data()
    return data.lastPickId
end

return this
