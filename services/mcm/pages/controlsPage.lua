local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm
local translations = require("tauer.modern-lockpicking.services.translations.translations")
local TRANSLATION_KEY = require("tauer.modern-lockpicking.services.translations.enums.TRANSLATION_KEY")
local ACTIVATION_STRATEGY_NAMES = require(
    "tauer.modern-lockpicking.services.lockpicking.activation-strategies.enums.ACTIVATION_STRATEGY_NAMES")

---@class controlsPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
function this.initialize(template)
    local controlsPage = template:createSideBarPage { label = translations.get(TRANSLATION_KEY.interfaceControlsHeader) }

    local rotateLockCategory = controlsPage:createCategory({
        label = translations.get(TRANSLATION_KEY.interfaceControlsRotateLock),
        description = translations.get(TRANSLATION_KEY.mcmDescriptionRotateLock),
    })

    rotateLockCategory:createKeyBinder({
        label = translations.get(TRANSLATION_KEY.mcmLabelsLeft),
        description = translations.get(TRANSLATION_KEY.mcmDescriptionRotateLockCounterclockwise),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "rotateLockCounterclockwise",
            table = settings.keyBinds,
        }),
    })

    rotateLockCategory:createKeyBinder({
        label = translations.get(TRANSLATION_KEY.mcmLabelsRight),
        description = translations.get(TRANSLATION_KEY.mcmDescriptionRotateLockClockwise),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "rotateLockClockwise",
            table = settings.keyBinds,
        }),
    })


    local cyclePicksCategory = controlsPage:createCategory({
        label = translations.get(TRANSLATION_KEY.interfaceControlsCyclePicks),
        description = translations.get(TRANSLATION_KEY.mcmDescriptionCyclePicks),
    })

    cyclePicksCategory:createKeyBinder({
        label = translations.get(TRANSLATION_KEY.mcmLabelsPrevious),
        description = translations.get(TRANSLATION_KEY.mcmDescriptionCyclePreviousPick),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "cyclePreviousPick",
            table = settings.keyBinds,
        }),
    })


    cyclePicksCategory:createKeyBinder({
        label = translations.get(TRANSLATION_KEY.mcmLabelsNext),
        description = translations.get(TRANSLATION_KEY.mcmDescriptionCycleNextPick),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "cycleNextPick",
            table = settings.keyBinds,
        }),
    })

    local activationCategory = controlsPage:createCategory({
        label = translations.get(TRANSLATION_KEY.mcmActivationMethodCategory),
    })

    activationCategory:createCycleButton({
        label = translations.get(TRANSLATION_KEY.mcmActivationMethodLabel),
        description = translations.get(TRANSLATION_KEY.mcmActivationMethodDesc),
        options = {
            { text = translations.get(TRANSLATION_KEY.mcmActivationMethodDefault), value = ACTIVATION_STRATEGY_NAMES.default },
            { text = translations.get(TRANSLATION_KEY.mcmActivationMethodAttack), value = ACTIVATION_STRATEGY_NAMES.attack },
        },
        variable = mwse.mcm.createTableVariable({
            id = "activationStrategy",
            table = settings,
        }),
    })

    activationCategory:createOnOffButton({
        label = translations.get(TRANSLATION_KEY.mcmAllowEquipPicksLabel),
        description = translations.get(TRANSLATION_KEY.mcmAllowEquipPicksDesc),
        variable = mwse.mcm.createTableVariable({
            id = "allowEquipPicks",
            table = settings,
        }),
    })

    local otherCategory = controlsPage:createCategory({
        label = translations.get(TRANSLATION_KEY.mcmLabelsOther),
        description = translations.get(TRANSLATION_KEY.mcmDescriptionOther),
    })

    otherCategory:createKeyBinder({
        label = translations.get(TRANSLATION_KEY.interfaceControlsExit),
        description = translations.get(TRANSLATION_KEY.mcmDescriptionExit),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "exit",
            table = settings.keyBinds,
        }),
    })
end

return this
