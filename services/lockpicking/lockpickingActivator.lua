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

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlers
this.eventHandlers = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.enums = services.enums
	this.settings = services.settings
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.activationStrategies = services.strategyLoader.loadAll({
		directory = "tauer\\modern-lockpicking\\services\\lockpicking\\activation-strategies",
		requireNotEmpty = true,
	}) --[[@as { [string]: activationStrategy }]]

	if not this.activationStrategies then
		return false, "Failed to load activation strategies"
	end

	this.eventHandlers = {
		[events.settingsUpdated] = this.onSettingsUpdated,
	}

	this.eventRegistrar.register(this.eventHandlers)
	this.applyStrategy()

	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
function this.applyStrategy()
	if this.currentActivationStrategy then
		this.currentActivationStrategy.disable()
	end

	local strategyName = this.settings.activationStrategy or this.enums.activationStrategyNames.default

	this.currentActivationStrategy = this.activationStrategies[strategyName]
	this.currentActivationStrategy.enable()
end

---@private
function this.onSettingsUpdated()
	this.applyStrategy()
end

return this
