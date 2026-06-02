---@class playerDataController
local this = {}

---@public
---@return playerData
function this.resolve()
    if not tes3.player then
        return {}
    end

    if not tes3.player.data.modernLockpicking then
        tes3.player.data.modernLockpicking = {}
    end

    return tes3.player.data.modernLockpicking
end

return this
