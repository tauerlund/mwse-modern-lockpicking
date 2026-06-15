---@class skillController : initializedService
local this = {}

---@private
---@type enums
this.enums = nil

---@private
---@type formulas
this.formulas = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type settings
this.settings = nil

---@private
---@type eventHandlers
this.eventHandlers = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.enums = services.enums
	this.formulas = services.formulas
	this.eventRegistrar = services.eventRegistrar
	this.settings = services.settings

	local events = services.enums.events

	this.eventHandlers = {
		[events.lockpickingEnded] = this.onLockpickingEnded,
		[events.pickBroken] = this.onPickBroken,
	}

	this.eventRegistrar.register(this.eventHandlers)
	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers)
end

--- Based on the formula described here: https://en.uesp.net/wiki/Morrowind:Security
---@public
---@param pick tes3itemStack
---@param lock tes3lockNode
---@return number
function this.getSuccessChance(pick, lock)
	return this.formulas.successChance({
		statsModifier = this.getStatsModifier(),
		quality = pick.object.quality,
		fatigueModifier = this.getFatigueModifier(),
		lockLevel = lock.level,
	})
end

---@public
---@return number
function this.getStatsModifier()
	local security = tes3.mobilePlayer:getSkillValue(tes3.skill.security)
	local agility = tes3.mobilePlayer.attributes[tes3.attribute.agility].current
	local luck = tes3.mobilePlayer.attributes[tes3.attribute.luck].current

	return security + (agility / 5 + luck / 10)
end

---@private
---@return number
function this.getFatigueModifier()
	local fatigue = tes3.mobilePlayer.fatigue
	return 0.75 + (0.5 * fatigue.normalized)
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	if e.success then
		this.exerciseSkill()
	end
end

---@private
---@param _ pickBrokenEventData
function this.onPickBroken(_)
	this.exerciseSkill(this.settings.difficulty.pickBreakSkillGain)
end

---@private
---@param multiplier? number
function this.exerciseSkill(multiplier)
	local player = tes3.player.mobile --[[@as tes3mobilePlayer]]
	local skill = tes3.getSkill(tes3.skill.security)
	local increase = skill.actions[this.enums.constants.skills.action.lockpicking]

	player:exerciseSkill(tes3.skill.security, increase * (multiplier or 1))
end

return this
