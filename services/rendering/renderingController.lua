--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local CONSTANTS = require("tauer.modern-lockpicking.services.rendering.enums.CONSTANTS")
---

---@class renderingController : initializedService
local this = {}

---@private
---@type boolean
this.pauseRenderingInMenus = false

---@private
---@type mgeShaderHandle|nil
this.depthOfField = nil

---@public
---@param _ serviceCollection
---@return boolean,string|nil
function this.initialize(_)
    this.registerEvents()

    this.depthOfField = mge.shaders.load({ name = "modern-lockpicking/Bokeh" })
    if this.depthOfField then
        this.depthOfField.enabled = false
    end

    return true, nil
end

---@private
function this.registerEvents()
    event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
    event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
end

---@private
---@param _ lockpickingStartEventData
function this.onLockpickingStart(_)
    this.pauseRenderingInMenus = mge.render.pauseRenderingInMenus
    mge.render.pauseRenderingInMenus = false

    if this.depthOfField then
        this.depthOfField["focus_distance"] = CONSTANTS.focusDistance
        this.depthOfField["focal_length"] = CONSTANTS.focalLength
        this.depthOfField.enabled = true
    end

    if not tes3.mobilePlayer.is3rdPerson then
        tes3.player1stPerson.sceneNode.appCulled = true
    end
end

---@privates
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
