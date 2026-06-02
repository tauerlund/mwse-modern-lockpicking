--- ENUMS
local TRANSLATION_KEY = require("tauer.modern-lockpicking.services.translations.enums.TRANSLATION_KEY")
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

---@class mcmInitializer : initializedService
local this = {}

--- @private
--- @type mcmPage[]
this.pages = {
    require("tauer.modern-lockpicking.services.mcm.pages.controlsPage"),
    require("tauer.modern-lockpicking.services.mcm.pages.difficultyPage"),
    require("tauer.modern-lockpicking.services.mcm.pages.debuggingPage")
}

---@private
---@type string
this.headerImagePath = "textures\\tauer\\modern-lockpicking\\logo.tga"

---@private
---@type mcmSettings
this.settings = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
    this.settings = services.mcmSettings

    local template = mwse.mcm.createTemplate({
        name = services.translations.get(TRANSLATION_KEY.modName),
        headerImagePath = this.headerImagePath,
        onClose = this.onClose
    })

    for _, page in ipairs(this.pages) do
        page.initialize(template, services)
    end

    template:register()

    return true, nil
end

---@private
function this.onClose()
    this.settings.save()
    event.trigger(EVENTS.settingsUpdated)
end

return this
