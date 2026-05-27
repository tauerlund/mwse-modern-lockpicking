--- SERVICES
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm
local strategyLoader = require("tauer.modern-lockpicking.services.strategies.strategyLoader")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

---@class lockpickingActivator : initializedService
local this = {}

---@private
---@type { [string]: activationStrategy }
this.activationStrategies = nil

---@private
---@type activationStrategy
this.currentActivationStrategy = nil

---@public
---@return boolean, string|nil
function this.initialize()
	this.activationStrategies = strategyLoader.loadAll({
		directory = "tauer\\modern-lockpicking\\services\\lockpicking\\activation-strategies",
		requireNotEmpty = true,
	}) --[[@as { [string]: activationStrategy }]]

	if not this.activationStrategies then
		return false, "Failed to load activation strategies"
	end

	this.applyStrategy()
	event.register(EVENTS.settingsUpdated, this.onSettingsUpdated)

	return true, nil
end

---@private
function this.applyStrategy()
	if this.currentActivationStrategy then
		this.currentActivationStrategy.disable()
	end

	this.currentActivationStrategy = this.activationStrategies[settings.activationStrategy]
	this.currentActivationStrategy.enable()
end

---@private
function this.onSettingsUpdated()
	this.applyStrategy()
end

return this
