---@class ModernLockpicking
local this = {}

---@private
this.tests = require("tauer.modern-lockpicking.tests")

---@private
this.services = require("tauer.modern-lockpicking.services")

---@private
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
	if this.tests.enabled then
		this.tests.run()
	end

	local services = this.services

	---@type initializedService[]
	local initializedServices = {
		services.nodeAnimator,
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
		services.pickOverrideResolver,
		services.pickSpawnAnimator,
		services.pickSessionAnimator,
		services.skillController,
		services.guiController,
		services.renderingController,
		services.inventoryController,
		services.eventLogger,
		services.debuggingRenderer,
		services.playerController,
	}

	this.initializer.initialize(services, initializedServices)
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
