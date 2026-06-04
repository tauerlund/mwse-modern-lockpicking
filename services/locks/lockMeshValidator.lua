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
    for _, objectName in ipairs(this.enums.objectNames) do
        if not mesh:getObjectByName(objectName) then
            return false, string.format("'%s' is missing object '%'", mesh.name, objectName)
        end
    end
    return true, nil
end

return this
