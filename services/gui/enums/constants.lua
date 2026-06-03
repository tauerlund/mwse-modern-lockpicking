---@enum guiConstants
local enum = {
    headerId = "tauer.modern-lockpicking.gui.header",
    controlsId = "tauer.modern-lockpicking.gui.controls",
    controlsLabelId = "tauer.modern-lockpicking.gui.controls.labels.%d",
    picksId = "tauer.modern-lockpicking.gui.picks",
    picksLabelId = "tauer.modern-lockpicking.gui.picks.labels.%s",
    picksCountLabelId = "tauer.modern-lockpicking.gui.picks.count.labels.%s",
    pickPalette = {
        active = tes3.palette.normalOverColor,
        inactive = tes3.palette.normalColor,
        ineligible = tes3.palette.negativeColor,
    },
}

return enum
