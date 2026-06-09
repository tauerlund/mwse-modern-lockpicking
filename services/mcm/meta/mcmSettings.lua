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
---@field public baseRate number
---@field public damageSkeletonKey boolean

---@class debuggingSettings
---@field public showSweetSpotRenderer boolean

---@class settings
---@field public enabled boolean
---@field public keyBinds keybindSettings
---@field public logLevel string
---@field public activationStrategy string|nil
---@field public litRendering boolean
---@field public enableDof boolean
---@field public allowEquipPicks boolean
---@field public useLockComplexity boolean
---@field public difficulty difficultySettings
---@field public debugging debuggingSettings
