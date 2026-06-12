---@class pickBreakAnimator : initializedService
local this = {}

---@private
---@type pickBreakAnimatorState|nil
this.state = nil

---@private
this.rotationBuffer = tes3matrix33.new()

---@private
this.rotationBuffer2 = tes3matrix33.new()

---@private
---@type enums
this.enums = nil

---@private
---@type lockpickingSession|nil
this.session = nil

---@private
---@type renderingStrategyController
this.renderingStrategyController = nil

---@private
---@type formulas
this.formulas = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlerGroups
this.eventHandlers = {
	lifetime = {},
	session = {}
}

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.enums = services.enums
	this.renderingStrategyController = services.renderingStrategyController
	this.eventRegistrar = services.eventRegistrar
	this.formulas = services.formulas

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.lockpickingStarted] = this.onLockpickingStarted,
			[events.pickBroken] = this.onPickBroken,
			[events.lockpickingEnded] = this.onLockpickingEnded,
		},
		session = {
			[tes3.event.enterFrame] = this.onEnterFrame,
		}
	}

	this.eventRegistrar.register(this.eventHandlers.lifetime)
	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers.lifetime)
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.session = e.session
end

---@private
---@param e pickBrokenEventData
function this.onPickBroken(e)
	local ghostMesh = this.spawnGhost(e.pick.mesh)

	local firstPiece = this.findNodeBySuffix(ghostMesh, "0")
	local secondPiece = this.findNodeBySuffix(ghostMesh, "1")

	if not firstPiece or not secondPiece then
		ghostMesh.parent:detachChild(ghostMesh)
		return
	end

	local tipNode, handleNode = this.assignBreakRoles(ghostMesh, firstPiece, secondPiece)

	local constants = this.enums.constants.picks.breakAnimation

	local attachmentRotation = this.renderingStrategyController.getGhostAttachmentNode().worldTransform.rotation

	local function toScreenRotation(node)
		return node.parent.worldTransform.rotation:transpose() * attachmentRotation
	end

	local tipToScreen = toScreenRotation(tipNode)
	local handleToScreen = toScreenRotation(handleNode)

	this.state = {
		breakPhase = 0,
		ghost = {
			mesh = ghostMesh,
			originalTranslation = ghostMesh.translation:copy(),
		},
		tip = {
			node = tipNode,
			toScreen = tipToScreen,
			fromScreen = tipToScreen:transpose(),
			originalRotation = tipNode.rotation:copy(),
			originalTranslation = tipNode.translation:copy(),
			targetTranslation = tipNode.translation + tipToScreen * constants.snapTranslation,
			angleX = this.formulas.randomVariance(constants.snapAngle, constants.snapAngleVariance,
				math.random() * 2 - 1),
			angleZ = (math.random() * 2 - 1) * constants.snapAngleSideMax,
		},
		handle = {
			node = handleNode,
			toScreen = handleToScreen,
			fromScreen = handleToScreen:transpose(),
			originalRotation = handleNode.rotation:copy(),
			kickAngleX = this.formulas.randomVariance(constants.handleKickAngle, constants.handleKickAngleVariance,
				math.random() * 2 - 1),
			kickAngleZ = (math.random() * 2 - 1) * constants.handleKickAngleSideMax,
		},
	}

	this.enable()
end

---@private
---@param liveMesh niNode
---@return niNode
function this.spawnGhost(liveMesh)
	local ghostMesh = liveMesh:clone() --[[@as niNode]]
	ghostMesh.name = this.enums.objectNames.brokenPick

	-- Parent to the strategy's attachment node so the fall direction is in screen space,
	-- unaffected by pickHelper's cursor-driven Y-rotation.
	local cameraRoot = this.renderingStrategyController.getGhostAttachmentNode()
	local invRot = cameraRoot.worldTransform.rotation:transpose()
	local delta = liveMesh.worldTransform.translation - cameraRoot.worldTransform.translation

	ghostMesh.translation = invRot * delta
	ghostMesh.rotation = invRot * liveMesh.worldTransform.rotation

	cameraRoot:attachChild(ghostMesh, true)

	ghostMesh:updateProperties()
	ghostMesh:updateEffects()
	ghostMesh:update()

	liveMesh.appCulled = true
	liveMesh:update()

	return ghostMesh
end

--- Assigns the two pick shapes to their animation roles: the "tip" gets the
--- big snap rotation and drop, the "handle" gets the small recoil kick. The
--- vanilla pick meshes disagree on whether the "0" or "1" shape is the rear
--- shaft (Apprentice/Journeyman: "1"; Master/Grandmaster/Secret Master:
--- "0"), so the roles are assigned by geometry instead of by name: the
--- piece whose bounds sit farther back along the pick's local -Y axis is
--- the one that snaps away, matching how the pick points +Y into the lock.
---@private
---@param ghostMesh niNode
---@param firstPiece niNode
---@param secondPiece niNode
---@return niNode, niNode
function this.assignBreakRoles(ghostMesh, firstPiece, secondPiece)
	local forward = ghostMesh.worldTransform.rotation * tes3vector3.new(0, 1, 0)
	local origin = ghostMesh.worldTransform.translation
	local firstReach = (firstPiece.worldBoundOrigin - origin):dot(forward)
	local secondReach = (secondPiece.worldBoundOrigin - origin):dot(forward)
	if firstReach < secondReach then
		return firstPiece, secondPiece
	end
	return secondPiece, firstPiece
end

---@private
---@param node niNode
---@param suffix string
---@return niNode|nil
function this.findNodeBySuffix(node, suffix)
	for _, child in ipairs(node.children or {}) do
		if child.name and child.name:sub(- #suffix) == suffix then
			return child --[[@as niNode]]
		end
		if child.children then
			local found = this.findNodeBySuffix(child --[[@as niNode]], suffix)
			if found then return found end
		end
	end
end

---@private
---@param e enterFrameEventData
function this.onEnterFrame(e)
	local state = this.state
	if not state or (this.session and this.session.paused) then
		return
	end

	local constants = this.enums.constants.picks.breakAnimation
	state.breakPhase = math.min(state.breakPhase + e.delta / constants.duration, 1)

	local ghost = state.ghost
	local tip = state.tip
	local handle = state.handle

	local t = math.ease.quadOut(state.breakPhase)

	local pos = ghost.originalTranslation:copy()
	pos.z = pos.z + this.formulas.breakFallOffset(constants.fallDistance, constants.bounceHeight, state.breakPhase)
	ghost.mesh.translation = pos

	-- Tip snaps away from handle
	this.rotationBuffer:toRotationX(tip.angleX * t)
	this.rotationBuffer2:toRotationZ(tip.angleZ * t)

	tip.node.rotation = tip.toScreen
		* this.rotationBuffer
		* this.rotationBuffer2
		* tip.fromScreen
		* tip.originalRotation

	tip.node.translation = tip.originalTranslation:lerp(tip.targetTranslation, t)
	tip.node:update()

	this.rotationBuffer:toRotationX(-handle.kickAngleX * t)
	this.rotationBuffer2:toRotationZ(handle.kickAngleZ * t)

	handle.node.rotation = handle.toScreen * this.rotationBuffer * this.rotationBuffer2 * handle.fromScreen *
		handle.originalRotation
	handle.node:update()

	ghost.mesh:update()

	if state.breakPhase >= 1 then
		this.cleanup()
	end
end

---@private
function this.onLockpickingEnded(_)
	this.session = nil
	this.cleanup()
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
function this.cleanup()
	if this.state then
		local ghost = this.state.ghost.mesh
		if ghost.parent then
			ghost.parent:detachChild(ghost)
		end
		this.state = nil
	end
	this.disable()
end

return this
