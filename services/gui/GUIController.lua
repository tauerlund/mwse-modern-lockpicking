--- SERVICES
local GUI = require("tauer.modern-lockpicking.services.gui.GUIBuilder")
local Translations = require("tauer.modern-lockpicking.shared.Translations")
local Settings = require("tauer.modern-lockpicking.shared.Settings").Mcm
local Logger = require("tauer.modern-lockpicking.shared.Logger")
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
---

---@class GUIController : IInitializedService
local this = {}

---@private
---@type tes3uiElement
this.header = nil

---@private
---@type tes3uiElement
this.controls = nil

---@private
---@type tes3uiElement
this.picks = nil

---@public
---@return boolean
function this.Initialize()
	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)

	return true
end

---@private
---@param e lockpickingStartEventData
function this.start(e)
	this.header = this.createHeader(e)
	this.controls = this.createControls()
	this.picks = this.createPicks(e.picks)
end

---@private
---@param e lockpickingStartEventData
---@return tes3uiElement
function this.createHeader(e)
	local header = GUI.CreateMenu({
			id = "tauer.modern-lockpicking.header",
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:WithPositionAlign({ x = 0.5, y = 0.05 })
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithMinSize({ width = 0, height = 0 })
		:WithAutoSize()
		:Build()

	local block = GUI
		.CreateBlock({ parent = header })
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithAutoSize()
		:WithMinSize({ width = 300 })
		:WithBorder({
			all = 8
		})
		:WithChildAlignment({
			x = 0.5,
		})
		:Build()

	GUI.CreateLabel({ parent = block })
		:WithText(e.activator.baseObject.name)
		:WithColor(tes3ui.getPalette(tes3.palette.headerColor))
		:Build()

	GUI.CreateDivider({ parent = block })
		:WithProportional({ width = 1.0 })
		:Build()

	local lockLevel = tes3.getLockLevel({
		reference = e.activator --[[@as tes3reference]],
	})

	local player = tes3.player.mobile --[[@as tes3mobileActor]]
	local securitySkill = player:getSkillValue(tes3.skill.security)

	GUI.CreateLabel({ parent = block })
		:WithText(this.createLockLevelText(lockLevel))
		:WithColor(this.getLockLevelColor(lockLevel, securitySkill))
		:Build()

	return header
end

---@private
---@param level number
---@return string
function this.createLockLevelText(level)
	return string.format("%s: %d", tes3.findGMST(tes3.gmst.sLockLevel).value, level)
end

---@private
---@param level number
---@param skill number
---@return number[]
function this.getLockLevelColor(level, skill)
	local t = math.remap(level - skill, 0, 50, 0, 1)
	t = math.clamp(t, 0, 1)

	local r = t
	local g = 1 - t
	local b = 0
	return { r, g, b }
end

---@private
---@return tes3uiElement
function this.createControls()
	local controls = GUI.CreateMenu({
			id = "tauer.modern-lockpicking.controls",
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:WithPositionAlign({ x = 0.5, y = 0.95 })
		:WithAutoSize()
		:Build()

	local outerBlock = GUI.CreateBlock({ parent = controls })
		:WithAutoSize()
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithChildAlignment({
			x = 0.5,
		})
		:Build()

	GUI.CreateLabel({ parent = outerBlock })
		:WithText(Translations.Get("interface.controls.header"))
		:WithColor(tes3ui.getPalette(tes3.palette.headerColor))
		:Build()

	local innerBlock = GUI.CreateThinBorder({ parent = outerBlock })
		:WithFlowDirection(tes3.flowDirection.leftToRight)
		:WithAutoSize()
		:WithPadding({
			all = 8,
		})
		:WithBorder({
			top = 8,
		})
		:WithChildAlignment({
			x = 0.5,
			y = 0.5,
		})
		:Build()

	local controlTexts = this.getControlTexts()

	for i, text in ipairs(controlTexts) do
		GUI.CreateLabel({ parent = innerBlock })
			:WithText(text)
			:WithColor(tes3ui.getPalette(tes3.palette.normalColor))
			:Build()

		if i < #controlTexts then
			GUI.CreateThinBorder({ parent = innerBlock })
				:WithSize({ width = 1, height = 24 })
				:WithBorder({
					left = 12,
					right = 12,
				})
				:Build()
		end
	end

	return controls
end

---@private
---@return string[]
function this.getControlTexts()
	local mouse = tes3.findGMST(tes3.gmst.sMouse).value

	local rotateLockLeft = this.getKeyName(Settings.keyBinds.rotateLockLeft)
	local rotateLockRight = this.getKeyName(Settings.keyBinds.rotateLockRight)

	local cyclePreviousPick = this.getKeyName(Settings.keyBinds.cyclePreviousPick)
	local cycleNextPick = this.getKeyName(Settings.keyBinds.cycleNextPick)

	local exit = this.getKeyName(Settings.keyBinds.exit)

	return {
		string.format("%s: %s", Translations.Get("interface.controls.rotatePick"), mouse),
		string.format("%s: %s / %s", Translations.Get("interface.controls.rotateLock"), rotateLockLeft, rotateLockRight),
		string.format("%s: %s / %s", Translations.Get("interface.controls.cyclePicks"), cyclePreviousPick, cycleNextPick),
		string.format("%s: %s", Translations.Get("interface.controls.exit"), exit),
	}
end

---@private
---@param keyBind keyBind
---@return string|number
function this.getKeyName(keyBind)
	return tes3.findGMST(string.format("sKeyName_%02X", keyBind.keyCode)).value
end

---@private
---@param picks tes3itemStack[]
---@return tes3uiElement
function this.createPicks(picks)
	local picksMenu = GUI.CreateMenu({
			id = "tauer.modern-lockpicking.picks",
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithPositionAlign({ x = 0.75, y = 0.25 })
		:WithAutoSize()
		:Build()

	local upperBlock = GUI.CreateBlock({ parent = picksMenu })
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithAutoSize()
		:WithPadding({
			all = 8,
		})
		:Build()

	GUI.CreateLabel({ parent = upperBlock })
		:WithText(Translations.Get("interface.picks.header"))
		:WithColor(tes3ui.getPalette(tes3.palette.headerColor))
		:Build()

	local lowerBlock = GUI.CreateThinBorder({ parent = picksMenu })
		:WithFlowDirection(tes3.flowDirection.leftToRight)
		:WithPadding({
			all = 8,
		})
		:WithAutoSize()
		:Build()

	local pickNameBlock = GUI.CreateBlock({ parent = lowerBlock })
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithAutoSize()
		:Build()

	local pickCountBlock = GUI.CreateBlock({ parent = lowerBlock })
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithAutoSize()
		:Build()

	for _, pick in ipairs(picks) do
		GUI.CreateLabel({ parent = pickNameBlock })
			:WithText(pick.object.name)
			:WithColor(tes3ui.getPalette(tes3.palette.normalColor))
			:WithBorder({
				top = 4,
				bottom = 4,
				right = 16,
			})
			:Build()

		GUI.CreateLabel({ parent = pickCountBlock })
			:WithText(string.format("%d", this.getLockpickCount(pick)))
			:WithColor(tes3ui.getPalette(tes3.palette.normalColor))
			:WithBorder({
				top = 4,
				bottom = 4,
			})
			:Build()
	end

	return picksMenu
end

---@private
---@param pick tes3itemStack
---@return integer
function this.getLockpickCount(pick)
	local totalPicks = 0
	local newPicks = pick.count

	local variables = pick.variables
	if variables then
		for _, variable in pairs(variables) do
			totalPicks = totalPicks + variable.condition
			newPicks = newPicks - 1
		end
	end

	return totalPicks + (newPicks * pick.object.maxCondition)
end

---@private
function this.stop()
	this.header:destroy()
	this.controls:destroy()
	this.picks:destroy()
end

---@private
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.start(e)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded, { doOnce = true })
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.stop()
end

return this
