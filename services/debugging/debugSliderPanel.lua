---@class debugSliderPanel
local this = {}

local guiBuilder = require("tauer.modern-lockpicking.services.gui.guiBuilder")

---@private
local nextId = 0

---@public
---@param params debugSliderPanelParams
---@return tes3uiElement
function this.create(params)
	nextId = nextId + 1

	local position = params.position or { x = 0.02, y = 0.3 }

	local menu = guiBuilder.createMenu({
			id = string.format("ModernLockpicking:DebugPanel:%d", nextId),
			dragFrame = false,
			fixedFrame = true,
			modal = false,
		})
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:withPositionAlign({ x = position.x, y = position.y })
		:build()

	local content = guiBuilder.createBlock({ parent = menu })
		:withFlowDirection(tes3.flowDirection.topToBottom)
		:withAutoSize()
		:withMinSize({ width = 300 })
		:withPadding({ all = 8 })
		:build()

	guiBuilder.createLabel({ parent = content })
		:withText(params.title)
		:withColor(tes3ui.getPalette(tes3.palette.headerColor))
		:build()

	guiBuilder.createDivider({ parent = content }):build()

	local sliderRefs = {}

	for _, sliderDef in ipairs(params.sliders) do
		local steps = math.round((sliderDef.max - sliderDef.min) / sliderDef.step)
		local defaultStep = math.round((sliderDef.default - sliderDef.min) / sliderDef.step)

		local row = guiBuilder.createBlock({ parent = content })
			:withFlowDirection(tes3.flowDirection.leftToRight)
			:withAutoSize()
			:withPadding({ top = 4, bottom = 4 })
			:build()

		guiBuilder.createLabel({ parent = row })
			:withText(sliderDef.label)
			:withSize({ width = 60 })
			:build()

		local valueLabel = guiBuilder.createLabel({ parent = row })
			:withText(string.format("%.3f", sliderDef.default))
			:withSize({ width = 55 })
			:build()

		local sliderEl = guiBuilder.createSlider({
				parent = row,
				current = defaultStep,
				max = steps,
				step = 1,
				jump = math.max(1, math.round(steps / 10)),
			})
			:withSize({ width = 185 })
			:build()

		sliderEl:registerAfter(tes3.uiEvent.partScrollBarChanged, function ()
			local intVal = sliderEl.widget.current
			local floatVal = sliderDef.min + (intVal / steps) * (sliderDef.max - sliderDef.min)
			valueLabel.text = string.format("%.3f", floatVal)
			menu:updateLayout()
			sliderDef.onChange(floatVal)
		end)

		table.insert(sliderRefs,
			{ sliderEl = sliderEl, valueLabel = valueLabel, defaultStep = defaultStep, sliderDef = sliderDef })
	end

	guiBuilder.createDivider({ parent = content }):build()

	local buttonRow = guiBuilder.createBlock({ parent = content })
		:withFlowDirection(tes3.flowDirection.leftToRight)
		:withAutoSize()
		:build()

	local resetButton = guiBuilder.createButton({ parent = buttonRow })
		:withText("Reset")
		:build()

	resetButton:registerBefore(tes3.uiEvent.mouseClick, function ()
		for _, ref in ipairs(sliderRefs) do
			ref.sliderEl.widget.current = ref.defaultStep
			ref.valueLabel.text = string.format("%.3f", ref.sliderDef.default)
			ref.sliderDef.onChange(ref.sliderDef.default)
		end
		menu:updateLayout()
	end)

	if params.onCopy then
		local copyButton = guiBuilder.createButton({ parent = buttonRow })
			:withText("Copy")
			:build()

		copyButton:registerBefore(tes3.uiEvent.mouseClick, function ()
			os.setClipboardText(params.onCopy())
		end)
	end

	menu:updateLayout()
	return menu
end

---@public
---@param mesh niNode
---@param options transformSlidersOptions|nil
---@return tes3uiElement[]
function this.createTransformSliders(mesh, options)
	local t = mesh.translation:copy()
	local euler = mesh.rotation:toEulerXYZ()
	local rx, ry, rz = euler.x, euler.y, euler.z

	local function applyTranslation()
		mesh.translation = tes3vector3.new(t.x, t.y, t.z)
		mesh:update()
	end

	local function applyRotation()
		local m = tes3matrix33.new()
		m:fromEulerXYZ(rx, ry, rz)
		if options and options.applyRotation then
			options.applyRotation(m)
		else
			mesh.rotation = m
			mesh:update()
		end
	end

	local translationPanel = this.create({
		title = "Translation",
		position = { x = 0.02, y = 0.02 },
		onCopy = function ()
			return string.format('{ "x": %.4f, "y": %.4f, "z": %.4f }', t.x, t.y, t.z)
		end,
		sliders = {
			{
				label = "X",
				min = -50,
				max = 50,
				step = 0.1,
				default = t.x,
				onChange = function (v)
					t.x = v
					applyTranslation()
				end
			},
			{
				label = "Y",
				min = -50,
				max = 50,
				step = 0.1,
				default = t.y,
				onChange = function (v)
					t.y = v
					applyTranslation()
				end
			},
			{
				label = "Z",
				min = -50,
				max = 50,
				step = 0.1,
				default = t.z,
				onChange = function (v)
					t.z = v
					applyTranslation()
				end
			},
		},
	})

	local rotationPanel = this.create({
		title = "Rotation",
		position = { x = 0.02, y = 0.42 },
		onCopy = function ()
			return string.format('{ "x": %.4f, "y": %.4f, "z": %.4f }', rx, ry, rz)
		end,
		sliders = {
			{
				label = "X",
				min = -math.pi,
				max = math.pi,
				step = 0.01,
				default = rx,
				onChange = function (v)
					rx = v
					applyRotation()
				end
			},
			{
				label = "Y",
				min = -math.pi,
				max = math.pi,
				step = 0.01,
				default = ry,
				onChange = function (v)
					ry = v
					applyRotation()
				end
			},
			{
				label = "Z",
				min = -math.pi,
				max = math.pi,
				step = 0.01,
				default = rz,
				onChange = function (v)
					rz = v
					applyRotation()
				end
			},
		},
	})

	local scalePanel = this.create({
		title = "Scale",
		position = { x = 0.02, y = 0.82 },
		sliders = {
			{
				label = "S",
				min = 0.01,
				max = 5,
				step = 0.01,
				default = mesh.scale,
				onChange = function (v)
					mesh.scale = v
					mesh:update()
				end
			},
		},
	})

	return { translationPanel, rotationPanel, scalePanel }
end

return this
