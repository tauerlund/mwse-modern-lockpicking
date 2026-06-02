---@enum soundConstants
local enum = {
    paths = {
        sound = "data files/sound",
        mod = "tauer/modern-lockpicking",
    },
    templates = {
        lockpickingStart = "lockpicking-start",
        changeLockpick = "change-lockpick",
        unlock = "unlock",
        rotateLockpick = "rotate-lockpick",
        rotateCylinder = "rotate-cylinder",
        jiggleLockpick = "jiggle-lockpick",
        breakLockpick = "break-lockpick"
    },
    lockpickRotationMaxDelta = 0.1,
    wav = {
        headerSize = 96,
        sampleRate = 22050,
        bytesPerSample = 2,
    }
}

return enum
