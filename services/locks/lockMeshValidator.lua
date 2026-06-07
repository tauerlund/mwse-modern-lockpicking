---@class lockMeshValidator : initializedService
local this = {}

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
    this.enums = services.enums
    return true, nil
end

---@public
---@param mesh niNode
---@return boolean, reason
function this.validate(mesh)
    local names = this.enums.objectNames

    for _, name in ipairs({ names.cylinderHelper, names.knifeHelper, names.pickHelper }) do
        if not mesh:getObjectByName(name) then
            return false, string.format("object '%s' is missing", mesh.name, name)
        end
    end
    return true, nil
end

return this
