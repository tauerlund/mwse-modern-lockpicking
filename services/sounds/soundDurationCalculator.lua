--- Reads the playback duration of PCM WAV sound files from their headers.
---@class soundDurationCalculator
local this = {}

---@private
this.logger = mwse.Logger.new()

--- Duration (in seconds) of the PCM WAV at the given path. Returns 0 if the
--- file cannot be read.
---@public
---@param filePath string
---@return number
function this.getDuration(filePath)
    local file = io.open(filePath, "rb")
    if not file then
        this.logger:error("Could not open sound file '%s' to read its duration.", filePath)
        return 0
    end

    local duration = this.parseWavDuration(file)
    file:close()
    return duration
end

--- Returns the "data" chunk size divided by the "fmt " chunk's byteRate, which
--- already folds in sample rate, channels and bit depth. Returns 0 if the file
--- is not a well-formed PCM WAV.
---@private
---@param file file*
---@return number
function this.parseWavDuration(file)
    if not this.isRiffWave(file) then
        return 0
    end

    local byteRate
    while true do
        local id, size = this.readChunkHeader(file)
        if not id then
            return 0
        end

        if id == "fmt " then
            byteRate = this.readByteRate(file, size)
        elseif id == "data" then
            if not byteRate or byteRate == 0 then
                return 0
            end
            return size / byteRate
        else
            this.skipChunk(file, size)
        end
    end
end

--- Verifies the RIFF/WAVE header, skipping the file-size field between the two
--- tags, and leaves the file at the first chunk.
---@private
---@param file file*
---@return boolean
function this.isRiffWave(file)
    if file:read(4) ~= "RIFF" then
        return false
    end
    file:seek("cur", 4)
    return file:read(4) == "WAVE"
end

--- Reads a chunk's id and body size, leaving the file at the body. Returns nil
--- once the file runs out of chunks.
---@private
---@param file file*
---@return string|nil id, integer size
function this.readChunkHeader(file)
    local id = file:read(4)
    local sizeBytes = file:read(4)
    if not id or not sizeBytes or #sizeBytes < 4 then
        return nil, 0
    end
    return id, this.readUint32(sizeBytes)
end

--- Reads byteRate from a "fmt " chunk body (bytes 9-12) and consumes the rest
--- of the chunk.
---@private
---@param file file*
---@param size integer
---@return integer
function this.readByteRate(file, size)
    local body = file:read(size)
    this.skipPadding(file, size)
    return this.readUint32(body:sub(9, 12))
end

--- Skips a chunk body and its padding.
---@private
---@param file file*
---@param size integer
function this.skipChunk(file, size)
    file:seek("cur", size)
    this.skipPadding(file, size)
end

--- Chunks are word-aligned: an odd-sized body is followed by a pad byte.
---@private
---@param file file*
---@param size integer
function this.skipPadding(file, size)
    if size % 2 == 1 then
        file:seek("cur", 1)
    end
end

---@private
---@param bytes string
---@return integer
function this.readUint32(bytes)
    return bytes:byte(1)
        + bytes:byte(2) * 0x100
        + bytes:byte(3) * 0x10000
        + bytes:byte(4) * 0x1000000
end

return this
