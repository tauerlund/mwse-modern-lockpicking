---@class pickSelectorTests : test
local this = {}

---@private
this.pickSelectorPath = "Data Files/MWSE/mods/tauer/modern-lockpicking/services/picks/pickSelector.lua"

---@private
this.enums = {
    events = require("tauer.modern-lockpicking.services.events.enums.events"),
    cycleDirections = require("tauer.modern-lockpicking.services.lockpicking.enums.cycleDirections"),
    activationStrategyNames = require(
        "tauer.modern-lockpicking.services.lockpicking.activation-strategies.enums.activationStrategyNames"),
}

---@private
this.nextDirection = this.enums.cycleDirections.next

---@private
this.previousDirection = this.enums.cycleDirections.previous

---@public
---@param unitwind UnitWind
function this.run(unitwind)
    unitwind:start("Modern Lockpicking: pickSelector")

    unitwind:test("Initial selection returns first pick when nothing is saved or equipped", function ()
        local pickSelector = this.setup()
        local picks = this.createPicks({ "apprentice" }, { "journeyman" }, { "master" })

        local result = pickSelector.select({ picks = picks })

        unitwind:expect(result).toBe(picks[1])
    end)

    unitwind:test("Initial selection skips empty stacks", function ()
        local pickSelector = this.setup()
        local picks = this.createPicks({ "apprentice", 0 }, { "journeyman" })

        local result = pickSelector.select({ picks = picks })

        unitwind:expect(result).toBe(picks[2])
    end)

    unitwind:test("Initial selection prefers the last used pick in default mode", function ()
        local pickSelector = this.setup({ lastPickId = "journeyman" })
        local picks = this.createPicks({ "apprentice" }, { "journeyman" }, { "master" })

        local result = pickSelector.select({ picks = picks })

        unitwind:expect(result).toBe(picks[2])
    end)

    unitwind:test("Initial selection ignores the last used pick when it is ineligible", function ()
        local pickSelector = this.setup({ lastPickId = "apprentice" })
        local picks = this.createPicks({ "apprentice" }, { "journeyman" })

        local result = pickSelector.select({
            picks = picks,
            eligiblePicks = { journeyman = true },
        })

        unitwind:expect(result).toBe(picks[2])
    end)

    unitwind:test("Initial selection prefers the equipped pick in attack mode", function ()
        local pickSelector = this.setup({
            activationStrategy = this.enums.activationStrategyNames.attack,
            equippedPickId = "master",
            lastPickId = "apprentice",
        })
        local picks = this.createPicks({ "apprentice" }, { "journeyman" }, { "master" })

        local result = pickSelector.select({ picks = picks })

        unitwind:expect(result).toBe(picks[3])
    end)

    unitwind:test("Initial selection falls back to the first pick when nothing is eligible", function ()
        local pickSelector = this.setup()
        local picks = this.createPicks({ "apprentice" }, { "journeyman" })

        local result = pickSelector.select({
            picks = picks,
            eligiblePicks = {},
        })

        unitwind:expect(result).toBe(picks[1])
    end)

    --- Cycling ---

    unitwind:test("Cycling next advances to the next pick", function ()
        local pickSelector = this.setup()
        local picks = this.createPicks({ "apprentice" }, { "journeyman" })
        pickSelector.select({ picks = picks })

        local result = pickSelector.select({ picks = picks, direction = this.nextDirection })

        unitwind:expect(result).toBe(picks[2])
    end)

    unitwind:test("Cycling next wraps around at the end", function ()
        local pickSelector = this.setup({ lastPickId = "master" })
        local picks = this.createPicks({ "apprentice" }, { "journeyman" }, { "master" })
        pickSelector.select({ picks = picks })

        local result = pickSelector.select({ picks = picks, direction = this.nextDirection })

        unitwind:expect(result).toBe(picks[1])
    end)

    unitwind:test("Cycling previous wraps around at the start", function ()
        local pickSelector = this.setup()
        local picks = this.createPicks({ "apprentice" }, { "journeyman" }, { "master" })
        pickSelector.select({ picks = picks })

        local result = pickSelector.select({ picks = picks, direction = this.previousDirection })

        unitwind:expect(result).toBe(picks[3])
    end)

    unitwind:test("Cycling skips ineligible picks", function ()
        local pickSelector = this.setup()
        local picks = this.createPicks({ "apprentice" }, { "journeyman" }, { "master" })
        pickSelector.select({
            picks = picks,
            eligiblePicks = { apprentice = true, master = true },
        })

        local result = pickSelector.select({ picks = picks, direction = this.nextDirection })

        unitwind:expect(result).toBe(picks[3])
    end)

    unitwind:test("Cycling skips empty stacks", function ()
        local pickSelector = this.setup()
        local picks = this.createPicks({ "apprentice" }, { "journeyman", 0 }, { "master" })
        pickSelector.select({ picks = picks })

        local result = pickSelector.select({ picks = picks, direction = this.nextDirection })

        unitwind:expect(result).toBe(picks[3])
    end)

    unitwind:test("Cycling returns to the starting pick when no other pick is selectable", function ()
        local pickSelector = this.setup()
        local picks = this.createPicks({ "apprentice" }, { "journeyman" }, { "master" })
        pickSelector.select({ picks = picks })

        local result = pickSelector.select({
            picks = picks,
            direction = this.nextDirection,
            eligiblePicks = { apprentice = true },
        })

        unitwind:expect(result).toBe(picks[1])
    end)

    unitwind:test("Cycling terminates when the picks array shrank below the current index", function ()
        -- Regression test: breaking the last pick in the array used to leave currentIndex out of
        -- range, and cycling with no eligible picks left would never hit either exit condition,
        -- freezing the game.
        local pickSelector = this.setup({ lastPickId = "master" })
        local picks = this.createPicks({ "apprentice" }, { "journeyman" }, { "master" })
        pickSelector.select({ picks = picks })

        local remainingPicks = this.createPicks({ "apprentice" }, { "journeyman" })
        local result = pickSelector.select({
            picks = remainingPicks,
            direction = this.nextDirection,
            eligiblePicks = {},
        })

        unitwind:expect(result).NOT.toBe(nil)
    end)

    unitwind:test("Eligible picks persist across calls when not passed again", function ()
        local pickSelector = this.setup()
        local picks = this.createPicks({ "apprentice" }, { "journeyman" }, { "master" })
        pickSelector.select({
            picks = picks,
            eligiblePicks = { apprentice = true, master = true },
        })

        local result = pickSelector.select({ picks = picks, direction = this.nextDirection })

        unitwind:expect(result).toBe(picks[3])
    end)

    unitwind:finish()
end

--- Builds fake pick stacks from { id, count? } definitions, e.g. createPicks({ "a" }, { "b", 0 }).
---@private
---@param ... { [1]: string, [2]: integer? }
---@return tes3itemStack[]
function this.createPicks(...)
    local picks = {}
    for _, definition in ipairs({ ... }) do
        table.insert(picks, {
            object = { id = definition[1] },
            count = definition[2] or 1,
        })
    end
    return picks
end

---@class pickSelectorTests.setup.params
---@field lastPickId string?
---@field equippedPickId string?
---@field activationStrategy activationStrategyNames?

--- Loads a fresh pickSelector instance and initializes it with fake dependencies.
--- Uses dofile because the service is a stateful singleton: MWSE's require would return
--- the same cached instance every time, leaking state between tests (and into the live mod).
---@private
---@param params pickSelectorTests.setup.params?
---@return pickSelector
function this.setup(params)
    params = params or {}

    local playerData = { lastPickId = params.lastPickId }
    local equippedPick = params.equippedPickId and { id = params.equippedPickId } or nil

    local services = {
        playerDataController = {
            resolve = function () return playerData end,
        },
        inventoryController = {
            tryGetEquippedPick = function () return equippedPick end,
        },
        settings = {
            activationStrategy = params.activationStrategy or this.enums.activationStrategyNames.default,
        },
        enums = this.enums,
        eventRegistrar = {
            register = function () end,
            unregister = function () end,
        },
    }

    local pickSelector = dofile(this.pickSelectorPath) ---@type pickSelector
    pickSelector.initialize(services --[[@as serviceCollection]])
    return pickSelector
end

return this
