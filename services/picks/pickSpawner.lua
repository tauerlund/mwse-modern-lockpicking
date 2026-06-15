---@class pickSpawner : initializedService
local this = {}

---@private
---@type enums
this.enums = nil

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlers
this.eventHandlers = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		[events.lockpickingEnded] = this.onLockpickingEnded,
		[events.pickCycled] = this.onPickCycled,
	}

	this.eventRegistrar.register(this.eventHandlers)
	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers)
end

---@public
---@param lock lock
---@param pickItem tes3itemStack
---@return pick
function this.spawn(lock, pickItem)
	local pick = this.getMesh(pickItem.object --[[@as tes3lockpick]])
	local helper = lock.mesh:getObjectByName(this.enums.objectNames.pickHelper) --[[@as niNode]]

	helper:attachChild(pick)

	pick:updateProperties()
	pick:updateEffects()
	pick:update()

	helper:update()

	return {
		mesh = pick,
		item = pickItem,
		helper = helper,
		itemData = this.resolveItemData(pickItem),
	}
end

---@private
---@param pickItem tes3itemStack
---@return tes3itemData|nil
function this.resolveItemData(pickItem)
	if not pickItem.variables then
		return nil
	end

	local data = pickItem.variables[1]
	for _, variable in ipairs(pickItem.variables) do
		if variable.condition < data.condition then
			data = variable
		end
	end

	return data
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	this.despawn(e.session.pick)
end

---@private
---@param e pickCycledEventData
function this.onPickCycled(e)
	this.despawn(e.previousPick)
end

---@public
---@param pick tes3lockpick
---@return niNode
function this.getMesh(pick)
	local mesh = tes3.loadMesh(pick.mesh, true):clone() --[[@as niNode]]

	mesh.name = this.enums.objectNames.pick
	mesh:attachProperty(this.getZBufferProperty())

	return mesh
end

---@private
---@return niZBufferProperty
function this.getZBufferProperty()
	local property = niZBufferProperty.new()
	local zBufferIndex = this.enums.zBufferIndex

	property:setFlag(true, zBufferIndex.test)
	property:setFlag(true, zBufferIndex.write)

	return property
end

---@private
---@param pick pick
function this.despawn(pick)
	pick.helper:detachChild(pick.mesh)
end

return this
