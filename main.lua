---@class ModernLockpicking
local this = {}

---@private
this.services = require("tauer.modern-lockpicking.services")

---@private
---@type initializer
this.initializer = require("tauer.modern-lockpicking.initializer")

---@private
this.logger = mwse.Logger.new()

---@package
---@param _ modConfigReadyEventData
function this.initializeMcm(_)
	this.services.mcmInitializer.initialize(this.services)
end

---@package
---@param _ initializedEventData
function this.initializeMod(_)
	local services = this.services

	---@type initializedService[]
	local initializedServices = {
		services.strategyLoader,
		services.renderingStrategyController,
		services.pickBreakAnimator,
		services.lockpickingCircuitBreaker,
		services.lockpickingController,
		services.lockpickingActivator,
		services.lockController,
		services.lockMeshLoader,
		services.lockMeshValidator,
		services.lockMeshResolver,
		services.lockSpawner,
		services.lockAnimator,
		services.cylinderController,
		services.cylinderAnimator,
		services.knifeSpawner,
		services.knifeAnimator,
		services.soundController,
		services.soundFileResolver,
		services.pickController,
		services.pickSelector,
		services.pickSpawner,
		services.pickSessionAnimator,
		services.skillController,
		services.guiController,
		services.renderingController,
		services.inventoryController,
		services.eventLogger,
		services.debuggingRenderer,
	}

	this.initializer.initialize(services, initializedServices)
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
