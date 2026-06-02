--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
---

---@class lockpickingActivator : initializedService
local this = {}

---@private
---@type settings
this.settings = nil

---@private
---@type strategyLoader
this.strategyLoader = nil

---@private
---@type { [string]: activationStrategy }
this.activationStrategies = nil

---@private
---@type activationStrategy
this.currentActivationStrategy = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.settings = services.settings

	this.activationStrategies = services.strategyLoader.loadAll({
		directory = "tauer\\modern-lockpicking\\services\\lockpicking\\activation-strategies",
		requireNotEmpty = true,
	}) --[[@as { [string]: activationStrategy }]]

	if not this.activationStrategies then
		return false, "Failed to load activation strategies"
	end

	event.register(EVENTS.settingsUpdated, this.onSettingsUpdated)
	this.applyStrategy()

	return true, nil
end

---@private
function this.applyStrategy()
	if this.currentActivationStrategy then
		this.currentActivationStrategy.disable()
	end

	this.currentActivationStrategy = this.activationStrategies[this.settings.activationStrategy]
	this.currentActivationStrategy.enable()
end

---@private
function this.onSettingsUpdated()
	this.applyStrategy()
end

return this
