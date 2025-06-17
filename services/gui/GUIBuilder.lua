local Logger = require("tauer.modern-lockpicking.shared.Logger")

---@class GUIBuilder
---@field private element tes3uiElement
---@field private callbacks { [string]: function }
local GUIBuilder = {}
GUIBuilder.__index = GUIBuilder

---@public
---@param parameters createMenuParameters
---@return GUIBuilder
function GUIBuilder.CreateMenu(parameters)
	local element = tes3ui.createMenu({
		id = parameters.id,
		dragFrame = parameters.dragFrame,
		fixedFrame = parameters.fixedFrame,
		modal = parameters.modal,
	})
	return GUIBuilder.create(element)
end

---@public
---@param parameters createParameters
---@return GUIBuilder
function GUIBuilder.CreateLabel(parameters)
	local element = parameters.parent:createLabel({
		id = parameters.id,
	})
	return GUIBuilder.create(element)
end

---@public
---@param parameters createParameters
---@return GUIBuilder
function GUIBuilder.CreateThinBorder(parameters)
	local element = parameters.parent:createThinBorder({
		id = parameters.id,
	})
	return GUIBuilder.create(element)
end

---@public
---@param parameters createParameters
---@return GUIBuilder
function GUIBuilder.CreateBlock(parameters)
	local element = parameters.parent:createBlock({
		id = parameters.id,
	})
	return GUIBuilder.create(element)
end

---@public
---@param parameters createParameters
---@return GUIBuilder
function GUIBuilder.CreateDivider(parameters)
	local element = parameters.parent:createDivider({
		id = parameters.id,
	})
	return GUIBuilder.create(element)
end

---@public
---@param text string
---@return GUIBuilder
function GUIBuilder:WithText(text)
	self.element.text = text
	return self
end

---@public
---@param color number[]
---@return GUIBuilder
function GUIBuilder:WithColor(color)
	self.element.color = color
	return self
end

---@public
---@return GUIBuilder
function GUIBuilder:WithAutoSize()
	self.element.autoHeight = true
	self.element.autoWidth = true
	return self
end

---@public
---@param parameters sizeParameters
---@return GUIBuilder
function GUIBuilder:WithMinSize(parameters)
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
---@return GUIBuilder
function GUIBuilder:WithPositionAlign(parameters)
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
---@return GUIBuilder
function GUIBuilder:WithFlowDirection(flowDirection)
	self.element.flowDirection = flowDirection
	return self
end

---@public
---@param parameters borderPaddingParameters
---@return GUIBuilder
function GUIBuilder:WithBorder(parameters)
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
---@return GUIBuilder
function GUIBuilder:WithPadding(parameters)
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
---@return GUIBuilder
function GUIBuilder:WithChildAlignment(parameters)
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
---@return GUIBuilder
function GUIBuilder:WithProportional(parameters)
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
function GUIBuilder:WithSize(parameters)
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
function GUIBuilder:WithCallback(evt, callback)
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
function GUIBuilder:Build()
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
function GUIBuilder:registerCallback(evt, callback)
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
---@return GUIBuilder
function GUIBuilder.create(element)
	local instance = setmetatable({ element = element }, GUIBuilder)
	return instance
end

return GUIBuilder
