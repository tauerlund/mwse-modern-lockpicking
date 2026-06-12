---@class menuCameraStrategy : renderingStrategy
local this = {}

---@public
---@type string
this.name = nil

---@private
---@type enums
this.enums = nil

---@private
---@type settings
this.settings = nil

---@private
---@type formulas
this.formulas = nil

---@public
---@param services serviceCollection
function this.initialize(services)
	this.name = services.enums.renderingStrategyNames.menuCamera
	this.enums = services.enums
	this.settings = services.settings
	this.formulas = services.formulas
end

---@private
---@return niNode
function this.getRootNode()
	return tes3.worldController.menuCamera.cameraRoot
end

---@public
---@param mesh niNode
function this.attachMesh(mesh)
	local root = this.getRootNode()

	if not root:getProperty(ni.propertyType.zBuffer) then
		local property = niZBufferProperty.new()
		property.name = this.enums.constants.locks.cameraRootZBufferName

		property:setFlag(false, this.enums.zBufferIndex.test)
		property:setFlag(false, this.enums.zBufferIndex.write)

		root:attachProperty(property)
		root:updateProperties()
	end

	local existingChildren = {}
	for _, child in ipairs(root.children) do
		table.insert(existingChildren, child)
	end
	root:detachAllChildren()
	root:attachChild(mesh, true)
	for _, child in ipairs(existingChildren) do
		root:attachChild(child, true)
	end

	root:updateEffects()
	root:update()
end

---@public
---@param mesh niNode
function this.detachMesh(mesh)
	local root = this.getRootNode()
	root:detachChild(mesh)

	local property = root:getProperty(ni.propertyType.zBuffer)
	if property and property.name == this.enums.constants.locks.cameraRootZBufferName then
		root:detachProperty(ni.propertyType.zBuffer)
		root:updateProperties()
	end

	root:update()
end

---@public
---@return niCamera
function this.getNiCamera()
	return tes3.worldController.menuCamera.cameraData.camera
end

---@public
---@return niNode
function this.getGhostAttachmentNode()
	return tes3.worldController.menuCamera.cameraRoot
end

---@public
---@return number
function this.getTargetDistance()
	local constants = this.enums.constants.locks
	local camera = this.getNiCamera()
	local topPlane = camera.cullingPlanes[5]
	local verticalTan = this.formulas.verticalTanFromCullingPlane(topPlane, camera.worldDirection, camera.worldUp)
	return this.formulas.lockTargetDistance(constants.targetDistance, constants.referenceVerticalTan, verticalTan,
		this.settings.lockDistanceFactor)
end

return this
