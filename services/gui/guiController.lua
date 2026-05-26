--- SERVICES
local gui = require("tauer.modern-lockpicking.services.gui.guiBuilder")
local translations = require("tauer.modern-lockpicking.services.translations.translations")
local settings = require("tauer.modern-lockpicking.services.mcm.mcmSettings").mcm
---

--- ENUMS
local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local TRANSLATION_KEY = require("tauer.modern-lockpicking.services.translations.enums.TRANSLATION_KEY")
local CONSTANTS = require("tauer.modern-lockpicking.services.gui.enums.CONSTANTS")
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
---@return boolean,string|nil
function this.initialize()
	this.registerEvents()
	return true, nil
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
	local header = gui.createMenu({
			id = CONSTANTS.headerId,
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:withPositionAlign({ x = 0.5, y = 0.05 })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withMinSize({ width = 0, height = 0 })
		:withAutoSize()
		:wuild()

	local block = gui
		.createBlock({ parent = header })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:withMinSize({ width = 300 })
		:withBorder({
			all = 8
		})
		:withChildAlignment({
			x = 0.5,
		})
		:wuild()

	gui.createLabel({ parent = block })
		:withText(e.activator.baseObject.name)
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:wuild()

	gui.createDivider({ parent = block })
		:withProportional({ width = 1.0 })
		:wuild()

	local lockLevel = tes3.getLockLevel({
		reference = e.activator --[[@as tes3reference]],
	})

	local player = tes3.player.mobile --[[@as tes3mobileActor]]
	local securitySkill = player:getSkillValue(tes3.skill.security)

	gui.createLabel({ parent = block })
		:withText(this.createLockLevelText(lockLevel))
		:withColor(this.getLockLevelColor(lockLevel, securitySkill))
		:wuild()

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
	local controls = gui.createMenu({
			id = CONSTANTS.controlsId,
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:withPositionAlign({ x = 0.5, y = 0.95 })
		:withAutoSize()
		:wuild()

	local outerBlock = gui.createBlock({ parent = controls })
		:withAutoSize()
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withChildAlignment({
			x = 0.5,
		})
		:wuild()

	gui.createLabel({ parent = outerBlock })
		:withText(translations.get(TRANSLATION_KEY.interfaceControlsHeader))
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:wuild()

	local innerBlock = gui.createThinBorder({ parent = outerBlock })
		:withFlowDirection(tes3.flowDirection.leftToRight)
		:withAutoSize()
		:withPadding({
			all = 8,
		})
		:withBorder({
			top = 8,
		})
		:withChildAlignment({
			x = 0.5,
			y = 0.5,
		})
		:withCallback(EVENTS.keyBindsUpdated, this.onKeyBindsUpdated)
		:wuild()

	local controlTexts = this.getControlTexts()

	for i, text in ipairs(controlTexts) do
		gui.createLabel({ parent = innerBlock, id = string.format(CONSTANTS.controlsLabelId, i) })
			:withText(text)
			:withColor(tes3ui.getPalette(tes3.palette.normalColor))
			:wuild()

		if i < #controlTexts then
			gui.createThinBorder({ parent = innerBlock })
				:withSize({ width = 1, height = 24 })
				:withBorder({
					left = 12,
					right = 12,
				})
				:wuild()
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
		string.format("%s: %s", translations.get(TRANSLATION_KEY.interfaceControlsRotatePick), mouse),
		string.format("%s: %s / %s", translations.get(TRANSLATION_KEY.interfaceControlsRotateLock),
			rotateLockCounterclockwise, rotateLockClockwise),
		string.format("%s: %s / %s", translations.get(TRANSLATION_KEY.interfaceControlsCyclePicks), cyclePreviousPick,
			cycleNextPick),
		string.format("%s: %s", translations.get(TRANSLATION_KEY.interfaceControlsExit), exit),
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
	local picksMenu = gui.createMenu({
			id = CONSTANTS.picksId,
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withPositionAlign({ x = 0.75, y = 0.25 })
		:withAutoSize()
		:wuild()

	local upperBlock = gui.createBlock({ parent = picksMenu })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:withPadding({
			all = 8,
		})
		:wuild()

	gui.createLabel({ parent = upperBlock })
		:withText(translations.get(TRANSLATION_KEY.interfacePicksHeader))
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:wuild()

	local lowerBlock = gui.createThinBorder({ parent = picksMenu })
		:withFlowDirection(tes3.flowDirection.leftToRight)
		:withPadding({
			all = 8,
		})
		:withAutoSize()
		:wuild()

	local pickLabelContainer = gui.createBlock({ parent = lowerBlock })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:wuild()

	local pickCountLabelContainer = gui.createBlock({ parent = lowerBlock })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:wuild()

	for _, pick in ipairs(picks) do
		local color = pick.object.id == activePick.item.object.id and
			tes3ui.getPalette(tes3.palette.normalOverColor) or
			tes3ui.getPalette(tes3.palette.normalColor)

		local verticalBorder = 8
		local horizontalBorder = 16

		gui.createLabel({
			parent = pickLabelContainer,
			id = string.format(CONSTANTS.picksLabelId,
				pick.object.id)
		})
			:withText(pick.object.name)
			:withColor(color)
			:withBorder({
				top = verticalBorder,
				bottom = verticalBorder,
				right = horizontalBorder,
			})
			:withCallback(EVENTS.pickChange, this.onPickChange)
			:withCallback(EVENTS.pickSelected, this.onPickSelected)
			:wuild()

		gui.createLabel({
			parent = pickCountLabelContainer,
			id = string.format(CONSTANTS.picksCountLabelId,
				pick.object.id)
		})
			:withText(string.format("%d", this.getLockpickCount(pick)))
			:withColor(color)
			:withBorder({
				top = verticalBorder,
				bottom = verticalBorder,
			})
			:withCallback(EVENTS.pickChange, this.onPickChange)
			:withCallback(EVENTS.pickSelected, this.onPickSelected)
			:wuild()
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
