---@class lockController : initializedService
local this = {}

---@private
---@type tes3reference
this.activator = nil

---@public
---@param services serviceCollection
---@return boolean,string|nil
function this.initialize(services)
	local events = services.enums.events

	event.register(events.lockpickingStarted, this.onLockpickingStarted)
	event.register(events.lockpickingEnded, this.onLockpickingEnded)
	return true, nil
end

---@private
---@param e lockpickingStartedEventData
function this.onLockpickingStarted(e)
	this.activator = e.session.activator
end

---@private
---@param e lockpickingEndedEventData
function this.onLockpickingEnded(e)
	if not this.activator then
		return
	end

	if e.success then
		local activator = this.activator
		tes3.unlock({
			reference = activator --[[@as tes3reference]]
		})
		timer.delayOneFrame(function ()
			tes3.player:activate(activator --[[@as tes3reference]])
		end)
	end

	this.activator = nil
end

return this
