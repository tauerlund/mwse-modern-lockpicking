local Settings = require("tauer.modern-lockpicking.shared.Settings")
local Translations = require("tauer.modern-lockpicking.shared.Translations")

local template = mwse.mcm.createTemplate { name = Translations.Get("modName"), headerImagePath = "textures\\tauer\\modern-lockpicking\\logo.tga" }
template.onClose = function ()
    Settings:Save()
end
template:register()

local settingsPage = template:createPage { label = Translations.Get("mcm.labels.settings") }

settingsPage:createSlider({
    label = Translations.Get("mcm.labels.lockpickDifficulty"),
    description = Translations.Get("mcm.description.lockpickDifficulty"),
    variable = mwse.mcm.createTableVariable({
        id = "lockpickDifficulty",
        table = Settings.Mcm,
    }),
    min = 0,
    max = 100,
    step = 1,
})

local controlsPage = template:createSideBarPage { label = Translations.Get("interface.controls.header") }

local rotateLockCategory = controlsPage:createCategory({
    label = Translations.Get("interface.controls.rotateLock"),
    description = Translations.Get("mcm.description.rotateLock"),
})

rotateLockCategory:createKeyBinder({
    label = Translations.Get("mcm.labels.left"),
    description = Translations.Get("mcm.description.rotateLockLeft"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "rotateLockLeft",
        table = Settings.Mcm.keyBinds,
    }),
})

rotateLockCategory:createKeyBinder({
    label = Translations.Get("mcm.labels.right"),
    description = Translations.Get("mcm.description.rotateLockRight"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "rotateLockRight",
        table = Settings.Mcm.keyBinds,
    }),
})


local cyclePicksCategory = controlsPage:createCategory({
    label = Translations.Get("interface.controls.cyclePicks"),
    description = Translations.Get("mcm.description.cyclePicks"),
})

cyclePicksCategory:createKeyBinder({
    label = Translations.Get("mcm.labels.previous"),
    description = Translations.Get("mcm.description.cyclePreviousPick"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "cyclePreviousPick",
        table = Settings.Mcm.keyBinds,
    }),
})


cyclePicksCategory:createKeyBinder({
    label = Translations.Get("mcm.labels.next"),
    description = Translations.Get("mcm.description.cycleNextPick"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "cycleNextPick",
        table = Settings.Mcm.keyBinds,
    }),
})

local otherCategory = controlsPage:createCategory({
    label = Translations.Get("mcm.labels.other"),
    description = Translations.Get("mcm.description.other"),
})

otherCategory:createKeyBinder({
    label = Translations.Get("interface.controls.exit"),
    description = Translations.Get("mcm.description.exit"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "exit",
        table = Settings.Mcm.keyBinds,
    }),
})
