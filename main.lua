local logger = mwse.Logger.new()
local lockpickingController = require("tauer.modern-lockpicking.services.lockpicking.lockpickingController")
local lockMeshResolver = require("tauer.modern-lockpicking.services.locks.lockMeshResolver")
local soundController = require("tauer.modern-lockpicking.services.sounds.soundController")
local playerController = require("tauer.modern-lockpicking.services.player.playerController")
local skillController = require("tauer.modern-lockpicking.services.skills.skillController")
local guiController = require("tauer.modern-lockpicking.services.gui.guiController")
local lockAnimator = require("tauer.modern-lockpicking.services.locks.lockAnimator")
local knifeAnimator = require("tauer.modern-lockpicking.services.knives.knifeAnimator")
local cylinderAnimator = require("tauer.modern-lockpicking.services.cylinders.cylinderAnimator")
local pickAnimator = require("tauer.modern-lockpicking.services.picks.pickAnimator")
local renderingController = require("tauer.modern-lockpicking.services.rendering.renderingController")
local soundFileResolver = require("tauer.modern-lockpicking.services.sounds.soundFileResolver")
local mcm = require("tauer.modern-lockpicking.services.mcm.mcmInitializer")

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
		lockMeshResolver,
		soundController,
		guiController,
		lockAnimator,
		knifeAnimator,
		cylinderAnimator,
		pickAnimator,
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

	event.register(tes3.event.load, this.stopMod)
	event.register(tes3.event.loaded, this.startMod)

	logger:info("Initialized.")
end

function this.stopMod()
	playerController.stop()
end

function this.startMod()
	playerController.start()
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
