---@class renderingStrategyController : initializedService
local this = {}

---@private
---@type { [string]: renderingStrategy }
this.strategies = nil

---@private
---@type renderingStrategy
this.activeStrategy = nil

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

	local strategyName = services.enums.renderingStrategyNames.armCamera
	this.activeStrategy = this.strategies[strategyName]

	if not this.activeStrategy then
		return false, string.format("Rendering strategy '%s' not found", strategyName)
	end

	return true, nil
end

---@public
function this.uninitialize()
	this.activeStrategy = nil
	this.strategies = nil
end

---@public
---@param mesh niNode
function this.attachMesh(mesh)
	this.activeStrategy.attachMesh(mesh)
end

---@public
---@param mesh niNode
function this.detachMesh(mesh)
	this.activeStrategy.detachMesh(mesh)
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
