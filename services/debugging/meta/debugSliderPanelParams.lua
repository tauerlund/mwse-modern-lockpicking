---@meta
---@class debugSliderDef
---@field public label string
---@field public min number
---@field public max number
---@field public step number
---@field public default number
---@field public onChange fun(value: number)

---@class debugSliderPanelParams
---@field public title string
---@field public position { x: number, y: number }|nil
---@field public sliders debugSliderDef[]
---@field public onCopy (fun(): string)|nil

---@class transformSlidersOptions
---@field public applyRotation (fun(rotation: tes3matrix33))|nil
