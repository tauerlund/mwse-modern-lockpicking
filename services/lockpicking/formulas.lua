--- Stateless gameplay formulas
---@class formulas
local this = {}

---@class sweetSpotRadiusParams
---@field public quality number
---@field public statsModifier number
---@field public lockLevel number
---@field public difficulty difficultySettings

--- Sweet spot radius in radians, clamped to difficulty.maxSweetSpotRadius (degrees).
---@public
---@param params sweetSpotRadiusParams
---@return number
function this.sweetSpotRadius(params)
	local difficulty = params.difficulty
	local radius = math.pi * params.quality ^ difficulty.qualityFactor * params.statsModifier * difficulty
		.securityFactor /
		(math.max(1, params.lockLevel) * difficulty.lockLevelFactor)
	return math.min(radius, math.rad(difficulty.maxSweetSpotRadius))
end

--- Maximum cylinder rotation for a pick at the given angle: unlimited inside the sweet spot,
--- falling linearly to zero across the gradient outside it.
---@public
---@param pickAngle number
---@param sweetSpot sweetSpotUpdatedEventData
---@param targetRotation number
---@return number
function this.maxAngle(pickAngle, sweetSpot, targetRotation)
	local distance = math.abs(pickAngle - sweetSpot.center)
	if distance <= sweetSpot.radius then
		return math.huge
	end

	if sweetSpot.gradientWidth == 0 then
		return 0
	end

	local overshoot = distance - sweetSpot.radius
	local fraction = math.max(0, 1 - overshoot / sweetSpot.gradientWidth)
	return targetRotation * fraction
end

--- Pick damage per second; smaller sweet spots damage picks faster.
---@public
---@param sweetSpotRadius number|nil
---@param difficulty difficultySettings
---@return number
function this.damageRate(sweetSpotRadius, difficulty)
	if not sweetSpotRadius or sweetSpotRadius <= 0 then
		return difficulty.baseRate
	end
	local maxRadius = math.rad(difficulty.maxSweetSpotRadius)
	return difficulty.baseRate * math.sqrt(maxRadius / sweetSpotRadius)
end

--- Tangent of a camera's vertical half-angle, derived from a horizontal
--- FOV (in degrees) and the viewport size.
---@public
---@param horizontalFov number
---@param viewportWidth number
---@param viewportHeight number
---@return number
function this.verticalTanFromHorizontalFov(horizontalFov, viewportWidth, viewportHeight)
	return math.tan(math.rad(horizontalFov) * 0.5) * (viewportHeight / viewportWidth)
end

--- Tangent of a camera's vertical half-angle, derived from its top culling
--- plane: the plane's normal lies in the direction/up plane, tilted from the
--- up axis by the half-angle. Indifferent to the normal's orientation and length.
---@public
---@param plane tes3vector4
---@param direction tes3vector3
---@param up tes3vector3
---@return number
function this.verticalTanFromCullingPlane(plane, direction, up)
	local normal = tes3vector3.new(plane.x, plane.y, plane.z)
	return math.abs(normal:dot(direction)) / math.abs(normal:dot(up))
end

--- Lock distance for a camera's vertical tangent, scaled from the base
--- distance (tuned at referenceVerticalTan) so the lock subtends the same
--- fraction of screen height on any aspect ratio and FOV, then adjusted by
--- the player's distance factor.
---@public
---@param baseDistance number
---@param referenceVerticalTan number
---@param verticalTan number
---@param distanceFactor number
---@return number
function this.lockTargetDistance(baseDistance, referenceVerticalTan, verticalTan, distanceFactor)
	return baseDistance * distanceFactor * referenceVerticalTan / verticalTan
end

--- Focus distance (in meters) for the Bokeh DOF shader: the shader's eye
--- model is focused exactly at the lock's depth, so the lock stays sharp at
--- any distance while the world behind it blurs. unitsToMeters mirrors the
--- unit2m constant inside the shader.
---@public
---@param distance number
---@param unitsToMeters number
---@return number
function this.dofFocusDistance(distance, unitsToMeters)
	return distance * unitsToMeters
end

--- Based on the formula described here: https://en.uesp.net/wiki/Morrowind:Security
--- A pick is eligible for a lock when this is greater than zero.
---@public
---@param statsModifier number
---@param quality number
---@param fatigueModifier number
---@param lockLevel number
---@return number
function this.successChance(statsModifier, quality, fatigueModifier, lockLevel)
	return (statsModifier * quality * fatigueModifier) - lockLevel
end

return this
