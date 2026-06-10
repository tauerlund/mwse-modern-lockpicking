---@class ModernLockpicking
local this = {}

---@private
this.services = require("tauer.modern-lockpicking.services")

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
	this.logger:info("Initializing...")

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

	local success, reason = this.initializeServices(initializedServices)

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
function this.initializeServices(initializedServices)
	for _, service in ipairs(initializedServices) do
		if service.dependencies then
			local dependencies = service.dependencies(this.services)
			for _, dependency in ipairs(dependencies) do
				if not dependency.initialized then
					return false, string.format("'%s' must be initialized before '%s'", dependency.name, service.name)
				end
			end
		end

		service.initialized = false

		local success, reason = service.initialize(this.services)
		if not success then
			return false, string.format("'%s' could not be initialized because %s", service.name, reason)
		end

		service.initialized = true
	end

	return true, nil
end

---@private
---@param initializedServices initializedService[]
function this.uninitializeServices(initializedServices)
	for _, service in ipairs(initializedServices) do
		if service.initialized and service.uninitialize then
			service.uninitialize()
		end
	end
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
