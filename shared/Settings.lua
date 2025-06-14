---@class Settings
local this = {}

---@private
---@type string
this.path = "modern-lockpicking"

---@type SettingsMcm
this.defaults = {
    keyBinds = {
        rotateLockLeft = { keyCode = tes3.scanCode.a },
        rotateLockRight = { keyCode = tes3.scanCode.d },
        cyclePreviousPick = { keyCode = tes3.scanCode.w },
        cycleNextPick = { keyCode = tes3.scanCode.s },
        exit = { keyCode = tes3.scanCode.tab },
    }
}

---@type SettingsMcm
this.Mcm = mwse.loadConfig(this.path, this.defaults) --[[@as SettingsMcm]]

---@public
function this.Save()
    mwse.saveConfig(this.path, this.Mcm)
end

return this
