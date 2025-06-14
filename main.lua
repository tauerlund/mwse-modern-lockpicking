local Logger = require("tauer.modern-lockpicking.shared.Logger")
local LockMeshResolver = require("tauer.modern-lockpicking.services.locks.LockMeshResolver")
local SoundController = require("tauer.modern-lockpicking.services.sounds.SoundController")
local PlayerController = require("tauer.modern-lockpicking.services.player.PlayerController")
local SkillController = require("tauer.modern-lockpicking.services.skills.SkillController")
local GUIController = require("tauer.modern-lockpicking.services.gui.GUIController")

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
		LockMeshResolver,
		SoundController,
		GUIController,
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

function this.stopMod() end

function this.startMod()
	SkillController.Start()
	PlayerController.Start()
end

event.register(tes3.event.modConfigReady, this.initializeMcm)
event.register(tes3.event.initialized, this.initializeMod)
