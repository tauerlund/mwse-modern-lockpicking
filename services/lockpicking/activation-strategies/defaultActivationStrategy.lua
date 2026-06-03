---@class defaultActivationStrategy : activationStrategy
local this = {}

---@public
---@type string
this.name = nil

---@private
---@type enums
this.enums = nil

---@private
---@type inventoryController
this.inventoryController = nil

---@private
---@type skillController
this.skillController = nil

---@private
---@type translations
this.translations = nil

---@private
---@type settings
this.settings = nil

---@public
---@param services serviceCollection
function this.initialize(services)
    this.name = services.enums.activationStrategyNames.default
    this.enums = services.enums
    this.inventoryController = services.inventoryController
    this.skillController = services.skillController
    this.translations = services.translations
    this.settings = services.settings
end

---@public
function this.enable()
    if not event.isRegistered(tes3.event.activate, this.onActivate) then
        event.register(tes3.event.activate, this.onActivate)
    end
end

---@public
function this.disable()
    if event.isRegistered(tes3.event.activate, this.onActivate) then
        event.unregister(tes3.event.activate, this.onActivate)
    end
end

---@private
---@param e activateEventData
function this.onActivate(e)
    if e.activator ~= tes3.player then
        return
    end

    local activator = this.validateActivator(e.target)
    if not activator then
        return
    end

    if not this.isLocked(activator) then
        return
    end

    local canPick, reason = this.canPick(activator.lockNode)
    if canPick == false then
        tes3.messageBox(reason)
        return
    end

    ---@type lockpickingActivatedEventData
    local eventData = {
        activator = activator
    }
    event.trigger(this.enums.events.lockpickingActivated, eventData)
end

---@private
---@param lock tes3lockNode
---@return boolean, string
function this.canPick(lock)
    local pick = this.inventoryController.getBestLockpick()
    if not pick then
        return false, this.translations.get(this.enums.translationKeys.messageBoxNoLockpicks)
    end

    if not this.settings.useLockComplexity then
        return true, ""
    end

    local chance = this.skillController.getSuccessChance(pick, lock)
    if chance <= 0 then
        return false, tes3.findGMST(tes3.gmst.sLockImpossible).value --[[@as string]]
    end

    return true, ""
end

---@private
---@param target tes3reference
---@return tes3reference|nil
function this.validateActivator(target)
    local type = target.object.objectType
    if type == tes3.objectType.container or type == tes3.objectType.door then
        return target
    end
    return nil
end

---@private
---@param activator tes3reference
---@return boolean
function this.isLocked(activator)
    return tes3.getLocked({
        reference = activator,
    })
end

return this
