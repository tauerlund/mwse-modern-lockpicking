---@class serviceCollection
local this = {
    eventRegistrar = require("tauer.modern-lockpicking.services.events.eventRegistrar"),
    eventLogger = require("tauer.modern-lockpicking.services.events.eventLogger"),

    cylinderAnimator = require("tauer.modern-lockpicking.services.cylinders.cylinderAnimator"),
    cylinderController = require("tauer.modern-lockpicking.services.cylinders.cylinderController"),

    debuggingRenderer = require("tauer.modern-lockpicking.services.debugging.debuggingRenderer"),

    fileHelper = require("tauer.modern-lockpicking.services.files.fileHelper"),

    guiBuilder = require("tauer.modern-lockpicking.services.gui.guiBuilder"),
    guiController = require("tauer.modern-lockpicking.services.gui.guiController"),

    inventoryController = require("tauer.modern-lockpicking.services.inventory.inventoryController"),

    knifeAnimator = require("tauer.modern-lockpicking.services.knives.knifeAnimator"),
    knifeSpawner = require("tauer.modern-lockpicking.services.knives.knifeSpawner"),

    formulas = require("tauer.modern-lockpicking.services.shared.formulas"),
    lockpickingCircuitBreaker = require("tauer.modern-lockpicking.services.lockpicking.lockpickingCircuitBreaker"),
    lockpickingActivator = require("tauer.modern-lockpicking.services.lockpicking.lockpickingActivator"),
    lockpickingController = require("tauer.modern-lockpicking.services.lockpicking.lockpickingController"),

    lockAnimator = require("tauer.modern-lockpicking.services.locks.lockAnimator"),
    lockController = require("tauer.modern-lockpicking.services.locks.lockController"),
    lockMeshValidator = require("tauer.modern-lockpicking.services.locks.lockMeshValidator"),
    lockMeshResolver = require("tauer.modern-lockpicking.services.locks.lockMeshResolver"),
    lockMeshLoader = require("tauer.modern-lockpicking.services.locks.lockMeshLoader"),
    lockSpawner = require("tauer.modern-lockpicking.services.locks.lockSpawner"),

    mcmInitializer = require("tauer.modern-lockpicking.services.mcm.mcmInitializer"),
    mcmSettings = require("tauer.modern-lockpicking.services.mcm.mcmSettings"),
    settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm,

    nodeAnimator = require("tauer.modern-lockpicking.services.nodes.nodeAnimator"),

    pickSessionAnimator = require("tauer.modern-lockpicking.services.picks.pickSessionAnimator"),
    pickBreakAnimator = require("tauer.modern-lockpicking.services.picks.pickBreakAnimator"),
    pickController = require("tauer.modern-lockpicking.services.picks.pickController"),
    pickSelector = require("tauer.modern-lockpicking.services.picks.pickSelector"),
    pickSpawner = require("tauer.modern-lockpicking.services.picks.pickSpawner"),

    renderingController = require("tauer.modern-lockpicking.services.rendering.renderingController"),
    renderingStrategyController = require("tauer.modern-lockpicking.services.rendering.renderingStrategyController"),

    skillController = require("tauer.modern-lockpicking.services.skills.skillController"),

    soundController = require("tauer.modern-lockpicking.services.sounds.soundController"),
    soundDurationCalculator = require("tauer.modern-lockpicking.services.sounds.soundDurationCalculator"),
    soundFileResolver = require("tauer.modern-lockpicking.services.sounds.soundFileResolver"),

    strategyLoader = require("tauer.modern-lockpicking.services.strategies.strategyLoader"),

    timerManager = require("tauer.modern-lockpicking.services.timers.timerManager"),

    translations = require("tauer.modern-lockpicking.services.translations.translations"),

    playerController = require("tauer.modern-lockpicking.services.player.playerController"),

    ---@class enums
    enums = {
        events = require("tauer.modern-lockpicking.services.events.enums.events"),
        rotationDirections = require("tauer.modern-lockpicking.services.lockpicking.enums.rotationDirections"),
        cycleDirections = require("tauer.modern-lockpicking.services.lockpicking.enums.cycleDirections"),
        activationStrategyNames = require(
            "tauer.modern-lockpicking.services.lockpicking.activation-strategies.enums.activationStrategyNames"),
        renderingStrategyNames = require(
            "tauer.modern-lockpicking.services.rendering.rendering-strategies.enums.renderingStrategyNames"),
        openOnSuccessModes = require("tauer.modern-lockpicking.services.locks.enums.openOnSuccessModes"),
        fileTypes = require("tauer.modern-lockpicking.services.files.enums.fileType"),
        translationKeys = require("tauer.modern-lockpicking.services.translations.enums.translationKeys"),
        objectNames = require("tauer.modern-lockpicking.services.nodes.enums.objectNames"),
        zBufferIndex = require("tauer.modern-lockpicking.services.rendering.enums.zBufferIndex"),

        ---@class constants
        constants = {
            cylinder = require("tauer.modern-lockpicking.services.cylinders.enums.constants"),
            lockpicking = require("tauer.modern-lockpicking.services.lockpicking.enums.constants"),
            gui = require("tauer.modern-lockpicking.services.gui.enums.constants"),
            knives = require("tauer.modern-lockpicking.services.knives.enums.constants"),
            sounds = require("tauer.modern-lockpicking.services.sounds.enums.constants"),
            picks = require("tauer.modern-lockpicking.services.picks.enums.constants"),
            locks = require("tauer.modern-lockpicking.services.locks.enums.constants"),
            rendering = require("tauer.modern-lockpicking.services.rendering.enums.constants"),
            skills = require("tauer.modern-lockpicking.services.skills.enums.constants"),
        }
    }
}

---@public
---@return service[]
function this.unnamedServices()
    return { this.enums, this.settings }
end

return this
