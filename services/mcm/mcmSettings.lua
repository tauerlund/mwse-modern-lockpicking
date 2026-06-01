--- ENUMS
local ACTIVATION_STRATEGY_NAMES = require(
    "tauer.modern-lockpicking.services.lockpicking.activation-strategies.enums.ACTIVATION_STRATEGY_NAMES")
---

---@class mcmSettings
local this = {}

---@private
---@type string
this.path = "modern-lockpicking"

---@type settings
this.defaults = {
    keyBinds = {
        rotateLockCounterclockwise = { keyCode = tes3.scanCode.a },
        rotateLockClockwise = { keyCode = tes3.scanCode.d },
        cyclePreviousPick = { keyCode = tes3.scanCode.w },
        cycleNextPick = { keyCode = tes3.scanCode.s },
        exit = { keyCode = tes3.scanCode.tab },
    },
    logLevel = "INFO",
    activationStrategy = ACTIVATION_STRATEGY_NAMES.default,
    difficulty = {
        securityFactor = 1.0,
        lockLevelFactor = 5.0,
        qualityFactor = 1.0,
        gradientFactor = 2.0,
        maxSweetSpotRadius = 45,
        baseRate = 1,
    },
    debugging = {
        showSweetSpotRenderer = false,
    },
}

---@type settings
this.mcm = mwse.loadConfig(this.path, this.defaults) --[[@as settings]]

--- Saves the current settings to the MCM file
---@public
function this.save()
    mwse.saveConfig(this.path, this.mcm)
end

return this
