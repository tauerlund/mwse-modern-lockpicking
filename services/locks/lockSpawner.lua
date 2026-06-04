---@class lockSpawner : initializedService
local this = {}

---@private
---@type lockMeshResolver
this.lockMeshResolver = nil

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.lockMeshResolver = services.lockMeshResolver
	this.enums = services.enums
	local events = services.enums.events

	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	return true, nil
end

---@public
---@param activator tes3reference
---@return lock
function this.spawn(activator)
	local mesh = this.spawnMesh(activator)

	return {
		mesh = mesh,
		cylinder = mesh:getObjectByName(this.enums.objectNames.cylinderHelper),
		container = activator,
	}
end

---@private
local camRootZBufName = "ModernLockpicking:NoDepth"

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	local root = this.getRootNode()
	root:detachChild(e.session.lock.mesh)
	local p = root:getProperty(ni.propertyType.zBuffer)
	if p and p.name == camRootZBufName then
		root:detachProperty(ni.propertyType.zBuffer)
		root:updateProperties()
	end
	root:update()
end

---@private
---@param activator tes3reference
---@return niNode
function this.spawnMesh(activator)
	local mesh = this.getMesh(activator)
	local root = this.getRootNode()

	-- Mirror InspectIt: add test=false,write=false to camera root so depth buffer from
	-- world pass doesn't occlude things; child mesh overrides with its own property.
	if not root:getProperty(ni.propertyType.zBuffer) then
		local rootProp = niZBufferProperty.new()
		rootProp.name = camRootZBufName
		rootProp:setFlag(false, this.enums.zBufferIndex.test)
		rootProp:setFlag(false, this.enums.zBufferIndex.write)
		root:attachProperty(rootProp)
		root:updateProperties()
	end

	-- Prepend as first child (InspectIt pattern): tes3ui nodes already in cameraRoot render
	-- after our mesh and thus appear above it, which is what we want.
	local existingChildren = {}
	for _, child in ipairs(root.children) do
		table.insert(existingChildren, child)
	end
	root:detachAllChildren()
	root:attachChild(mesh, true)
	for _, child in ipairs(existingChildren) do
		root:attachChild(child, true)
	end

	mesh:updateProperties()
	mesh:updateEffects()
	mesh:update()

	root:updateEffects()
	root:update()

	return mesh
end

---@private
---@param activator tes3reference
---@return niNode
function this.getMesh(activator)
	local mesh = this.lockMeshResolver.resolve(activator)

	mesh.name = "ModernLockpicking:Root"
	-- Start close to camera so the fly-in animation is visible; nodeAnimator moves it to targetDistance.
	mesh.translation = tes3vector3.new(0, 5, 0)
	mesh.rotation = tes3matrix33.new(1, 0, 0, 0, 1, 0, 0, 0, 1)
	mesh:attachProperty(this.getZBufferProperty())

	return mesh
end

---@private
---@return niNode
function this.getRootNode()
	return tes3.worldController.menuCamera.cameraRoot
end

---@private
---@return niZBufferProperty
function this.getZBufferProperty()
	local property = niZBufferProperty.new()
	local zBufferIndex = this.enums.zBufferIndex

	property:setFlag(false, zBufferIndex.test)
	property:setFlag(true, zBufferIndex.write)
	property.testFunction = ni.zBufferPropertyTestFunction.always

	return property
end

return this
