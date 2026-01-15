--- SERVICES
local Settings = require("tauer.modern-lockpicking.shared.Settings")
local translations = require("tauer.modern-lockpicking.shared.translations")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
---

local template = mwse.mcm.createTemplate { name = translations.Get("modName"), headerImagePath = "textures\\tauer\\modern-lockpicking\\logo.tga" }
template.onClose = function ()
    Settings:Save()
    event.trigger(EVENTS.keyBindsUpdated)
end
template:register()

-- local settingsPage = template:createPage { label = translations.Get("mcm.labels.settings") }

-- settingsPage:createSlider({
--     label = translations.Get("mcm.labels.lockpickDifficulty"),
--     description = translations.Get("mcm.description.lockpickDifficulty"),
--     variable = mwse.mcm.createTableVariable({
--         id = "lockpickDifficulty",
--         table = Settings.Mcm,
--     }),
--     min = 0,
--     max = 100,
--     step = 1,
-- })

local controlsPage = template:createSideBarPage { label = translations.Get("interface.controls.header") }

local rotateLockCategory = controlsPage:createCategory({
    label = translations.Get("interface.controls.rotateLock"),
    description = translations.Get("mcm.description.rotateLock"),
})

rotateLockCategory:createKeyBinder({
    label = translations.Get("mcm.labels.left"),
    description = translations.Get("mcm.description.rotateLockCounterclockwise"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "rotateLockCounterclockwise",
        table = Settings.Mcm.keyBinds,
    }),
})

rotateLockCategory:createKeyBinder({
    label = translations.Get("mcm.labels.right"),
    description = translations.Get("mcm.description.rotateLockClockwise"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "rotateLockClockwise",
        table = Settings.Mcm.keyBinds,
    }),
})


local cyclePicksCategory = controlsPage:createCategory({
    label = translations.Get("interface.controls.cyclePicks"),
    description = translations.Get("mcm.description.cyclePicks"),
})

cyclePicksCategory:createKeyBinder({
    label = translations.Get("mcm.labels.previous"),
    description = translations.Get("mcm.description.cyclePreviousPick"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "cyclePreviousPick",
        table = Settings.Mcm.keyBinds,
    }),
})


cyclePicksCategory:createKeyBinder({
    label = translations.Get("mcm.labels.next"),
    description = translations.Get("mcm.description.cycleNextPick"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "cycleNextPick",
        table = Settings.Mcm.keyBinds,
    }),
})

local otherCategory = controlsPage:createCategory({
    label = translations.Get("mcm.labels.other"),
    description = translations.Get("mcm.description.other"),
})

otherCategory:createKeyBinder({
    label = translations.Get("interface.controls.exit"),
    description = translations.Get("mcm.description.exit"),
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({
        id = "exit",
        table = Settings.Mcm.keyBinds,
    }),
})
