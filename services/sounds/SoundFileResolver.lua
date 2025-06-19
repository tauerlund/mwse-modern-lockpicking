local Logger = require("tauer.modern-lockpicking.shared.Logger")

local CONSTANTS = require("tauer.modern-lockpicking.services.sounds.enums.constants")

---@class SoundFileResolver : IInitializedService
local this = {}

---@private
---@type { [string]: string[] }
this.sounds = {}

---@public
---@return boolean
function this.Initialize()
    for file in lfs.dir(string.format("data files/sound/%s", CONSTANTS.basePath)) do
        if file:match("%.wav$") then
            local name = file:match("^(.*)%.wav$")
            local template = name:gsub("%-%d+$", "")

            this.sounds[template] = this.sounds[template] or {}
            table.insert(this.sounds[template], string.format("%s/%s", CONSTANTS.basePath, file))
        end
    end
    return true
end

---@public
---@param template string
---@return string
function this.Resolve(template)
    if not this.sounds[template] then
        Logger:error("Sound template '%s' not found.", template)
        return ""
    end

    local sound = table.choice(this.sounds[template])
    if not sound then
        Logger:error("No sound files found for '%s'.", template)
        return ""
    end

    return sound
end

return this
