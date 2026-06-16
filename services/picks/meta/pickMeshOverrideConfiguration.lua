---@meta
---@class pickMeshOverrideConfiguration
---@field [integer] pickMeshOverrideEntry

---@class pickMeshOverrideEntry
---@field public pickMeshes string[]
---@field public rotationTarget { x: number, y: number, z: number }|nil
---@field public depthOffset number|nil

---@class resolvedPickOverride
---@field public rotationTarget tes3vector3
---@field public depthOffset number
