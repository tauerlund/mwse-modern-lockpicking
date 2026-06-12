---@class renderingController : initializedService
local this = {}

---@private
this.pauseRenderingInMenus = false

---@private
this.sessionActive = false

---@private
---@type mgeShaderHandle|nil
this.depthOfField = nil

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
---@type renderingStrategyController
this.renderingStrategyController = nil

---@private
---@type formulas
this.formulas = nil

---@private
---@type eventHandlers
this.eventHandlers = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
    this.settings = services.settings
    this.enums = services.enums
    this.eventRegistrar = services.eventRegistrar
    this.renderingStrategyController = services.renderingStrategyController
    this.formulas = services.formulas

    local events = services.enums.events

    this.eventHandlers = {
        [events.lockpickingStart] = this.onLockpickingStart,
        [events.lockpickingEnded] = this.onLockpickingEnded,
        [events.settingsUpdated] = this.onSettingsUpdated,
        [events.renderingStrategyChanged] = this.onRenderingStrategyChanged,
    }

    this.eventRegistrar.register(this.eventHandlers)

    this.depthOfField = mge.shaders.load({ name = "modern-lockpicking/Bokeh" })
    if this.depthOfField then
        this.depthOfField.enabled = false
    end

    return true, nil
end

---@public
function this.uninitialize()
    this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
function this.applyDof()
    if not this.depthOfField then
        return
    end
    if this.settings.enableDof then
        local constants = this.enums.constants.rendering
        this.depthOfField["focus_distance"] = this.formulas.dofFocusDistance(
            this.renderingStrategyController.getTargetDistance() - constants.focusBias, constants.unitsToMeters)
        this.depthOfField["focal_length"] = constants.focalLength
        this.depthOfField.enabled = true
    else
        this.depthOfField.enabled = false
    end
end

---@private
---@param _ lockpickingStartEventData
function this.onLockpickingStart(_)
    this.sessionActive = true
    this.pauseRenderingInMenus = mge.render.pauseRenderingInMenus
    mge.render.pauseRenderingInMenus = false

    this.applyDof()

    if not tes3.mobilePlayer.is3rdPerson then
        tes3.player1stPerson.sceneNode.appCulled = true
    end
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
    this.sessionActive = false
    mge.render.pauseRenderingInMenus = this.pauseRenderingInMenus

    if this.depthOfField then
        this.depthOfField.enabled = false
    end

    if not tes3.mobilePlayer.is3rdPerson then
        tes3.player1stPerson.sceneNode.appCulled = false
    end
end

---@private
function this.onSettingsUpdated()
    if not this.sessionActive then
        return
    end
    this.applyDof()
end

---@private
function this.onRenderingStrategyChanged()
    if not this.sessionActive then
        return
    end
    this.applyDof()
end

return this
