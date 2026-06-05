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
		services.pickAnimator,
		services.skillController,
		services.guiController,
		services.renderingController,
		services.inventoryController,
		services.eventLogger,
		services.debuggingRenderer,
	}

	local success, reason = this.intializeServices(initializedServices)

	if not success then
		this.logger:error("Initialization failed. Reason: %s", reason)
		this.uninitializeServices(initializedServices)
		return
	end

	this.logger:info("Initialized.")
end

---@private
---@param initializedServices initializedService[]
---@return boolean, reason
function this.intializeServices(initializedServices)
	for _, service in ipairs(initializedServices) do
		service.initalized = false

		local success, reason = service.initialize(this.services)
		if not success then
			return false, string.format("'%s' could not be initialized because %s", service.name, reason)
		end

		service.initalized = true
	end

	return true, nil
end

---@private
---@param initializedServices initializedService[]
function this.uninitializeServices(initializedServices)
	for _, service in ipairs(initializedServices) do
		if service.initalized and service.uninitialize then
			service.uninitialize()
		end
	end
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
