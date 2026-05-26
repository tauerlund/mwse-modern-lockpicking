local Logger = require("tauer.modern-lockpicking.shared.loggingFactory")

local CONSTANTS = require("tauer.modern-lockpicking.services.sounds.enums.constants")

---@class soundFileResolver : initializedService
local this = {}

---@private
---@type { [string]: soundFile[] }
this.sounds = {}

---@private
---@type soundFile
this.empty = {
    path = "",
    duration = 0,
}

---@public
---@return boolean,string|nil
function this.initialize()
    for file in lfs.dir(string.format("%s/%s", CONSTANTS.paths.sound, CONSTANTS.paths.mod)) do
        if file:match("%.wav$") then
            local name = file:match("^(.*)%.wav$")
            local template = name:gsub("%-%d+$", "")

            this.sounds[template] = this.sounds[template] or {}

            local path = string.format("%s/%s", CONSTANTS.paths.mod, file)
            ---@type soundFile
            local soundFile = {
                path = path,
                duration = this.calculateDuration(path),
            }

            table.insert(this.sounds[template], soundFile)
        end
    end

    return this.validate()
end

---@public
---@param template string
---@return soundFile
function this.resolve(template)
    if not this.sounds[template] then
        Logger:error("Sound template '%s' not found.", template)
        return this.empty
    end

    local sound = table.choice(this.sounds[template])
    if not sound then
        Logger:error("No sound files found for '%s'.", template)
        return this.empty
    end

    return sound
end

---@private
---@return boolean, string|nil
function this.validate()
    for _, template in pairs(CONSTANTS.templates) do
        if not this.sounds[template] then
            return false, string.format("sound template '%s' is missing or has no sound files.", template)
        end
    end
    return true, nil
end

---@private
---@param path string
---@return number
function this.calculateDuration(path)
    local fileSize = lfs.attributes(string.format("%s/%s", CONSTANTS.paths.sound, path), "size")

    local headerSize = CONSTANTS.wav.headerSize
    local sampleRate = CONSTANTS.wav.sampleRate
    local bytesPerSample = CONSTANTS.wav.bytesPerSample

    local bytesPerSecond = sampleRate * bytesPerSample

    return (fileSize - headerSize) / bytesPerSecond
end

return this
