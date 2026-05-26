--- SERVICES
local gui = require("tauer.modern-lockpicking.services.gui.guiBuilder")
local translations = require("tauer.modern-lockpicking.shared.translations")
local settings = require("tauer.modern-lockpicking.shared.settings").Mcm
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.shared.enums.events")
local CONSTANTS = require("tauer.modern-lockpicking.services.gui.enums.constants")
---

---@class guiController : initializedService
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
	this.registerEvents()
	return true
end

---@private
---@param e lockpickingStartEventData
function this.start(e)
	if not this.header then
		this.header = this.createHeader(e)
	end

	if not this.controls then
		this.controls = this.createControls()
	end

	if not this.picks then
		this.picks = this.createPicks(e.pick, e.picks)
	end
end

---@private
---@param e lockpickingStartEventData
---@return tes3uiElement
function this.createHeader(e)
	local header = gui.CreateMenu({
			id = CONSTANTS.headerId,
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:WithPositionAlign({ x = 0.5, y = 0.05 })
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithMinSize({ width = 0, height = 0 })
		:WithAutoSize()
		:Build()

	local block = gui
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

	gui.CreateLabel({ parent = block })
		:WithText(e.activator.baseObject.name)
		:WithColor(tes3ui.getPalette(tes3.palette.headerColor))
		:Build()

	gui.CreateDivider({ parent = block })
		:WithProportional({ width = 1.0 })
		:Build()

	local lockLevel = tes3.getLockLevel({
		reference = e.activator --[[@as tes3reference]],
	})

	local player = tes3.player.mobile --[[@as tes3mobileActor]]
	local securitySkill = player:getSkillValue(tes3.skill.security)

	gui.CreateLabel({ parent = block })
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
	local controls = gui.CreateMenu({
			id = CONSTANTS.controlsId,
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:WithPositionAlign({ x = 0.5, y = 0.95 })
		:WithAutoSize()
		:Build()

	local outerBlock = gui.CreateBlock({ parent = controls })
		:WithAutoSize()
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithChildAlignment({
			x = 0.5,
		})
		:Build()

	gui.CreateLabel({ parent = outerBlock })
		:WithText(translations.Get("interface.controls.header"))
		:WithColor(tes3ui.getPalette(tes3.palette.headerColor))
		:Build()

	local innerBlock = gui.CreateThinBorder({ parent = outerBlock })
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
		:WithCallback(EVENTS.keyBindsUpdated, this.onKeyBindsUpdated)
		:Build()

	local controlTexts = this.getControlTexts()

	for i, text in ipairs(controlTexts) do
		gui.CreateLabel({ parent = innerBlock, id = string.format(CONSTANTS.controlsLabelId, i) })
			:WithText(text)
			:WithColor(tes3ui.getPalette(tes3.palette.normalColor))
			:Build()

		if i < #controlTexts then
			gui.CreateThinBorder({ parent = innerBlock })
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

	local rotateLockCounterclockwise = this.getKeyName(settings.keyBinds.rotateLockCounterclockwise)
	local rotateLockClockwise = this.getKeyName(settings.keyBinds.rotateLockClockwise)

	local cyclePreviousPick = this.getKeyName(settings.keyBinds.cyclePreviousPick)
	local cycleNextPick = this.getKeyName(settings.keyBinds.cycleNextPick)

	local exit = this.getKeyName(settings.keyBinds.exit)

	return {
		string.format("%s: %s", translations.Get("interface.controls.rotatePick"), mouse),
		string.format("%s: %s / %s", translations.Get("interface.controls.rotateLock"), rotateLockCounterclockwise,
			rotateLockClockwise),
		string.format("%s: %s / %s", translations.Get("interface.controls.cyclePicks"), cyclePreviousPick, cycleNextPick),
		string.format("%s: %s", translations.Get("interface.controls.exit"), exit),
	}
end

---@private
---@param keyBind keyBind
---@return string|number
function this.getKeyName(keyBind)
	return tes3.findGMST(string.format("sKeyName_%02X", keyBind.keyCode)).value
end

---@private
---@param activePick pick
---@param picks tes3itemStack[]
---@return tes3uiElement
function this.createPicks(activePick, picks)
	local picksMenu = gui.CreateMenu({
			id = CONSTANTS.picksId,
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithPositionAlign({ x = 0.75, y = 0.25 })
		:WithAutoSize()
		:Build()

	local upperBlock = gui.CreateBlock({ parent = picksMenu })
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithAutoSize()
		:WithPadding({
			all = 8,
		})
		:Build()

	gui.CreateLabel({ parent = upperBlock })
		:WithText(translations.Get("interface.picks.header"))
		:WithColor(tes3ui.getPalette(tes3.palette.headerColor))
		:Build()

	local lowerBlock = gui.CreateThinBorder({ parent = picksMenu })
		:WithFlowDirection(tes3.flowDirection.leftToRight)
		:WithPadding({
			all = 8,
		})
		:WithAutoSize()
		:Build()

	local pickLabelContainer = gui.CreateBlock({ parent = lowerBlock })
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithAutoSize()
		:Build()

	local pickCountLabelContainer = gui.CreateBlock({ parent = lowerBlock })
		:WithFlowDirection(tes3.flowDirection.topToBottom)
		:WithAutoSize()
		:Build()

	for _, pick in ipairs(picks) do
		local color = pick.object.id == activePick.item.object.id and
			tes3ui.getPalette(tes3.palette.normalOverColor) or
			tes3ui.getPalette(tes3.palette.normalColor)

		local verticalBorder = 8
		local horizontalBorder = 16

		gui.CreateLabel({
			parent = pickLabelContainer,
			id = string.format(CONSTANTS.picksLabelId,
				pick.object.id)
		})
			:WithText(pick.object.name)
			:WithColor(color)
			:WithBorder({
				top = verticalBorder,
				bottom = verticalBorder,
				right = horizontalBorder,
			})
			:WithCallback(EVENTS.pickChange, this.onPickChange)
			:WithCallback(EVENTS.pickSelected, this.onPickSelected)
			:Build()

		gui.CreateLabel({
			parent = pickCountLabelContainer,
			id = string.format(CONSTANTS.picksCountLabelId,
				pick.object.id)
		})
			:WithText(string.format("%d", this.getLockpickCount(pick)))
			:WithColor(color)
			:WithBorder({
				top = verticalBorder,
				bottom = verticalBorder,
			})
			:WithCallback(EVENTS.pickChange, this.onPickChange)
			:WithCallback(EVENTS.pickSelected, this.onPickSelected)
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
	if this.header then
		this.header:destroy()
		this.header = nil
	end

	if this.controls then
		this.controls:destroy()
		this.controls = nil
	end

	if this.picks then
		this.picks:destroy()
		this.picks = nil
	end
end

---@private
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.start(e)
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.stop()
end

---@private
---@param _ loadEventData
function this.onLoad(_)
	this.stop()
end

---@private
---@param element tes3uiElement
function this.onKeyBindsUpdated(element)
	local texts = this.getControlTexts()
	for i, text in ipairs(texts) do
		local label = element:findChild(string.format(CONSTANTS.controlsLabelId, i))
		if not label then
			return
		else
			label.text = text
		end
	end
end

---@private
---@param element tes3uiElement
---@param _ pickChangeEventData
function this.onPickChange(element, _)
	element.color = tes3ui.getPalette(tes3.palette.normalColor)
end

---@private
---@param element tes3uiElement
---@param e pickSelectedEventData
function this.onPickSelected(element, e)
	if element.name:endswith(e.pick.item.object.id) then
		element.color = tes3ui.getPalette(tes3.palette.normalOverColor)
	end
end

---@private
function this.registerEvents()
	event.register(tes3.event.load, this.onLoad)
	event.register(EVENTS.lockpickingStart, this.onLockpickingStart)
	event.register(EVENTS.lockpickingEnded, this.onLockpickingEnded)
end

return this
