local logger = mwse.Logger.new()

--- SERVICES
local lockpickingController = require("tauer.modern-lockpicking.services.lockpicking.lockpickingController")
local lockpickingInputHandler = require("tauer.modern-lockpicking.services.lockpicking.lockpickingInputHandler")
local lockpickingActivator = require("tauer.modern-lockpicking.services.lockpicking.lockpickingActivator")
local lockMeshResolver = require("tauer.modern-lockpicking.services.locks.lockMeshResolver")
local soundController = require("tauer.modern-lockpicking.services.sounds.soundController")
local skillController = require("tauer.modern-lockpicking.services.skills.skillController")
local guiController = require("tauer.modern-lockpicking.services.gui.guiController")
local lockAnimator = require("tauer.modern-lockpicking.services.locks.lockAnimator")
local lockController = require("tauer.modern-lockpicking.services.locks.lockController")
local knifeAnimator = require("tauer.modern-lockpicking.services.knives.knifeAnimator")
local cylinderAnimator = require("tauer.modern-lockpicking.services.cylinders.cylinderAnimator")
local cylinderController = require("tauer.modern-lockpicking.services.cylinders.cylinderController")
local pickAnimator = require("tauer.modern-lockpicking.services.picks.pickAnimator")
local pickController = require("tauer.modern-lockpicking.services.picks.pickController")
local renderingController = require("tauer.modern-lockpicking.services.rendering.renderingController")
local soundFileResolver = require("tauer.modern-lockpicking.services.sounds.soundFileResolver")
local mcm = require("tauer.modern-lockpicking.services.mcm.mcmInitializer")
---

---@class ModernLockpicking
local this = {}

---@package
---@param _ modConfigReadyEventData
function this.initializeMcm(_)
	mcm.initialize()
end

---@package
---@param _ initializedEventData
function this.initializeMod(_)
	logger:info("Initializing...")

	---@type initializedService[]
	local services = {
		lockpickingController,
		lockpickingInputHandler,
		lockpickingActivator,
		lockMeshResolver,
		soundController,
		guiController,
		lockAnimator,
		lockController,
		knifeAnimator,
		cylinderAnimator,
		cylinderController,
		pickAnimator,
		pickController,
		renderingController,
		skillController,
		soundFileResolver,
	}

	for _, service in pairs(services) do
		local initialized, reason = service.initialize()
		if not initialized then
			logger:error("Initialization failed. Reason: %s", reason)
			return
		end
	end

	logger:info("Initialized.")
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
