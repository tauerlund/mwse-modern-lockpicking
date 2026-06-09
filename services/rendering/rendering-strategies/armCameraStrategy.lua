---@class armCameraStrategy : renderingStrategy
local this = {}

---@public
---@type string
this.name = nil

---@private
---@type enums
this.enums = nil

---@private
---@type niNode|nil
this.cameraJoint = nil

---@private
---@type niNode|nil
this.wrapperRoot = nil

---@public
---@param services serviceCollection
function this.initialize(services)
	this.name = services.enums.renderingStrategyNames.armCamera
	this.enums = services.enums
end

---@private
---@return tes3matrix33
local function cameraRelativeRotation()
	local camera = tes3.worldController.worldCamera.cameraData.camera
	local view = tes3matrix33.new(camera.worldRight, camera.worldDirection, camera.worldUp):transpose()
	local baseView = tes3.worldController.worldCamera.cameraRoot.worldTransform.rotation:copy()
	return baseView:transpose() * view
end

---@private
---@return niNode
local function getRootNode()
	return tes3.worldController.armCamera.cameraRoot
end

---@private
---@param node niNode
local function attachDynamicEffects(node)
	local src = tes3.is3rdPerson() and tes3.player.sceneNode or tes3.player1stPerson.sceneNode
	if not src then return end
	local effects = src.effectList
	while effects do
		if effects.data and effects.data:isInstanceOfType(ni.type.NiLight) then
			node:attachEffect(effects.data)
			effects.data:attachAffectedNode(node)
			effects.data:updateEffects()
		end
		effects = effects.next
	end
end

---@private
---@param node niNode
local function detachDynamicEffects(node)
	local list = {}
	local effects = node.effectList
	while effects do
		if effects.data then
			table.insert(list, effects.data)
		end
		effects = effects.next
	end
	for _, effect in ipairs(list) do
		effect:detachAffectedNode(node)
		effect:updateEffects()
	end
	if node.detachAllEffects then
		node:detachAllEffects()
	end
end

---@public
---@param mesh niNode
function this.attachMesh(mesh)
	-- NiSortAdjustNode + NiAlphaAccumulator required; cannot be created from Lua, must be loaded from NIF
	local wrapperRoot = tes3.loadMesh("tauer\\root.nif", false)
	wrapperRoot.translation = tes3vector3.new(0, 0, 0)
	wrapperRoot.appCulled = false
	wrapperRoot:attachChild(mesh)

	local cameraJoint = niNode.new()
	cameraJoint.name = "ModernLockpicking:CameraJoint"
	cameraJoint.rotation = cameraRelativeRotation()
	cameraJoint:attachChild(wrapperRoot)

	local root = getRootNode()
	root:attachChild(cameraJoint)

	attachDynamicEffects(wrapperRoot)

	root:updateEffects()
	root:update()

	this.cameraJoint = cameraJoint
	this.wrapperRoot = wrapperRoot
end

---@public
---@param mesh niNode
function this.detachMesh(mesh)
	local root = getRootNode()

	if this.wrapperRoot then
		detachDynamicEffects(this.wrapperRoot)
		this.wrapperRoot:updateEffects()
	end

	if this.cameraJoint then
		root:detachChild(this.cameraJoint)
	end

	root:updateEffects()
	root:update()

	this.cameraJoint = nil
	this.wrapperRoot = nil
end

---@public
---@return niCamera
function this.getNiCamera()
	return tes3.worldController.worldCamera.cameraData.camera
end

---@public
---@return niNode
function this.getGhostAttachmentNode()
	return this.wrapperRoot
end

---@public
---@return number
function this.getTargetDistance()
	local menuFov = tes3.worldController.menuCamera.cameraData.fov
	local armFov = mge.camera.fov
	local base = this.enums.constants.locks.targetDistance
	return base * math.tan(math.rad(menuFov) * 0.5) / math.tan(math.rad(armFov) * 0.5)
end

return this
