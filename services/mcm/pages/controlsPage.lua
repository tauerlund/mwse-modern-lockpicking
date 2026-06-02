---@class controlsPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
---@param services serviceCollection
function this.initialize(template, services)
    local settings = services.settings

    local translations = services.translations
    local translationKeys = services.enums.translationKeys

    local activationStrategyNames = services.enums.activationStrategyNames

    local controlsPage = template:createSideBarPage { label = translations.get(translationKeys.interfaceControlsHeader) }

    local rotateLockCategory = controlsPage:createCategory({
        label = translations.get(translationKeys.interfaceControlsRotateLock),
        description = translations.get(translationKeys.mcmDescriptionRotateLock),
    })

    rotateLockCategory:createKeyBinder({
        label = translations.get(translationKeys.mcmLabelsLeft),
        description = translations.get(translationKeys.mcmDescriptionRotateLockCounterclockwise),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "rotateLockCounterclockwise",
            table = settings.keyBinds,
        }),
    })

    rotateLockCategory:createKeyBinder({
        label = translations.get(translationKeys.mcmLabelsRight),
        description = translations.get(translationKeys.mcmDescriptionRotateLockClockwise),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "rotateLockClockwise",
            table = settings.keyBinds,
        }),
    })


    local cyclePicksCategory = controlsPage:createCategory({
        label = translations.get(translationKeys.interfaceControlsCyclePicks),
        description = translations.get(translationKeys.mcmDescriptionCyclePicks),
    })

    cyclePicksCategory:createKeyBinder({
        label = translations.get(translationKeys.mcmLabelsPrevious),
        description = translations.get(translationKeys.mcmDescriptionCyclePreviousPick),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "cyclePreviousPick",
            table = settings.keyBinds,
        }),
    })


    cyclePicksCategory:createKeyBinder({
        label = translations.get(translationKeys.mcmLabelsNext),
        description = translations.get(translationKeys.mcmDescriptionCycleNextPick),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "cycleNextPick",
            table = settings.keyBinds,
        }),
    })

    local activationCategory = controlsPage:createCategory({
        label = translations.get(translationKeys.mcmActivationMethodCategory),
    })

    activationCategory:createCycleButton({
        label = translations.get(translationKeys.mcmActivationMethodLabel),
        description = translations.get(translationKeys.mcmActivationMethodDesc),
        options = {
            { text = translations.get(translationKeys.mcmActivationMethodDefault), value = activationStrategyNames.default },
            { text = translations.get(translationKeys.mcmActivationMethodAttack),  value = activationStrategyNames.attack },
        },
        variable = mwse.mcm.createTableVariable({
            id = "activationStrategy",
            table = settings,
        }),
    })

    activationCategory:createOnOffButton({
        label = translations.get(translationKeys.mcmAllowEquipPicksLabel),
        description = translations.get(translationKeys.mcmAllowEquipPicksDesc),
        variable = mwse.mcm.createTableVariable({
            id = "allowEquipPicks",
            table = settings,
        }),
    })

    local otherCategory = controlsPage:createCategory({
        label = translations.get(translationKeys.mcmLabelsOther),
        description = translations.get(translationKeys.mcmDescriptionOther),
    })

    otherCategory:createKeyBinder({
        label = translations.get(translationKeys.interfaceControlsExit),
        description = translations.get(translationKeys.mcmDescriptionExit),
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable({
            id = "exit",
            table = settings.keyBinds,
        }),
    })
end

return this
