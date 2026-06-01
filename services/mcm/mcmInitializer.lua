--- SERVICES
local translations = require("tauer.modern-lockpicking.services.translations.translations")
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings")
---

--- PAGES
local controlsPage = require("tauer.modern-lockpicking.services.mcm.pages.controlsPage")
local difficultyPage = require("tauer.modern-lockpicking.services.mcm.pages.difficultyPage")
local debuggingPage = require("tauer.modern-lockpicking.services.mcm.pages.debuggingPage")
---

--- ENUMS
local TRANSLATION_KEY = require("tauer.modern-lockpicking.services.translations.enums.TRANSLATION_KEY")
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

---@class mcmInitializer : initializedService
local this = {}

--- @private
--- @type mcmPage[]
this.pages = {
    controlsPage,
    difficultyPage,
    debuggingPage
}

---@private
---@type string
this.headerImagePath = "textures\\tauer\\modern-lockpicking\\logo.tga"

---@public
---@return boolean, string|nil
function this.initialize()
    local template = mwse.mcm.createTemplate({
        name = translations.get(TRANSLATION_KEY.modName),
        headerImagePath = this.headerImagePath,
        onClose = this.onClose
    })

    for _, page in ipairs(this.pages) do
        page.initialize(template)
    end

    template:register()

    return true, nil
end

---@private
function this.onClose()
    settings.save()
    event.trigger(EVENTS.settingsUpdated)
end

return this
