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
