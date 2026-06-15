---@class lockController : initializedService
local this = {}

---@private
---@type eventRegistrar
this.eventRegistrar = nil

---@private
---@type eventHandlers
this.eventHandlers = nil

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	this.enums = services.enums
	this.eventRegistrar = services.eventRegistrar

	local events = services.enums.events

	this.eventHandlers = {
		[events.lockpickingEnded] = this.onLockpickingEnded,
	}

	this.eventRegistrar.register(this.eventHandlers)
	return true, nil
end

---@public
function this.uninitialize()
	this.eventRegistrar.unregister(this.eventHandlers)
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	local activator = e.session.activator

	if e.session.rotationAttempted and not tes3.hasOwnershipAccess({ target = activator }) then
		this.triggerCrime()
	end

	if e.success then
		tes3.unlock({
			reference = activator
		})
		if not activator.lockNode.trap then
			this.activateWithDelay(activator)
		end
	end
end

---@private
function this.triggerCrime()
	local gmst = tes3.findGMST(tes3.gmst.iCrimeTresspass)
	local crimeGoldAmount = gmst
		and gmst.value ~= nil
		and gmst.value
		or this.enums.constants.locks.crimeGoldAmount

	tes3.triggerCrime({
		type = tes3.crimeType.trespass,
		value = crimeGoldAmount --[[@as number]]
	})
end

--- Activation needs to be delayed by 3 frames for crime detection to trigger when the activator is a door leading to another cell
---@private
---@param activator tes3reference
function this.activateWithDelay(activator)
	timer.delayOneFrame(function ()
		timer.delayOneFrame(function ()
			timer.delayOneFrame(function ()
				tes3.player:activate(activator --[[@as tes3reference]])
			end)
		end)
	end)
end

return this
