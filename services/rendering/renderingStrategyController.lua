---@class renderingStrategyController : initializedService
local this = {}

---@private
---@type { [string]: renderingStrategy }
this.strategies = nil

---@private
---@type renderingStrategy
this.activeStrategy = nil

---@private
---@type niNode|nil
this.currentMesh = nil

---@private
---@type settings
this.settings = nil

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
this.eventHandlers = {
	lifetime = {}
}

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.strategies = services.strategyLoader.loadAll({
		directory = "tauer\\modern-lockpicking\\services\\rendering\\rendering-strategies",
		requireNotEmpty = true,
	}) --[[@as { [string]: renderingStrategy }]]

	if not this.strategies then
		return false, "Failed to load rendering strategies"
	end

	this.settings = services.settings
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar

	this.activeStrategy = this.resolveStrategy()

	if not this.activeStrategy then
		return false, "Failed to resolve rendering strategy"
	end

	local events = services.enums.events
	this.eventHandlers = {
		lifetime = {
			[events.settingsUpdated] = this.onSettingsUpdated,
		}
	}
	this.eventRegistrar.register(this.eventHandlers.lifetime)

	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
	this.activeStrategy = nil
	this.strategies = nil
	this.currentMesh = nil
end

---@private
---@return renderingStrategy
function this.resolveStrategy()
	local names = this.enums.renderingStrategyNames
	local name = this.settings.litRendering and names.armCamera or names.menuCamera
	return this.strategies[name]
end

---@private
function this.onSettingsUpdated()
	local newStrategy = this.resolveStrategy()
	if newStrategy == this.activeStrategy then
		return
	end

	local mesh = this.currentMesh
	if mesh then
		this.activeStrategy.detachMesh(mesh)
	end

	this.activeStrategy = newStrategy

	if mesh then
		this.activeStrategy.attachMesh(mesh)
	end
end

---@public
---@param mesh niNode
function this.attachMesh(mesh)
	this.currentMesh = mesh
	this.activeStrategy.attachMesh(mesh)
end

---@public
---@param mesh niNode
function this.detachMesh(mesh)
	this.activeStrategy.detachMesh(mesh)
	this.currentMesh = nil
end

---@public
---@return niCamera
function this.getNiCamera()
	return this.activeStrategy.getNiCamera()
end

---@public
---@return niNode
function this.getGhostAttachmentNode()
	return this.activeStrategy.getGhostAttachmentNode()
end

---@public
---@return number
function this.getTargetDistance()
	return this.activeStrategy.getTargetDistance()
end

return this
