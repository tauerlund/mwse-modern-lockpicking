---@class skillControllerTests : test
local this = {}

---@private
this.skillControllerPath = "Data Files/MWSE/mods/tauer/modern-lockpicking/services/skills/skillController.lua"

--- Mocked once per run and mutated between tests: unitwind's mock() saves the current value
--- as the original, so mocking the same key twice would restore the first fake on cleanup.
---@private
this.mobilePlayer = {}

---@public
---@param unitwind UnitWind
function this.run(unitwind)
    unitwind:start("Modern Lockpicking: skillController")
    unitwind:mock(tes3, "mobilePlayer", this.mobilePlayer)

    unitwind:test("Stats modifier combines security, agility and luck", function ()
        local skillController = this.setup({ security = 50, agility = 40, luck = 30 })

        local result = skillController.getStatsModifier()

        unitwind:expect(result).toBe(50 + 40 / 5 + 30 / 10)
    end)

    unitwind:test("Success chance follows the vanilla security formula at full fatigue", function ()
        local skillController = this.setup({ security = 40, normalizedFatigue = 1.0 })
        local pick = { object = { quality = 1.0 } }
        local lock = { level = 25 }

        local result = skillController.getSuccessChance(pick, lock)

        unitwind:expect(result).toBe(40 * 1.25 - 25)
    end)

    unitwind:test("Success chance at zero fatigue uses the 0.75 floor", function ()
        local skillController = this.setup({ security = 40, normalizedFatigue = 0 })
        local pick = { object = { quality = 1.0 } }
        local lock = { level = 30 }

        local result = skillController.getSuccessChance(pick, lock)

        unitwind:expect(result).toBe(0)
    end)

    unitwind:test("Success chance scales with pick quality", function ()
        local skillController = this.setup({ security = 40, normalizedFatigue = 1.0 })
        local pick = { object = { quality = 5.0 } }
        local lock = { level = 100 }

        local result = skillController.getSuccessChance(pick, lock)

        unitwind:expect(result).toBe(40 * 5.0 * 1.25 - 100)
    end)

    unitwind:finish()
end

---@class skillControllerTests.setup.params
---@field security number?
---@field agility number?
---@field luck number?
---@field normalizedFatigue number?

--- Configures the mobile player mock and loads a fresh skillController instance.
---@private
---@param params skillControllerTests.setup.params
---@return skillController
function this.setup(params)
    local mobilePlayer = this.mobilePlayer
    mobilePlayer.getSkillValue = function (_, skill)
        return skill == tes3.skill.security and (params.security or 0) or 0
    end
    mobilePlayer.attributes = {
        [tes3.attribute.agility] = { current = params.agility or 0 },
        [tes3.attribute.luck] = { current = params.luck or 0 },
    }
    mobilePlayer.fatigue = { normalized = params.normalizedFatigue or 1.0 }

    local services = {
        formulas = require("tauer.modern-lockpicking.services.lockpicking.formulas"),
        enums = {
            events = require("tauer.modern-lockpicking.services.events.enums.events"),
        },
        eventRegistrar = {
            register = function () end,
            unregister = function () end,
        },
    }

    local skillController = dofile(this.skillControllerPath) ---@type skillController
    skillController.initialize(services --[[@as serviceCollection]])
    return skillController
end

return this
