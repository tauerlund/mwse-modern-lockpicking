local events = require("tauer.modern-lockpicking.shared.enums.events")

---@class SoundController : InitializedService
local this = {}

---@public
function this.Initialize()
	event.register(events.lockpickingEnded, this.onLockUnlocked)
	return true
end

---@private
function this.onLockUnlocked() end

return this
