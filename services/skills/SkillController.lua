--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local CONSTANTS = require("tauer.modern-lockpicking.services.skills.enums.constants")
---

---@class SkillController
local this = {}

---@public
function this.Start()
	this.registerEvents()
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

---@private
function this.registerEvents()
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
end

return this
