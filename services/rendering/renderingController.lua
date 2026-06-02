---@class renderingController : initializedService
local this = {}

---@private
---@type boolean
this.pauseRenderingInMenus = false

---@private
---@type mgeShaderHandle|nil
this.depthOfField = nil

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
    this.enums = services.enums

    local events = services.enums.events

    event.register(events.lockpickingStart, this.onLockpickingStart)
    event.register(events.lockpickingEnded, this.onLockpickingEnded)

    this.depthOfField = mge.shaders.load({ name = "modern-lockpicking/Bokeh" })
    if this.depthOfField then
        this.depthOfField.enabled = false
    end

    return true, nil
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
