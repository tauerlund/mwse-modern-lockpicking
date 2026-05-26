local Logger = require("tauer.modern-lockpicking.shared.loggingFactory")

---@class guiBuilder
---@field private element tes3uiElement
---@field private callbacks { [string]: function }
local guiBuilder = {}
guiBuilder.__index = guiBuilder

---@public
---@param parameters createMenuParameters
---@return guiBuilder
function guiBuilder.createMenu(parameters)
	local element = tes3ui.createMenu({
		id = parameters.id,
		dragFrame = parameters.dragFrame,
		fixedFrame = parameters.fixedFrame,
		modal = parameters.modal,
	})
	return guiBuilder.create(element)
end

---@public
---@param parameters createParameters
---@return guiBuilder
function guiBuilder.createLabel(parameters)
	local element = parameters.parent:createLabel({
		id = parameters.id,
	})
	return guiBuilder.create(element)
end

---@public
---@param parameters createParameters
---@return guiBuilder
function guiBuilder.createThinBorder(parameters)
	local element = parameters.parent:createThinBorder({
		id = parameters.id,
	})
	return guiBuilder.create(element)
end

---@public
---@param parameters createParameters
---@return guiBuilder
function guiBuilder.createBlock(parameters)
	local element = parameters.parent:createBlock({
		id = parameters.id,
	})
	return guiBuilder.create(element)
end

---@public
---@param parameters createParameters
---@return guiBuilder
function guiBuilder.createDivider(parameters)
	local element = parameters.parent:createDivider({
		id = parameters.id,
	})
	return guiBuilder.create(element)
end

---@public
---@param text string
---@return guiBuilder
function guiBuilder:withText(text)
	self.element.text = text
	return self
end

---@public
---@param color number[]
---@return guiBuilder
function guiBuilder:withColor(color)
	self.element.color = color
	return self
end

---@public
---@return guiBuilder
function guiBuilder:withAutoSize()
	self.element.autoHeight = true
	self.element.autoWidth = true
	return self
end

---@public
---@param parameters sizeParameters
---@return guiBuilder
function guiBuilder:withMinSize(parameters)
	if parameters.width then
		self.element.minWidth = parameters.width
	end
	if parameters.height then
		self.element.minHeight = parameters.height
	end
	return self
end

---@public
---@param parameters vector2Parameters
---@return guiBuilder
function guiBuilder:withPositionAlign(parameters)
	if parameters.x then
		self.element.absolutePosAlignX = parameters.x
	end
	if parameters.y then
		self.element.absolutePosAlignY = parameters.y
	end
	return self
end

---@public
---@param flowDirection string
---@return guiBuilder
function guiBuilder:withFlowDirection(flowDirection)
	self.element.flowDirection = flowDirection
	return self
end

---@public
---@param parameters borderPaddingParameters
---@return guiBuilder
function guiBuilder:withBorder(parameters)
	if parameters.all then
		self.element.borderAllSides = parameters.all
	end
	if parameters.left then
		self.element.borderLeft = parameters.left
	end
	if parameters.right then
		self.element.borderRight = parameters.right
	end
	if parameters.top then
		self.element.borderTop = parameters.top
	end
	if parameters.bottom then
		self.element.borderBottom = parameters.bottom
	end
	return self
end

---@public
---@param parameters borderPaddingParameters
---@return guiBuilder
function guiBuilder:withPadding(parameters)
	if parameters.all then
		self.element.paddingAllSides = parameters.all
	end
	if parameters.left then
		self.element.paddingLeft = parameters.left
	end
	if parameters.right then
		self.element.paddingRight = parameters.right
	end
	if parameters.top then
		self.element.paddingTop = parameters.top
	end
	if parameters.bottom then
		self.element.paddingBottom = parameters.bottom
	end
	return self
end

---@public
---@param parameters vector2Parameters
---@return guiBuilder
function guiBuilder:withChildAlignment(parameters)
	if parameters.x then
		self.element.childAlignX = parameters.x
	end
	if parameters.y then
		self.element.childAlignY = parameters.y
	end
	return self
end

---@public
---@param parameters sizeParameters
---@return guiBuilder
function guiBuilder:withProportional(parameters)
	if parameters.width then
		self.element.widthProportional = parameters.width
	end
	if parameters.height then
		self.element.heightProportional = parameters.height
	end
	return self
end

---@public
---@param parameters sizeParameters
function guiBuilder:withSize(parameters)
	if parameters.width then
		self.element.width = parameters.width
	end
	if parameters.height then
		self.element.height = parameters.height
	end
	return self
end

---@public
---@param evt string
---@param callback fun(element: tes3uiElement, e: table|nil)
function guiBuilder:withCallback(evt, callback)
	self.callbacks = self.callbacks or {}
	if self.callbacks[evt] then
		Logger:warn("Callback for event '%s' already registered", evt)
		return
	end

	self.callbacks[evt] = function (e)
		callback(self.element, e or nil)
		self.element:updateLayout()
	end

	return self
end

---@public
---@return tes3uiElement
function guiBuilder:wuild()
	if self.callbacks then
		for evt, callback in pairs(self.callbacks) do
			self:registerCallback(evt, callback)
		end
	end
	self.element:updateLayout()
	return self.element
end

---@private
---@param evt string
---@param callback fun(element: tes3uiElement, e: table|nil)
function guiBuilder:registerCallback(evt, callback)
	if not event.isRegistered(evt, callback) then
		event.register(evt, callback)
	end

	self.element:registerBefore(tes3.uiEvent.destroy, function ()
		if event.isRegistered(evt, callback) then
			event.unregister(evt, callback)
		end
	end)
end

---@private
---@param element tes3uiElement
---@return guiBuilder
function guiBuilder.create(element)
	local instance = setmetatable({ element = element }, guiBuilder)
	return instance
end

return guiBuilder
