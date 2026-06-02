--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local CONSTANTS = require("tauer.modern-lockpicking.services.skills.enums.CONSTANTS")
---

---@class skillController : initializedService
local this = {}

---@public
---@param _ serviceCollection
---@return boolean,string|nil
function this.initialize(_)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
	return true, nil
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	if e.success then
		this.exerciseSkill()
	end
end

---@private
function this.exerciseSkill()
	local player = tes3.player.mobile --[[@as tes3mobilePlayer]]
	local skill = tes3.getSkill(tes3.skill.security)
	local increase = skill.actions[CONSTANTS.action.lockpicking]

	player:exerciseSkill(tes3.skill.security, increase)
end

return this
