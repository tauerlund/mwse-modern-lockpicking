---@class ModernLockpicking
local this = {}

---@private
---@type serviceCollection
this.services = require("tauer.modern-lockpicking.services")

---@private
---@type mwseLogger
this.logger = mwse.Logger.new()

---@package
---@param _ modConfigReadyEventData
function this.initializeMcm(_)
	this.services.mcmInitializer.initialize(this.services)
end

---@package
---@param _ initializedEventData
function this.initializeMod(_)
	this.logger:info("Initializing...")

	local services = this.services

	---@type initializedService[]
	local initializedServices = {
		services.strategyLoader,
		services.lockpickingController,
		services.lockpickingActivator,
		services.lockController,
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
		services.pickAnimator,
		services.skillController,
		services.guiController,
		services.renderingController,
		services.inventoryController,
		services.eventLogger,
		services.debuggingRenderer,
		services.timerManager,
	}

	for _, service in pairs(initializedServices) do
		local initialized, reason = service.initialize(services)
		if not initialized then
			this.logger:error("Initialization failed. Reason: %s", reason)
			return
		end
	end

	this.logger:info("Initialized.")
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
