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
---@field public securityWeight number
---@field public lockLevelWeight number
---@field public qualityWeight number
---@field public gradientFactor number
---@field public minSweetSpotRadius number
---@field public maxSweetSpotRadius number
---@field public baseRate number
---@field public damageSkeletonKey boolean

---@class debuggingSettings
---@field public showSweetSpotRenderer boolean

---@class settings
---@field public enabled boolean
---@field public keyBinds keybindSettings
---@field public logLevel string
---@field public activationStrategy activationStrategyNames
---@field public litRendering boolean
---@field public enableDof boolean
---@field public lockDistanceFactor number
---@field public showPickHealth boolean
---@field public allowEquipPicks boolean
---@field public useLockComplexity boolean
---@field public difficulty difficultySettings
---@field public debugging debuggingSettings
