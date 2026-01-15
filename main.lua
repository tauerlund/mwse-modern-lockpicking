local Logger = require("tauer.modern-lockpicking.shared.loggingFactory")
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

---@class ModernLockpicking
local this = {}

---@private
function this.initializeMcm()
	dofile("Data Files\\MWSE\\mods\\tauer\\modern-lockpicking\\mcm.lua")
end

---@private
function this.initializeMod()
	Logger:info("Initializing...")

	---@type IInitializedService[]
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
		local initialized = service.Initialize()
		if not initialized then
			Logger:error("Initialization failed.")
			return
		end
	end

	event.register(tes3.event.load, this.stopMod)
	event.register(tes3.event.loaded, this.startMod)

	Logger:info("Initialized.")
end

function this.stopMod()
	playerController.Stop()
end

function this.startMod()
	playerController.Start()
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
