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
}

---@type settings
this.mcm = mwse.loadConfig(this.path, this.defaults) --[[@as settings]]

--- Saves the current settings to the MCM file
---@public
function this.save()
    mwse.saveConfig(this.path, this.mcm)
end

return this
