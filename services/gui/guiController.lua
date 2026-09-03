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
---@type locksAndTrapDetection
this.locksAndTrapDetection = nil

---@private
---@type tes3uiElement
this.header = nil

---@private
---@type tes3uiElement
this.lockLevelDivider = nil

---@private
---@type tes3uiElement
this.lockLevelLabel = nil

---@private
---@type tes3reference
this.activator = nil

---@private
---@type tes3uiElement
this.controls = nil

---@private
---@type tes3uiElement
this.picks = nil

---@private
---@type tes3uiElement
this.healthBlock = nil

---@private
---@type tes3uiElement
this.healthLabel = nil

---@private
---@type pick|nil
this.activePick = nil

---@private
---@type integer
this.lastPickCondition = -1

---@private
---@type number
this.usesTooltipId = -1217 -- ID of the "Uses" row in the vanilla item tooltip, found by inspecting tooltip children

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlerGroups
this.eventHandlers = {
	lifetime = {},
	session = {},
}

---@private
this.lockpicking = false

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.guiBuilder            = services.guiBuilder
	this.translations          = services.translations
	this.settings              = services.settings
	this.enums                 = services.enums
	this.eventRegistrar        = services.eventRegistrar
	this.locksAndTrapDetection = services.locksAndTrapDetection

	local events               = this.enums.events

	this.eventHandlers         = {
		lifetime = {
			[tes3.event.uiObjectTooltip] = this.onUiObjectTooltip,
			[tes3.event.uiActivated] = { this.uiActivated, { filter = "MenuOptions" } },
			[events.lockpickingStart] = this.onLockpickingStart,
			[events.lockpickingEnded] = this.onLockpickingEnded,
			[events.pickBroken] = this.onPickBroken,
			[events.pickCycled] = this.onPickCycled,
		},
		session = {
			[tes3.event.enterFrame] = this.onEnterFrame,
		},
	}

	this.eventRegistrar.register(this.eventHandlers.lifetime)

	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
end

---@private
function this.enable()
	this.eventRegistrar.register(this.eventHandlers.session)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.eventHandlers.session)
end

---@private
---@param e lockpickingStartEventData
function this.onLockpickingStart(e)
	this.start(e)
	this.lockpicking = true
end

---@private
---@param _ lockpickingEndedEventData
function this.onLockpickingEnded(_)
	this.stop()
	this.lockpicking = false
end

---@private
---@param e lockpickingStartEventData
function this.start(e)
	tes3ui.enterMenuMode("ModernLockpicking")
	this.activator = e.session.activator
	this.header = this.createHeader(e)
	this.controls = this.createControls()
	this.picks = this.createPicks(e.session.pick, e.session.picks, e.session.eligiblePicks)
	this.enable()
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
		:build()

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
		:build()

	this.guiBuilder.createLabel({ parent = block })
		:withText(e.session.activator.baseObject.name)
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:build()

	this.lockLevelDivider = this.guiBuilder.createDivider({ parent = block })
		:withProportional({ width = 1.0 })
		:build()

	this.lockLevelLabel = this.guiBuilder.createLabel({ parent = block })
		:withText(this.resolveLockLevelText(e.session.activator))
		:withColor(this.resolveLockLevelColor(e.session.activator))
		:withCallback(this.enums.events.settingsUpdated, function ()
			this.applyLockLevelVisibility()
		end)
		:build()

	this.applyLockLevelVisibility()

	return header
end

---@private
function this.applyLockLevelVisibility()
	if not this.lockLevelLabel or not this.lockLevelDivider then
		return
	end

	local visible = this.settings.showLockLevel
	this.lockLevelDivider.visible = visible
	this.lockLevelLabel.visible = visible

	if this.header then
		this.header:updateLayout()
	end
end

--- The header's lock level text: the Locks and Trap Detection range when the mod
--- is installed, otherwise the true lock level.
---@private
---@param activator tes3reference
---@return string
function this.resolveLockLevelText(activator)
	local lockLevel = tes3.getLockLevel({
		reference = activator --[[@as tes3reference]],
	})

	local locksAndTrapDetectionLabel = this.locksAndTrapDetection.getLockLevelLabel(activator)

	return this.createLockLevelText(locksAndTrapDetectionLabel or tostring(lockLevel))
end

--- The header's lock level colour. When Locks and Trap Detection is installed the
--- colour is based on the top of the detected range (the pessimistic estimate the
--- player sees), otherwise on the true lock level.
---@private
---@param activator tes3reference
---@return number[]
function this.resolveLockLevelColor(activator)
	local lockLevel = this.locksAndTrapDetection.getMaxLockLevel(activator)
		or tes3.getLockLevel({ reference = activator --[[@as tes3reference]] })

	local player = tes3.player.mobile --[[@as tes3mobileActor]]
	local securitySkill = player:getSkillValue(tes3.skill.security)

	return this.getLockLevelColor(lockLevel, securitySkill)
end

--- Re-resolve the header's lock level text so a narrowed Locks and Trap Detection
--- range becomes visible mid-session.
---@private
---@param activator tes3reference
function this.refreshLockLevelLabel(activator)
	if not this.lockLevelLabel then
		return
	end

	this.lockLevelLabel.text = this.resolveLockLevelText(activator)
	this.lockLevelLabel.color = this.resolveLockLevelColor(activator)

	if this.header then
		this.header:updateLayout()
	end
end

---@private
---@param level string
---@return string
function this.createLockLevelText(level)
	return string.format("%s: %s", tes3.findGMST(tes3.gmst.sLockLevel).value, level)
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
		:withPositionAlign({ x = 0.5, y = 0.90 })
		:withAutoSize()
		:build()

	local outerBlock = this.guiBuilder.createBlock({ parent = controls })
		:withAutoSize()
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withChildAlignment({
			x = 0.5,
		})
		:build()

	this.guiBuilder.createLabel({ parent = outerBlock })
		:withText(this.translations.get(enums.translationKeys.interfaceControlsHeader))
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:build()

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
		:build()

	local controlTexts = this.getControlTexts()

	for i, text in ipairs(controlTexts) do
		this.guiBuilder.createLabel({ parent = innerBlock, id = string.format(constants.controlsLabelId, i) })
			:withText(text)
			:withColor(tes3ui.getPalette(tes3.palette.normalColor))
			:build()

		if i < #controlTexts then
			this.guiBuilder.createThinBorder({ parent = innerBlock })
				:withSize({ width = 1, height = 24 })
				:withBorder({
					left = 12,
					right = 12,
				})
				:build()
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
---@param eligiblePicks { [string]: boolean }
---@return tes3uiElement
function this.createPicks(activePick, picks, eligiblePicks)
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
		:withPositionAlign({ x = 0.8, y = 0.25 })
		:withAutoSize()
		:build()

	local upperBlock = this.guiBuilder.createBlock({ parent = picksMenu })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:withPadding({
			all = 8,
		})
		:build()

	this.guiBuilder.createLabel({ parent = upperBlock })
		:withText(this.translations.get(enums.translationKeys.interfacePicksHeader))
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:build()

	local lowerBlock = this.guiBuilder.createThinBorder({ parent = picksMenu })
		:withFlowDirection(tes3.flowDirection.leftToRight)
		:withPadding({
			all = 8,
		})
		:withAutoSize()
		:build()

	local pickLabelContainer = this.guiBuilder.createBlock({ parent = lowerBlock })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:build()

	local pickCountLabelContainer = this.guiBuilder.createBlock({ parent = lowerBlock })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:build()

	local pickPalette = constants.pickPalette

	for _, pick in ipairs(picks) do
		local isActive = pick.object.id == activePick.item.object.id
		local isEligible = eligiblePicks[pick.object.id]
		local color = isActive and tes3ui.getPalette(pickPalette.active)
			or isEligible and tes3ui.getPalette(pickPalette.inactive)
			or tes3ui.getPalette(pickPalette.ineligible)

		local verticalBorder = 8
		local horizontalBorder = 16

		local pickId = pick.object.id
		local function onPickCycled(element, e)
			local isActive = pickId == e.pick.item.object.id
			element.color = isActive and tes3ui.getPalette(pickPalette.active)
				or eligiblePicks[pickId] and tes3ui.getPalette(pickPalette.inactive)
				or tes3ui.getPalette(pickPalette.ineligible)
		end

		this.guiBuilder.createLabel({
			parent = pickLabelContainer,
			id = string.format(constants.picksLabelId, pickId)
		})
			:withText(pick.object.name)
			:withColor(color)
			:withBorder({
				top = verticalBorder,
				bottom = verticalBorder,
				right = horizontalBorder,
			})
			:withCallback(events.pickCycled, onPickCycled)
			:build()

		this.guiBuilder.createLabel({
			parent = pickCountLabelContainer,
			id = string.format(constants.picksCountLabelId, pickId)
		})
			:withText(string.format("%d", pick.count))
			:withColor(color)
			:withBorder({
				top = verticalBorder,
				bottom = verticalBorder,
			})
			:withCallback(events.pickCycled, onPickCycled)
			:build()
	end

	this.activePick = activePick
	this.lastPickCondition = activePick.itemData and activePick.itemData.condition or -1

	this.healthBlock = this.guiBuilder.createBlock({ parent = picksMenu })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:withPadding({ all = 8 })
		:withCallback(enums.events.settingsUpdated, function (element)
			element.visible = this.settings.showPickHealth
			if this.picks then this.picks:updateLayout() end
		end)
		:build()

	this.healthBlock.visible = this.settings.showPickHealth

	this.healthLabel = this.guiBuilder.createLabel({ parent = this.healthBlock })
		:withColor(tes3ui.getPalette(tes3.palette.normalColor))
		:build()

	this.updateHealthLabel(activePick)

	return picksMenu
end

---@private
function this.stop()
	this.disable()
	this.healthBlock = nil
	this.healthLabel = nil
	this.activePick = nil
	this.lastPickCondition = -1
	this.activator = nil
	this.lockLevelDivider = nil
	this.lockLevelLabel = nil

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
---@param pick pick
function this.updateHealthLabel(pick)
	local ratio = pick.itemData
		and math.clamp(pick.itemData.condition / pick.item.object.maxCondition, 0, 1)
		or 1
	this.healthLabel.text = string.format(
		"%s: %d%%",
		this.translations.get(this.enums.translationKeys.tooltipPickHealth),
		math.round(ratio * 100))
	this.healthLabel.color = { 1 - ratio, ratio, 0 }
	this.healthLabel:updateLayout()
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	this.activePick = e.pick
	this.lastPickCondition = e.pick.itemData and e.pick.itemData.condition or -1
	if not this.healthLabel or not this.settings.showPickHealth then
		return
	end
	this.updateHealthLabel(e.pick)
end

---@private
function this.onEnterFrame()
	if not this.healthLabel or not this.activePick then
		return
	end
	if not this.settings.showPickHealth then
		return
	end
	local condition = this.activePick.itemData and this.activePick.itemData.condition or -1
	if condition == this.lastPickCondition then
		return
	end
	this.lastPickCondition = condition
	this.updateHealthLabel(this.activePick)
end

---@private
---@param e pickBrokenEventData
function this.onPickBroken(e)
	if not this.picks then
		return
	end

	if this.activator then
		this.locksAndTrapDetection.narrowLockRange(this.activator)
		this.refreshLockLevelLabel(this.activator)
	end

	local constants = this.enums.constants.gui

	local objectId = e.item.id
	local countLabel = this.picks:findChild(string.format(constants.picksCountLabelId, objectId))
	if not countLabel then
		return
	end

	local newCount = e.remainingCount

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
	if not this.settings.enabled then
		return
	end

	if this.lockpicking then
		e.tooltip:destroy()
		return
	end

	if e.object.objectType ~= tes3.objectType.lockpick then
		return
	end

	if this.settings.pickBlacklist[e.object.id:lower()] then
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
