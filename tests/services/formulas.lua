---@class formulasTests : test
local this = {}

---@private
this.formulas = require("tauer.modern-lockpicking.services.lockpicking.formulas")

---@public
---@param unitwind UnitWind
function this.run(unitwind)
    unitwind:start("Modern Lockpicking: formulas")

    --- Sweet spot radius ---

    unitwind:test("Sweet spot radius follows the difficulty formula", function ()
        local radius = this.formulas.sweetSpotRadius({
            quality = 1.0,
            statsModifier = 30,
            lockLevel = 50,
            difficulty = this.createDifficulty(),
        })

        this.expectNear(unitwind, radius, math.pi * 30 / (50 * 5))
    end)

    unitwind:test("Sweet spot radius clamps at maxSweetSpotRadius", function ()
        local radius = this.formulas.sweetSpotRadius({
            quality = 5.0,
            statsModifier = 100,
            lockLevel = 1,
            difficulty = this.createDifficulty({ maxSweetSpotRadius = 45 }),
        })

        unitwind:expect(radius).toBe(math.rad(45))
    end)

    unitwind:test("Sweet spot radius treats lock levels below 1 as level 1", function ()
        local params = {
            quality = 1.0,
            statsModifier = 30,
            difficulty = this.createDifficulty(),
        }

        params.lockLevel = 0
        local unleveled = this.formulas.sweetSpotRadius(params)
        params.lockLevel = 1
        local levelOne = this.formulas.sweetSpotRadius(params)

        unitwind:expect(unleveled).toBe(levelOne)
    end)

    unitwind:test("Sweet spot radius shrinks as the lock level rises", function ()
        local params = {
            quality = 1.0,
            statsModifier = 30,
            difficulty = this.createDifficulty(),
        }

        params.lockLevel = 50
        local easy = this.formulas.sweetSpotRadius(params)
        params.lockLevel = 100
        local hard = this.formulas.sweetSpotRadius(params)

        unitwind:expect(hard < easy).toBe(true)
    end)

    --- Max cylinder angle ---

    ---@type sweetSpotUpdatedEventData
    local sweetSpot = { center = 0.25, radius = 0.5, gradientWidth = 0.25 }

    unitwind:test("Max angle is unlimited inside the sweet spot", function ()
        local maxAngle = this.formulas.maxAngle(0.25, sweetSpot, 2.0)

        unitwind:expect(maxAngle).toBe(math.huge)
    end)

    unitwind:test("Max angle is unlimited exactly at the sweet spot edge", function ()
        local maxAngle = this.formulas.maxAngle(0.75, sweetSpot, 2.0)

        unitwind:expect(maxAngle).toBe(math.huge)
    end)

    unitwind:test("Max angle falls linearly across the gradient", function ()
        -- Halfway into the gradient: overshoot 0.125 of gradientWidth 0.25.
        local maxAngle = this.formulas.maxAngle(0.875, sweetSpot, 2.0)

        unitwind:expect(maxAngle).toBe(1.0)
    end)

    unitwind:test("Max angle reaches exactly zero at the edge of the gradient", function ()
        local maxAngle = this.formulas.maxAngle(1.0, sweetSpot, 2.0)

        unitwind:expect(maxAngle).toBe(0)
    end)

    unitwind:test("Max angle stays zero beyond the gradient", function ()
        local maxAngle = this.formulas.maxAngle(3.0, sweetSpot, 2.0)

        unitwind:expect(maxAngle).toBe(0)
    end)

    unitwind:test("Max angle is symmetric around the sweet spot center", function ()
        local clockwise = this.formulas.maxAngle(0.875, sweetSpot, 2.0)
        local counterclockwise = this.formulas.maxAngle(-0.375, sweetSpot, 2.0)

        unitwind:expect(counterclockwise).toBe(clockwise)
    end)

    unitwind:test("Max angle with zero gradient width is zero, not a division by zero", function ()
        ---@type sweetSpotUpdatedEventData
        local hardSpot = { center = 0.25, radius = 0.5, gradientWidth = 0 }

        local maxAngle = this.formulas.maxAngle(1.0, hardSpot, 2.0)

        unitwind:expect(maxAngle).toBe(0)
    end)

    --- Damage rate ---

    unitwind:test("Damage rate is the base rate when there is no sweet spot yet", function ()
        local rate = this.formulas.damageRate(nil, this.createDifficulty({ baseRate = 2 }))

        unitwind:expect(rate).toBe(2)
    end)

    unitwind:test("Damage rate is the base rate at the maximum sweet spot radius", function ()
        local rate = this.formulas.damageRate(math.rad(45), this.createDifficulty())

        unitwind:expect(rate).toBe(1)
    end)

    unitwind:test("Damage rate grows as the sweet spot shrinks", function ()
        -- A quarter of the max radius gives sqrt(4) = 2x the base rate.
        local rate = this.formulas.damageRate(math.rad(45) / 4, this.createDifficulty())

        unitwind:expect(rate).toBe(2)
    end)

    unitwind:test("Damage rate falls back to the base rate at zero radius", function ()
        local rate = this.formulas.damageRate(0, this.createDifficulty())

        unitwind:expect(rate).toBe(1)
    end)

    --- Success chance ---

    unitwind:test("Success chance follows the vanilla security formula", function ()
        local chance = this.formulas.successChance(61, 1.25, 1.0, 50)

        unitwind:expect(chance).toBe(61 * 1.25 - 50)
    end)

    unitwind:test("Success chance is zero at the eligibility boundary", function ()
        local chance = this.formulas.successChance(40, 1.0, 1.25, 50)

        unitwind:expect(chance).toBe(0)
    end)

    --- Camera vertical tangent ---

    unitwind:test("Vertical tangent of a 90 degree FOV on a square viewport is 1", function ()
        local verticalTan = this.formulas.verticalTanFromHorizontalFov(90, 1000, 1000)

        this.expectNear(unitwind, verticalTan, 1)
    end)

    unitwind:test("Vertical tangent matches across aspect ratios when the vertical FOV is equal", function ()
        local ultrawide = this.formulas.verticalTanFromHorizontalFov(math.deg(2 * math.atan(2)), 3200, 900)
        local widescreen = this.formulas.verticalTanFromHorizontalFov(90, 1600, 900)

        this.expectNear(unitwind, ultrawide, widescreen)
    end)

    unitwind:test("Vertical tangent from the top culling plane recovers the half-angle", function ()
        local halfAngle = math.rad(25)
        local direction = tes3vector3.new(0.6, 0.8, 0)
        local up = tes3vector3.new(0, 0, 1)
        local plane = this.createTopPlane(direction, up, halfAngle, 1, 7)

        local verticalTan = this.formulas.verticalTanFromCullingPlane(plane, direction, up)

        this.expectNear(unitwind, verticalTan, math.tan(halfAngle))
    end)

    unitwind:test("Vertical tangent from the culling plane ignores normal orientation and length", function ()
        local halfAngle = math.rad(30)
        local direction = tes3vector3.new(0, 1, 0)
        local up = tes3vector3.new(0, 0, 1)
        local inward = this.createTopPlane(direction, up, halfAngle, 1, 0)
        local outwardScaled = this.createTopPlane(direction, up, halfAngle, -3, 12)

        local fromInward = this.formulas.verticalTanFromCullingPlane(inward, direction, up)
        local fromOutward = this.formulas.verticalTanFromCullingPlane(outwardScaled, direction, up)

        this.expectNear(unitwind, fromInward, fromOutward)
    end)

    --- Lock target distance ---

    unitwind:test("Lock distance is the base distance at the reference tangent", function ()
        local distance = this.formulas.lockTargetDistance(80, 0.5, 0.5, 1.0)

        unitwind:expect(distance).toBe(80)
    end)

    unitwind:test("Lock distance halves when the vertical tangent doubles", function ()
        local distance = this.formulas.lockTargetDistance(80, 0.5, 1.0, 1.0)

        unitwind:expect(distance).toBe(40)
    end)

    unitwind:test("Lock distance scales linearly with the player's distance factor", function ()
        local distance = this.formulas.lockTargetDistance(80, 0.5, 0.5, 1.5)

        unitwind:expect(distance).toBe(120)
    end)

    --- DOF focus distance ---

    unitwind:test("DOF focus is the lock's depth in meters", function ()
        local focus = this.formulas.dofFocusDistance(80, 0.0142)

        this.expectNear(unitwind, focus, 1.136)
    end)

    unitwind:finish()
end

--- Difficulty settings mirroring the MCM defaults, with optional overrides.
---@private
---@param overrides table?
---@return difficultySettings
function this.createDifficulty(overrides)
    ---@type difficultySettings
    local difficulty = {
        securityFactor = 1.0,
        lockLevelFactor = 5.0,
        qualityFactor = 1.0,
        gradientFactor = 2.0,
        maxSweetSpotRadius = 45,
        baseRate = 1,
        damageSkeletonKey = false,
    }
    for key, value in pairs(overrides or {}) do
        difficulty[key] = value
    end
    return difficulty
end

--- Top culling plane for a camera frame: the normal sits in the direction/up
--- plane, tilted from the up axis by the vertical half-angle. scale flips or
--- stretches the normal; w stands in for an arbitrary plane distance.
---@private
---@param direction tes3vector3
---@param up tes3vector3
---@param halfAngle number
---@param scale number
---@param w number
---@return tes3vector4
function this.createTopPlane(direction, up, halfAngle, scale, w)
    local normal = (direction * math.sin(halfAngle) - up * math.cos(halfAngle)) * scale
    return tes3vector4.new(normal.x, normal.y, normal.z, w)
end

--- Compares floats via fixed-point formatting so failures log both numbers.
---@private
---@param unitwind UnitWind
---@param actual number
---@param expected number
function this.expectNear(unitwind, actual, expected)
    unitwind:expect(string.format("%.9f", actual)).toBe(string.format("%.9f", expected))
end

return this
