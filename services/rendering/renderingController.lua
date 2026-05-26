local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local CONSTANTS = require("tauer.modern-lockpicking.services.rendering.enums.constants")

---@class renderingController : initializedService
local this = {}

---@private
---@type boolean
this.pauseRenderingInMenus = false

---@private
---@type mgeShaderHandle|nil
this.depthOfField = nil

---@public
---@return boolean
function this.initialize()
    this.registerEvents()

    this.depthOfField = mge.shaders.load({ name = "modern-lockpicking/Bokeh" })
    if this.depthOfField then
        this.depthOfField.enabled = false
    end

    return true
end

---@private
---@param _ lockpickingStartEventData
function this.start(_)
    this.pauseRenderingInMenus = mge.render.pauseRenderingInMenus
    mge.render.pauseRenderingInMenus = false

    if this.depthOfField then
        this.depthOfField["focus_distance"] = CONSTANTS.focusDistance
        this.depthOfField["focal_length"] = CONSTANTS.focalLength
        this.depthOfField.enabled = true
    end
end

---@privates
---@param _ lockpickingEndedEventData
function this.stop(_)
    mge.render.pauseRenderingInMenus = this.pauseRenderingInMenus

    if this.depthOfField then
        this.depthOfField.enabled = false
    end
end

---@private
function this.registerEvents()
    event.register(EVENTS.lockpickingStart, this.start)
    event.register(EVENTS.lockpickingEnded, this.stop)
end

return this
