local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local CONSTANTS = require("tauer.modern-lockpicking.services.sounds.enums.constants")

---@class SoundController : IInitializedService
local this = {}

---@public
function this.Initialize()
	this.registerEvents()
	return true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnd(_)
	tes3.playSound({
		reference = tes3.player,
		soundPath = string.format("%s/%s.wav", CONSTANTS.basePath, table.choice(CONSTANTS.sounds.unlock)),
	})
end

---@private
---@param _ pickChangeEventData
function this.onPickChange(_)
	tes3.playSound({
		reference = tes3.player,
		soundPath = string.format("%s/%s.wav", CONSTANTS.basePath, table.choice(CONSTANTS.sounds.lockpicks)),
	})
end

---@private
function this.registerEvents()
	event.register(EVENTS.lockpickingEnd, this.onLockpickingEnd)
	event.register(EVENTS.pickChange, this.onPickChange)
end

return this
