---@class debugSliderPanel
local this = {}

---@private
local nextId = 0

---@public
---@param params debugSliderPanelParams
---@return tes3uiElement
function this.create(params)
	nextId = nextId + 1
	local menuId = tes3ui.registerID(string.format("ModernLockpicking:DebugPanel:%d", nextId))

	local menu = tes3ui.createMenu({
		id = menuId,
		dragFrame = false,
		fixedFrame = true,
		modal = false,
	})
	menu.flowDirection = tes3.flowDirection.topToBottom
	menu.autoHeight = true
	menu.autoWidth = true
	local position = params.position or { x = 0.02, y = 0.3 }
	menu.absolutePosAlignX = position.x
	menu.absolutePosAlignY = position.y

	local content = menu:createBlock({})
	content.flowDirection = tes3.flowDirection.topToBottom
	content.autoHeight = true
	content.autoWidth = true
	content.minWidth = 300
	content.paddingAllSides = 8

	local title = content:createLabel({})
	title.text = params.title
	title.color = tes3ui.getPalette(tes3.palette.headerColor)

	content:createDivider({})

	for _, sliderDef in ipairs(params.sliders) do
		local steps = math.round((sliderDef.max - sliderDef.min) / sliderDef.step)

		local row = content:createBlock({})
		row.flowDirection = tes3.flowDirection.leftToRight
		row.autoHeight = true
		row.autoWidth = true
		row.paddingTop = 4
		row.paddingBottom = 4

		local nameLabel = row:createLabel({})
		nameLabel.text = sliderDef.label
		nameLabel.width = 60

		local valueLabel = row:createLabel({})
		valueLabel.text = string.format("%.3f", sliderDef.default)
		valueLabel.width = 55

		local sliderEl = row:createSlider({
			current = math.round((sliderDef.default - sliderDef.min) / sliderDef.step),
			max = steps,
			step = 1,
			jump = math.max(1, math.round(steps / 10)),
		})
		sliderEl.width = 185

		sliderEl:registerAfter(tes3.uiEvent.partScrollBarChanged, function ()
			local intVal = sliderEl.widget.current
			local floatVal = sliderDef.min + (intVal / steps) * (sliderDef.max - sliderDef.min)
			valueLabel.text = string.format("%.3f", floatVal)
			menu:updateLayout()
			sliderDef.onChange(floatVal)
		end)
	end

	menu:updateLayout()
	return menu
end

return this
