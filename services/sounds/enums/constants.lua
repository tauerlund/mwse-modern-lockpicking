---@enum SOUND_CONSTANTS
local enum = {
    basePath = "tauer/modern-lockpicking",
    soundTemplates = {
        lockpickingStart = "lockpicking-start",
        changeLockpick = "change-lockpick",
        unlock = "unlock",
        rotateLockpick = "rotate-lockpick",
        rotateCylinder = "rotate-cylinder",
    },
    lockpickRotationMaxDelta = 0.1,
    lockpickRotationSoundCountdown = 0.5,
    cylinderRotationSoundCountdown = 0.9,
}

return enum
