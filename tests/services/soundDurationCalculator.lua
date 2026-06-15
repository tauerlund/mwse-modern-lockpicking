---@class soundDurationCalculatorTests : test
local this = {}

---@private
this.soundDurationCalculator = require("tauer.modern-lockpicking.services.sounds.soundDurationCalculator")

---@private
this.constants = require("tauer.modern-lockpicking.services.sounds.enums.constants")

---@public
---@param unitwind UnitWind
function this.run(unitwind)
    unitwind:start("Modern Lockpicking: soundDurationCalculator")

    unitwind:test("WAV duration is read from the file header", function ()
        -- Arrange: unlock-01.wav holds 68894 PCM data bytes at 44100 bytes/sec
        -- (22050 Hz, mono, 16-bit), so its duration is 1.562222 seconds.
        local path = this.soundPath("unlock-01.wav")
        -- Act
        local duration = this.soundDurationCalculator.getDuration(path)
        -- Assert
        this.expectNear(unitwind, duration, 1.562222)
    end)

    unitwind:test("A missing sound file yields a zero duration", function ()
        -- Act
        local duration = this.soundDurationCalculator.getDuration(this.soundPath("does-not-exist.wav"))
        -- Assert
        unitwind:expect(duration).toBe(0)
    end)

    unitwind:finish()
end

--- Full on-disk path of a bundled sound file, mirroring how soundFileResolver builds it.
---@private
---@param file string
---@return string
function this.soundPath(file)
    return string.format("%s/%s/%s", this.constants.paths.sound, this.constants.paths.mod, file)
end

--- Compares floats via formatting so failures log both numbers. Six significant
--- figures comfortably covers a duration measured to the millisecond.
---@private
---@param unitwind UnitWind
---@param actual number
---@param expected number
function this.expectNear(unitwind, actual, expected)
    unitwind:expect(string.format("%.6g", actual)).toBe(string.format("%.6g", expected))
end

return this
