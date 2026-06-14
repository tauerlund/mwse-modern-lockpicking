--- Stateless gameplay formulas
---@class formulas
local this = {}

--- Baked sweet-spot baseline
local sweetSpotBase = math.pi / 5

--- Baked default weighting exponents. Each MCM weight scales its exponent and
--- defaults to 1.0, so every difficulty slider reads "1.0 = default". Lock level
--- is steeper than linear by default so high-level locks tighten the sweet spot
--- faster than skill or quality widen it.
local qualityBaseExponent = 1.0
local securityBaseExponent = 1.0
local lockLevelBaseExponent = 1.5

--- Baked gradient baseline (formerly the gradientFactor default of 2.0), so
--- gradientFactor reads as a multiplier on the default width, defaulting to 1.0.
local gradientBase = 2.0

---@class sweetSpotRadiusParams
---@field public quality number
---@field public statsModifier number
---@field public lockLevel number
---@field public difficulty difficultySettings

--- Sweet spot radius in radians, clamped between difficulty.minSweetSpotRadius and
--- difficulty.maxSweetSpotRadius (degrees). The floor keeps locks pickable even when
--- difficulty is cranked up far enough to otherwise drive the radius toward zero.
--- Quality, security skill and lock level each enter as a weighting exponent
--- scaled by its MCM weight (all weights default to 1.0). A weight on a different
--- input cannot be folded into the others, so the three knobs stay distinct.
--- Independent of successChance, which keeps the exact vanilla eligibility
--- formula untouched.
---@public
---@param params sweetSpotRadiusParams
---@return number
function this.sweetSpotRadius(params)
	local difficulty = params.difficulty
	local radius = sweetSpotBase
		* params.quality ^ (qualityBaseExponent * difficulty.qualityWeight)
		* params.statsModifier ^ (securityBaseExponent * difficulty.securityWeight)
		/ math.max(1, params.lockLevel) ^ (lockLevelBaseExponent * difficulty.lockLevelWeight)
	return math.clamp(radius, math.rad(difficulty.minSweetSpotRadius), math.rad(difficulty.maxSweetSpotRadius))
end

--- Width of the gradient zone (in radians) outside the sweet spot. gradientFactor
--- is a multiplier on the baked default width (1.0 = default).
---@public
---@param radius number
---@param difficulty difficultySettings
---@return number
function this.gradientWidth(radius, difficulty)
	return radius * gradientBase * difficulty.gradientFactor
end

---@class maxAngleParams
---@field public pickAngle number
---@field public sweetSpot sweetSpotUpdatedEventData
---@field public targetRotation number

--- Maximum cylinder rotation for a pick at the given angle: unlimited inside the sweet spot,
--- falling linearly to zero across the gradient outside it.
---@public
---@param params maxAngleParams
---@return number
function this.maxAngle(params)
	local sweetSpot = params.sweetSpot
	local distance = math.abs(params.pickAngle - sweetSpot.center)
	if distance <= sweetSpot.radius then
		return math.huge
	end

	if sweetSpot.gradientWidth == 0 then
		return 0
	end

	local overshoot = distance - sweetSpot.radius
	local fraction = math.max(0, 1 - overshoot / sweetSpot.gradientWidth)
	return params.targetRotation * fraction
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

---@class verticalTanFromCullingPlaneParams
---@field public plane tes3vector4
---@field public direction tes3vector3
---@field public up tes3vector3

--- Tangent of a camera's vertical half-angle, derived from its top culling
--- plane: the plane's normal lies in the direction/up plane, tilted from the
--- up axis by the half-angle. Indifferent to the normal's orientation and length.
---@public
---@param params verticalTanFromCullingPlaneParams
---@return number
function this.verticalTanFromCullingPlane(params)
	local plane = params.plane
	local normal = tes3vector3.new(plane.x, plane.y, plane.z)
	return math.abs(normal:dot(params.direction)) / math.abs(normal:dot(params.up))
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

---@class dofFocusDistanceParams
---@field public distance number
---@field public unitsToMeters number

--- Focus distance (in meters) for the Bokeh DOF shader: the shader's eye
--- model is focused exactly at the lock's depth, so the lock stays sharp at
--- any distance while the world behind it blurs. unitsToMeters mirrors the
--- unit2m constant inside the shader.
---@public
---@param params dofFocusDistanceParams
---@return number
function this.dofFocusDistance(params)
	return params.distance * params.unitsToMeters
end

---@class randomVarianceParams
---@field public base number
---@field public variance number
---@field public roll number

--- Randomized magnitude: scales base by (1 + roll * variance) for a roll in
--- [-1, 1]. The result keeps the sign of base as long as variance <= 1;
--- larger variances let extreme rolls flip the direction.
---@public
---@param params randomVarianceParams
---@return number
function this.randomVariance(params)
	return params.base * (1 + params.roll * params.variance)
end

--- Vertical offset of the falling broken pick: a gravity-like quadratic drop
--- with a sine bounce arc on top. Starts at 0 and ends exactly at
--- -fallDistance, since the bounce term vanishes at both ends.
---@public
---@param fallDistance number
---@param bounceHeight number
---@param phase number
---@return number
function this.breakFallOffset(fallDistance, bounceHeight, phase)
	return bounceHeight * math.sin(math.pi * phase) - fallDistance * phase * phase
end

---@class successChanceParams
---@field public statsModifier number
---@field public quality number
---@field public fatigueModifier number
---@field public lockLevel number

--- Based on the formula described here: https://en.uesp.net/wiki/Morrowind:Security
--- A pick is eligible for a lock when this is greater than zero.
---@public
---@param params successChanceParams
---@return number
function this.successChance(params)
	return (params.statsModifier * params.quality * params.fatigueModifier) - params.lockLevel
end

return this
