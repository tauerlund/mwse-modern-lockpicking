---@class debuggingPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
---@param services serviceCollection
function this.initialize(template, services)
    local settings = services.settings

    local translations = services.translations
    local translationKeys = services.enums.translationKeys

    local page = template:createSideBarPage {
        label = translations.get(translationKeys.mcmHeaderDebugging)
    }

    page:createOnOffButton({
        label = translations.get(translationKeys.mcmDebuggingLabelShowRenderer),
        description = translations.get(translationKeys.mcmDebuggingDescShowRenderer),
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
