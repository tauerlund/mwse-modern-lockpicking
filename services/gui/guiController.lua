---@class guiController : initializedService
local this = {}

---@private
---@type guiBuilder
this.guiBuilder = nil

---@private
---@type translations
this.translations = nil

---@private
---@type settings
this.settings = nil

---@private
---@type tes3uiElement
this.header = nil

---@private
---@type tes3uiElement
this.controls = nil

---@private
---@type tes3uiElement
this.picks = nil

---@private
---@type number
this.usesTooltipId = -1217

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.guiBuilder   = services.guiBuilder
	this.translations = services.translations
	this.settings     = services.settings
	this.enums        = services.enums

	event.register(tes3.event.load, this.onLoad)
	event.register(tes3.event.uiObjectTooltip, this.onUiObjectTooltip)
	event.register(tes3.event.uiActivated, this.uiActivated, { filter = "MenuOptions" })

	local events = this.enums.events

	event.register(events.lockpickingStart, this.onLockpickingStart)
	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	event.register(events.pickBroken, this.onPickBroken)

	return true, nil
end

---@private
---@param _ loadEventData
function this.onLoad(_)
	this.stop()
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
---@param e lockpickingStartEventData
function this.start(e)
	tes3ui.enterMenuMode("ModernLockpicking")

	if not this.header then
		this.header = this.createHeader(e)
	end

	if not this.controls then
		this.controls = this.createControls()
	end

	if not this.picks then
		this.picks = this.createPicks(e.session.pick, e.session.picks)
	end
end

---@private
---@param e lockpickingStartEventData
---@return tes3uiElement
function this.createHeader(e)
	local header = this.guiBuilder.createMenu({
			id = this.enums.constants.gui.headerId,
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:withPositionAlign({ x = 0.5, y = 0.05 })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withMinSize({ width = 0, height = 0 })
		:withAutoSize()
		:wuild()

	local block = this.guiBuilder.createBlock({ parent = header })
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

	this.guiBuilder.createLabel({ parent = block })
		:withText(e.session.activator.baseObject.name)
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:wuild()

	this.guiBuilder.createDivider({ parent = block })
		:withProportional({ width = 1.0 })
		:wuild()

	local lockLevel = tes3.getLockLevel({
		reference = e.session.activator --[[@as tes3reference]],
	})

	local player = tes3.player.mobile --[[@as tes3mobileActor]]
	local securitySkill = player:getSkillValue(tes3.skill.security)

	this.guiBuilder.createLabel({ parent = block })
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
	local enums = this.enums
	local constants = enums.constants.gui

	local controls = this.guiBuilder.createMenu({
			id = constants.controlsId,
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:withPositionAlign({ x = 0.5, y = 0.95 })
		:withAutoSize()
		:wuild()

	local outerBlock = this.guiBuilder.createBlock({ parent = controls })
		:withAutoSize()
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withChildAlignment({
			x = 0.5,
		})
		:wuild()

	this.guiBuilder.createLabel({ parent = outerBlock })
		:withText(this.translations.get(enums.translationKeys.interfaceControlsHeader))
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:wuild()

	local innerBlock = this.guiBuilder.createThinBorder({ parent = outerBlock })
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
		:withCallback(enums.events.settingsUpdated, this.onKeyBindsUpdated)
		:wuild()

	local controlTexts = this.getControlTexts()

	for i, text in ipairs(controlTexts) do
		this.guiBuilder.createLabel({ parent = innerBlock, id = string.format(constants.controlsLabelId, i) })
			:withText(text)
			:withColor(tes3ui.getPalette(tes3.palette.normalColor))
			:wuild()

		if i < #controlTexts then
			this.guiBuilder.createThinBorder({ parent = innerBlock })
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

	local rotateLockCounterclockwise = this.getKeyName(this.settings.keyBinds.rotateLockCounterclockwise)
	local rotateLockClockwise = this.getKeyName(this.settings.keyBinds.rotateLockClockwise)

	local cyclePreviousPick = this.getKeyName(this.settings.keyBinds.cyclePreviousPick)
	local cycleNextPick = this.getKeyName(this.settings.keyBinds.cycleNextPick)

	local exit = this.getKeyName(this.settings.keyBinds.exit)

	local translationKeys = this.enums.translationKeys

	return {
		string.format("%s: %s", this.translations.get(translationKeys.interfaceControlsRotatePick), mouse),
		string.format("%s: %s / %s", this.translations.get(translationKeys.interfaceControlsRotateLock),
			rotateLockCounterclockwise, rotateLockClockwise),
		string.format("%s: %s / %s", this.translations.get(translationKeys.interfaceControlsCyclePicks),
			cyclePreviousPick,
			cycleNextPick),
		string.format("%s: %s", this.translations.get(translationKeys.interfaceControlsExit), exit),
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
	local enums = this.enums
	local constants = enums.constants.gui
	local events = enums.events

	local picksMenu = this.guiBuilder.createMenu({
			id = constants.picksId,
			dragFrame = false,
			fixedFrame = true,
			modal = true
		})
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withPositionAlign({ x = 0.75, y = 0.25 })
		:withAutoSize()
		:wuild()

	local upperBlock = this.guiBuilder.createBlock({ parent = picksMenu })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:withPadding({
			all = 8,
		})
		:wuild()

	this.guiBuilder.createLabel({ parent = upperBlock })
		:withText(this.translations.get(enums.translationKeys.interfacePicksHeader))
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:wuild()

	local lowerBlock = this.guiBuilder.createThinBorder({ parent = picksMenu })
		:withFlowDirection(tes3.flowDirection.leftToRight)
		:withPadding({
			all = 8,
		})
		:withAutoSize()
		:wuild()

	local pickLabelContainer = this.guiBuilder.createBlock({ parent = lowerBlock })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:wuild()

	local pickCountLabelContainer = this.guiBuilder.createBlock({ parent = lowerBlock })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:wuild()

	for _, pick in ipairs(picks) do
		local color = pick.object.id == activePick.item.object.id and
			tes3ui.getPalette(tes3.palette.normalOverColor) or
			tes3ui.getPalette(tes3.palette.normalColor)

		local verticalBorder = 8
		local horizontalBorder = 16

		this.guiBuilder.createLabel({
			parent = pickLabelContainer,
			id = string.format(constants.picksLabelId,
				pick.object.id)
		})
			:withText(pick.object.name)
			:withColor(color)
			:withBorder({
				top = verticalBorder,
				bottom = verticalBorder,
				right = horizontalBorder,
			})
			:withCallback(events.pickCycled, this.onPickCycled)
			:wuild()

		this.guiBuilder.createLabel({
			parent = pickCountLabelContainer,
			id = string.format(constants.picksCountLabelId,
				pick.object.id)
		})
			:withText(string.format("%d", pick.count))
			:withColor(color)
			:withBorder({
				top = verticalBorder,
				bottom = verticalBorder,
			})
			:withCallback(events.pickCycled, this.onPickCycled)
			:wuild()
	end

	return picksMenu
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

	tes3ui.leaveMenuMode()
end

---@private
---@param element tes3uiElement
function this.onKeyBindsUpdated(element)
	local texts = this.getControlTexts()
	for i, text in ipairs(texts) do
		local label = element:findChild(string.format(this.enums.constants.gui.controlsLabelId, i))
		if not label then
			return
		else
			label.text = text
		end
	end
end

---@private
---@param element tes3uiElement
---@param e pickCycledEventData
function this.onPickCycled(element, e)
	local isSelected = element.name:endswith(e.pick.item.object.id)
	element.color = isSelected
		and tes3ui.getPalette(tes3.palette.normalOverColor)
		or tes3ui.getPalette(tes3.palette.normalColor)
end

---@private
---@param e pickBrokenEventData
function this.onPickBroken(e)
	if not this.picks then
		return
	end

	local constants = this.enums.constants.gui

	local objectId = e.pick.item.object.id
	local countLabel = this.picks:findChild(string.format(constants.picksCountLabelId, objectId))
	if not countLabel then return end

	local newCount = math.max(0, (tonumber(countLabel.text) or 1) - 1)

	if newCount == 0 then
		local nameLabel = this.picks:findChild(string.format(constants.picksLabelId, objectId))
		if nameLabel then nameLabel:destroy() end
		countLabel:destroy()
	else
		countLabel.text = string.format("%d", newCount)
	end

	this.picks:updateLayout()
end

---@private
---@param e uiObjectTooltipEventData
function this.onUiObjectTooltip(e)
	if e.object.objectType ~= tes3.objectType.lockpick then
		return
	end

	if not e.tooltip then
		return
	end

	local usesTooltip = e.tooltip:findChild(this.usesTooltipId)
	if not usesTooltip then
		return
	end

	local itemData = e.itemData

	if not itemData then
		for _, stack in pairs(tes3.player.object.inventory.items) do
			if stack.object == e.object and stack.variables then
				for _, v in ipairs(stack.variables) do
					if v.data and v.data.modernLockpicking then
						itemData = v
						break
					end
				end
			end
			if itemData then break end
		end
	end

	local conditionRatio = itemData and math.max(0, itemData.condition / e.object.maxCondition) or 1
	usesTooltip.text = string.format(
		"%s: %d%%",
		this.translations.get(this.enums.translationKeys.tooltipPickHealth),
		math.round(conditionRatio * 100))

	e.tooltip:updateLayout()
end

---@private
---@param e uiActivatedEventData
function this.uiActivated(e)
	e.element:getContentElement():registerAfter(
		tes3.uiEvent.destroy,
		this.onOptionsMenuClosed
	)
	event.trigger(this.enums.events.optionsMenuOpened)
end

---@private
function this.onOptionsMenuClosed()
	event.trigger(this.enums.events.optionsMenuClosed)
end

return this
