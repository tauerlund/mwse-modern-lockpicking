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
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		lifetime = {
			[events.pickBroken] = this.onPickBroken,
			[events.lockpickingEnded] = this.onLockpickingEnded,
			[events.optionsMenuOpened] = this.onOptionsMenuOpened,
			[events.optionsMenuClosed] = this.onOptionsMenuClosed,
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
function this.onOptionsMenuOpened()
	this.paused = true
end

---@private
function this.onOptionsMenuClosed()
	this.paused = false
end

---@private
---@param e pickBrokenEventData
function this.onPickBroken(e)
	local ghostMesh = this.spawnGhost(e.pick.mesh)

	local tipNode = this.findNodeBySuffix(ghostMesh, "1")
	local handleNode = this.findNodeBySuffix(ghostMesh, "0")

	if not tipNode or not handleNode then
		ghostMesh.parent:detachChild(ghostMesh)
		return
	end

	local constants = this.enums.constants.picks.breakAnimation
	local position = ghostMesh.translation

	local function random(base, variance)
		return base * (1 + (math.random() * 2 - 1) * variance)
	end

	this.state = {
		breakPhase = 0,
		ghost = {
			mesh = ghostMesh,
			originalTranslation = position:copy(),
			fallTargetTranslation = tes3vector3.new(position.x, position.y, position.z - constants.fallDistance),
		},
		tip = {
			node = tipNode,
			originalRotation = tipNode.rotation:copy(),
			originalTranslation = tipNode.translation:copy(),
			targetTranslation = tipNode.translation + constants.snapTranslation,
			angleX = random(constants.snapAngle, constants.snapAngleVariance),
			angleZ = (math.random() * 2 - 1) * constants.snapAngleSideMax,
		},
		handle = {
			node = handleNode,
			originalRotation = handleNode and handleNode.rotation:copy() or nil,
			kickAngleX = random(constants.handleKickAngle, constants.handleKickAngleVariance),
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

	-- Parent to cameraRoot (not pickHelper) so the fall direction is in screen space,
	-- unaffected by pickHelper's cursor-driven Y-rotation.
	local cameraRoot = tes3.worldController.menuCamera.cameraRoot
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
	if this.paused then
		return
	end

	local state = this.state
	if not state then
		return
	end

	local constants = this.enums.constants.picks.breakAnimation
	state.breakPhase = math.min(state.breakPhase + e.delta / constants.duration, 1)

	local ghost = state.ghost
	local tip = state.tip
	local handle = state.handle

	-- Ease-out quadratic for snap; quadratic phase for gravity falloff
	local t = 1 - (1 - state.breakPhase) ^ 2
	local fallT = state.breakPhase * state.breakPhase

	-- Ghost falls down with an initial upward bounce arc
	local pos = ghost.originalTranslation:lerp(ghost.fallTargetTranslation, fallT)
	pos.z = pos.z + constants.bounceHeight * math.sin(math.pi * state.breakPhase)
	ghost.mesh.translation = pos

	-- Tip snaps away from handle
	this.rotationBuffer:toRotationX(tip.angleX * t)
	this.rotationBuffer2:toRotationZ(tip.angleZ * t)

	tip.node.rotation = tip.originalRotation * this.rotationBuffer * this.rotationBuffer2
	tip.node.translation = tip.originalTranslation:lerp(tip.targetTranslation, t)
	tip.node:update()

	if handle.node then
		this.rotationBuffer:toRotationX(-handle.kickAngleX * t)
		this.rotationBuffer2:toRotationZ(handle.kickAngleZ * t)

		handle.node.rotation = handle.originalRotation * this.rotationBuffer * this.rotationBuffer2
		handle.node:update()
	end

	ghost.mesh:update()

	if state.breakPhase >= 1 then
		this.cleanup()
	end
end

---@private
function this.onLockpickingEnded(_)
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
