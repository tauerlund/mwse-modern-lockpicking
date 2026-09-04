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
---@field public minDamageRate number
---@field public maxDamageRate number
---@field public damageSkeletonKey boolean
---@field public pickBreakSkillGain number

---@class debuggingSettings
---@field public showSweetSpotRenderer boolean
---@field public showPickDebugger boolean

---@class settings
---@field public enabled boolean
---@field public keyBinds keybindSettings
---@field public logLevel string
---@field public activationStrategy activationStrategyNames
---@field public litRendering boolean
---@field public enableDof boolean
---@field public lockDistanceFactor number
---@field public showLockLevel boolean
---@field public showPickHealth boolean
---@field public allowEquipPicks boolean
---@field public useLockComplexity boolean
---@field public requireKnife boolean
---@field public knifeSelection knifeSelectionModes
---@field public pickBlacklist table<string, boolean>
---@field public knifeWhitelist table<string, boolean>
---@field public openOnSuccess openOnSuccessModes
---@field public difficulty difficultySettings
---@field public debugging debuggingSettings
