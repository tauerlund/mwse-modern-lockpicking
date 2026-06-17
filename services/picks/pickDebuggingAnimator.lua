---@class pickDebuggingAnimator : initializedService
local this = {}

local debugSliderPanel = require("tauer.modern-lockpicking.services.debugging.debugSliderPanel")

---@private
---@type settings
this.settings = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type tes3uiElement[]|nil
this.panels = nil

---@private
---@type eventHandlerGroups
this.eventHandlers = {
	lifetime = {},
}

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.settings = services.settings
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.pickSpawnFinished] = this.onPickSpawnFinished,
			[events.lockpickingEnded] = this.onLockpickingEnded,
		}
	}

	this.eventRegistrar.register(this.eventHandlers.lifetime)
	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
end

---@private
---@param e pickSpawnFinishedEventData
function this.onPickSpawnFinished(e)
	if not this.settings.debugging.showPickDebugger then
		return
	end

	local mesh = e.pick.mesh
	local helper = e.pick.helper
	local baseRotation = mesh.rotation:copy()
	local helperBuffer = tes3matrix33.new()
	helperBuffer:toRotationY(0)

	local function applyComposed()
		mesh.rotation = baseRotation * helperBuffer
		mesh:update()
	end

	this.panels = debugSliderPanel.createTransformSliders(mesh, {
		applyRotation = function (newBase)
			baseRotation = newBase
			applyComposed()
		end
	})

	local helperPanel = debugSliderPanel.create({
		title = "Pick Helper",
		position = { x = 0.7, y = 0.02 },
		sliders = {
			{
				label = "Y",
				min = -math.rad(90),
				max = math.rad(90),
				step = 0.01,
				default = 0,
				onChange = function (angle)
					helperBuffer:toRotationY(angle)
					helper.rotation = helperBuffer
					helper:update()
					applyComposed()
				end
			},
		},
	})

	table.insert(this.panels, helperPanel)
end

---@private
function this.onLockpickingEnded()
	if not this.panels then
		return
	end
	for _, panel in ipairs(this.panels) do
		panel:destroy()
	end
	this.panels = nil
end

return this
