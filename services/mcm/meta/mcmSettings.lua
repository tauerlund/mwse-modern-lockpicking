---@meta

---@class keyBind
---@field public keyCode integer

---@class keybindSettings
---@field public rotateLockCounterclockwise keyBind
---@field public rotateLockClockwise keyBind
---@field public cyclePreviousPick keyBind
---@field public cycleNextPick keyBind
---@field public exit keyBind

---@class difficultySettings
---@field public securityFactor number
---@field public lockLevelFactor number
---@field public qualityFactor number
---@field public gradientFactor number
---@field public maxSweetSpotRadius number

---@class debuggingSettings
---@field public showSweetSpotRenderer boolean

---@class settings
---@field public keyBinds keybindSettings
---@field public logLevel string
---@field public activationStrategy string
---@field public difficulty difficultySettings
---@field public debugging debuggingSettings
