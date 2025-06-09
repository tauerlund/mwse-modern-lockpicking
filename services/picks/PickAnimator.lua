--- SERVICES
local MeshAnimator = require("tauer.modern-lockpicking.shared.MeshAnimator")
---

--- ENUMS
local CONSTANTS = require("tauer.modern-lockpicking.services.picks.enums.constants")
---

---@class PickAnimator
local this = {}

---@private
---@type pick
this.pick = nil

---@public
---@param pick pick
function this.Start(pick)
	this.pick = pick

	MeshAnimator.Start({
		mesh = pick,
		durationInSeconds = CONSTANTS.animation.startAnimationDuration,
		originalRotation = CONSTANTS.rotation.original,
		targetRotation = CONSTANTS.rotation.target,
		originalTranslation = CONSTANTS.translation.original,
		targetTranslation = CONSTANTS.translation.target,
	})
end

return this
