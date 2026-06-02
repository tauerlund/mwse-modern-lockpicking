local TRANSLATION_KEY = require("tauer.modern-lockpicking.services.translations.enums.TRANSLATION_KEY")

---@class debuggingPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
---@param services serviceCollection
function this.initialize(template, services)
    local translations = services.translations
    local settings = services.mcmSettings.mcm

    local page = template:createSideBarPage {
        label = translations.get(TRANSLATION_KEY.mcmHeaderDebugging)
    }

    page:createOnOffButton({
        label = translations.get(TRANSLATION_KEY.mcmDebuggingLabelShowRenderer),
        description = translations.get(TRANSLATION_KEY.mcmDebuggingDescShowRenderer),
        variable = mwse.mcm.createTableVariable({
            id = "showSweetSpotRenderer",
            table = settings.debugging,
        }),
    })

    page:createLogLevelOptions({
        config = settings,
        configKey = "logLevel",
    })
end

return this
