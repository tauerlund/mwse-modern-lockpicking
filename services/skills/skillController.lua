---@class skillController : initializedService
local this = {}

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.enums = services.enums
	local events = services.enums.events

	event.register(events.lockpickingEnded, this.onLockpickingEnded)
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
	local increase = skill.actions[this.enums.constants.skills.action.lockpicking]

	player:exerciseSkill(tes3.skill.security, increase)
end

return this
