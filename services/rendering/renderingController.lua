---@class renderingController : initializedService
local this = {}

---@private
this.pauseRenderingInMenus = false

---@private
---@type mgeShaderHandle|nil
this.depthOfField = nil

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
---@return boolean,string|nil
function this.initialize(services)
    this.enums = services.enums
    this.eventRegistrar = services.eventRegistrar

    local events = services.enums.events

    this.eventHandlers = {
        [events.lockpickingStart] = this.onLockpickingStart,
        [events.lockpickingEnded] = this.onLockpickingEnded,
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
---@param _ lockpickingStartEventData
function this.onLockpickingStart(_)
    local constants = this.enums.constants.rendering
    this.pauseRenderingInMenus = mge.render.pauseRenderingInMenus
    mge.render.pauseRenderingInMenus = false

    if this.depthOfField then
        this.depthOfField["focus_distance"] = constants.focusDistance
        this.depthOfField["focal_length"] = constants.focalLength
        this.depthOfField.enabled = true
    end

    if not tes3.mobilePlayer.is3rdPerson then
        tes3.player1stPerson.sceneNode.appCulled = true
    end
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
    mge.render.pauseRenderingInMenus = this.pauseRenderingInMenus

    if this.depthOfField then
        this.depthOfField.enabled = false
    end

    if not tes3.mobilePlayer.is3rdPerson then
        tes3.player1stPerson.sceneNode.appCulled = false
    end
end

return this
