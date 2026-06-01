local translations = require("tauer.modern-lockpicking.services.translations.translations")
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings")

local TRANSLATION_KEY = require("tauer.modern-lockpicking.services.translations.enums.TRANSLATION_KEY")

---@class debuggingPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
function this.initialize(template)
    local page = template:createSideBarPage { label = translations.get(TRANSLATION_KEY.mcmHeaderDebugging) }

    page:createOnOffButton({
        label = translations.get(TRANSLATION_KEY.mcmDebuggingLabelShowRenderer),
        description = translations.get(TRANSLATION_KEY.mcmDebuggingDescShowRenderer),
        variable = mwse.mcm.createTableVariable({
            id = "showSweetSpotRenderer",
            table = settings.mcm.debugging,
        }),
    })

    page:createLogLevelOptions({
        config = settings.mcm,
        configKey = "logLevel",
    })
end

return this
