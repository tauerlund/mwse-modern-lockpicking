---@class serviceCollection
local this = {
    cylinderAnimator = require("tauer.modern-lockpicking.services.cylinders.cylinderAnimator"),
    cylinderController = require("tauer.modern-lockpicking.services.cylinders.cylinderController"),

    debuggingRenderer = require("tauer.modern-lockpicking.services.debugging.debuggingRenderer"),

    eventLogger = require("tauer.modern-lockpicking.services.events.eventLogger"),

    fileHelper = require("tauer.modern-lockpicking.services.files.fileHelper"),

    guiBuilder = require("tauer.modern-lockpicking.services.gui.guiBuilder"),
    guiController = require("tauer.modern-lockpicking.services.gui.guiController"),

    inventoryController = require("tauer.modern-lockpicking.services.inventory.inventoryController"),

    knifeAnimator = require("tauer.modern-lockpicking.services.knives.knifeAnimator"),
    knifeSpawner = require("tauer.modern-lockpicking.services.knives.knifeSpawner"),

    lockpickingActivator = require("tauer.modern-lockpicking.services.lockpicking.lockpickingActivator"),
    lockpickingController = require("tauer.modern-lockpicking.services.lockpicking.lockpickingController"),

    lockAnimator = require("tauer.modern-lockpicking.services.locks.lockAnimator"),
    lockController = require("tauer.modern-lockpicking.services.locks.lockController"),
    lockMeshResolver = require("tauer.modern-lockpicking.services.locks.lockMeshResolver"),
    lockSpawner = require("tauer.modern-lockpicking.services.locks.lockSpawner"),

    mcmInitializer = require("tauer.modern-lockpicking.services.mcm.mcmInitializer"),
    mcmSettings = require("tauer.modern-lockpicking.services.mcm.mcmSettings"),
    settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm,

    nodeAnimator = require("tauer.modern-lockpicking.services.nodes.nodeAnimator"),

    pickAnimator = require("tauer.modern-lockpicking.services.picks.pickAnimator"),
    pickController = require("tauer.modern-lockpicking.services.picks.pickController"),
    pickSelector = require("tauer.modern-lockpicking.services.picks.pickSelector"),
    pickSpawner = require("tauer.modern-lockpicking.services.picks.pickSpawner"),

    renderingController = require("tauer.modern-lockpicking.services.rendering.renderingController"),

    skillController = require("tauer.modern-lockpicking.services.skills.skillController"),

    soundController = require("tauer.modern-lockpicking.services.sounds.soundController"),
    soundFileResolver = require("tauer.modern-lockpicking.services.sounds.soundFileResolver"),

    strategyLoader = require("tauer.modern-lockpicking.services.strategies.strategyLoader"),

    timerManager = require("tauer.modern-lockpicking.services.timers.timerManager"),

    translations = require("tauer.modern-lockpicking.services.translations.translations"),
}

return this
