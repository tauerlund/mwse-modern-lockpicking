---@class armCameraStrategy : renderingStrategy
local this = {}

---@public
---@type string
this.name = nil

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
this.sessionHandlers = {}

---@private
---@type niNode|nil
this.cameraJoint = nil

---@private
---@type niNode|nil
this.wrapperRoot = nil

---@private
---@type niPointLight|nil
this.pointLight = nil

---@private
---@type boolean
this.paused = false

---@private
local LIGHT_AMPLITUDE = 64

---@public
---@param services serviceCollection
function this.initialize(services)
	this.name = services.enums.renderingStrategyNames.armCamera
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar

	local events = this.enums.events

	this.sessionHandlers = {
		[tes3.event.enterFrame] = this.onEnterFrame,
		[events.optionsMenuOpened] = this.onOptionsMenuOpened,
		[events.optionsMenuClosed] = this.onOptionsMenuClosed,
	}
end

---@private
---@return tes3matrix33
function this.cameraRelativeRotation()
	local camera = tes3.worldController.worldCamera.cameraData.camera
	local view = tes3matrix33.new(camera.worldRight, camera.worldDirection, camera.worldUp):transpose()
	local baseView = tes3.worldController.worldCamera.cameraRoot.worldTransform.rotation:copy()
	return baseView:transpose() * view
end

---@private
---@return niNode
function this.getRootNode()
	return tes3.worldController.armCamera.cameraRoot
end

---@private
---@return niPointLight
function this.createPointLight()
	local light = niPointLight.new()

	light.name = this.enums.objectNames.pointLight
	light.diffuse = niColor.new(0.3, 0.25, 0.25)
	light.ambient = niColor.new(0, 0, 0)
	light.constantAttenuation = 1
	light.linearAttenuation = 0
	light.quadraticAttenuation = 0.001

	return light
end

---@private
---@param node niNode
function this.attachDynamicEffects(node)
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
function this.detachDynamicEffects(node)
	---@type niDynamicEffect[]
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

---@private
function this.onEnterFrame()
	if this.paused or not this.pointLight then
		return
	end

	-- Cursor is in pixels relative to the screen center; normalize to [-0.5, 0.5]
	local cursor = tes3.getCursorPosition()
	local viewportWidth, viewportHeight = tes3.getViewportSize()
	local x = (cursor.x / viewportWidth) * LIGHT_AMPLITUDE
	local z = (cursor.y / viewportHeight) * LIGHT_AMPLITUDE
	local translation = tes3vector3.new(x, this.getTargetDistance() - 15, z)

	this.pointLight.translation = translation
	this.pointLight:update()
end

---@private
function this.onOptionsMenuOpened()
	this.paused = true
end

---@private
function this.onOptionsMenuClosed()
	this.paused = false
end

---@private
function this.enable()
	this.eventRegistrar.register(this.sessionHandlers)
end

---@private
function this.disable()
	this.eventRegistrar.unregister(this.sessionHandlers)
end

---@public
---@param mesh niNode
function this.attachMesh(mesh)
	-- NiSortAdjustNode + NiAlphaAccumulator required; cannot be created from Lua, must be loaded from NIF
	local wrapperRoot = tes3.loadMesh("tauer\\root.nif", false)
	wrapperRoot.translation = tes3vector3.new(0, 0, 0)
	wrapperRoot.appCulled = false
	wrapperRoot:attachChild(mesh)

	local light = this.createPointLight()

	local cameraJoint = niNode.new()
	cameraJoint.name = "ModernLockpicking:CameraJoint"
	cameraJoint.rotation = this.cameraRelativeRotation()
	cameraJoint:attachChild(wrapperRoot)
	cameraJoint:attachChild(light)

	local root = this.getRootNode()
	root:attachChild(cameraJoint)

	this.attachDynamicEffects(wrapperRoot)
	wrapperRoot:attachEffect(light)
	light:attachAffectedNode(wrapperRoot)

	root:updateEffects()
	root:update()

	this.cameraJoint = cameraJoint
	this.wrapperRoot = wrapperRoot
	this.pointLight = light
	this.enable()
end

---@public
---@param mesh niNode
function this.detachMesh(mesh)
	local root = this.getRootNode()

	this.disable()

	if this.wrapperRoot then
		this.wrapperRoot:detachChild(mesh)
		this.detachDynamicEffects(this.wrapperRoot)
		this.wrapperRoot:updateEffects()
	end

	if this.cameraJoint then
		root:detachChild(this.cameraJoint)
	end

	root:updateEffects()
	root:update()

	this.cameraJoint = nil
	this.wrapperRoot = nil
	this.pointLight = nil
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
