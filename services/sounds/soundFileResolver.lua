---@class soundFileResolver : initializedService
local this = {}

---@private
this.logger = mwse.Logger.new()

---@private
---@type { [string]: soundFile[] }
this.sounds = {}

---@private
---@type soundFile
this.empty = {
    path = "",
    duration = 0,
}

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
    this.enums = services.enums

    local paths = services.enums.constants.sounds.paths

    local directory = string.format("%s/%s", paths.sound, paths.mod)

    if not lfs.directoryexists(directory) then
        return false, string.format("could not find sound directory at '%s'", directory)
    end

    for file in lfs.dir(directory) do
        if file:match("%.wav$") then
            local name = file:match("^(.*)%.wav$")
            local template = name:gsub("%-%d+$", "")

            this.sounds[template] = this.sounds[template] or {}

            local path = string.format("%s/%s", paths.mod, file)
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
        this.logger:error("Sound template '%s' not found.", template)
        return this.empty
    end

    local sound = table.choice(this.sounds[template])
    if not sound then
        this.logger:error("No sound files found for '%s'.", template)
        return this.empty
    end

    return sound
end

---@private
---@return boolean, string|nil
function this.validate()
    for _, template in pairs(this.enums.constants.sounds.templates) do
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
    local constants = this.enums.constants.sounds

    local fileSize = lfs.attributes(string.format("%s/%s", constants.paths.sound, path), "size")

    local headerSize = constants.wav.headerSize
    local sampleRate = constants.wav.sampleRate
    local bytesPerSample = constants.wav.bytesPerSample

    local bytesPerSecond = sampleRate * bytesPerSample

    return (fileSize - headerSize) / bytesPerSecond
end

return this
