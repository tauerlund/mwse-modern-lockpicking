---@diagnostic disable: invisible

---@class pickSpawnerTests : test
local this = {}

---@private
this.pickSpawner = require("tauer.modern-lockpicking.services.picks.pickSpawner")

---@public
---@param unitwind UnitWind
function this.run(unitwind)
    unitwind:start("Modern Lockpicking: pickSpawner")

    unitwind:test("resolveItemData returns nil when variables is nil", function ()
        unitwind:expect(this.pickSpawner.resolveItemData(this.fakePickItem(nil))).toBe(nil)
    end)

    unitwind:test("resolveItemData returns the single item data", function ()
        local itemData = { condition = 50 }
        local result = this.pickSpawner.resolveItemData(this.fakePickItem(this.fakeVariables(itemData)))
        unitwind:expect(result).toBe(itemData)
    end)

    unitwind:test("resolveItemData returns the lowest-condition item data", function ()
        local high = { condition = 80 }
        local low  = { condition = 30 }
        unitwind:expect(this.pickSpawner.resolveItemData(this.fakePickItem(this.fakeVariables(high, low)))).toBe(low)
        unitwind:expect(this.pickSpawner.resolveItemData(this.fakePickItem(this.fakeVariables(low, high)))).toBe(low)
    end)

    -- Regression: sol2's ipairs for tes3tarray iterates begin()..end() and yields nil
    -- for erased (null) slots. When one pick from a multi-entry stack broke and was
    -- removed via removePick, the vanilla engine zeroed its variables slot without
    -- compacting the array, leaving a null hole. resolveItemData must skip those nil
    -- entries rather than crashing on variable.condition.
    unitwind:test("resolveItemData skips nil entries left by erased tarray slots", function ()
        local itemData = { condition = 50 }
        unitwind:expect(this.pickSpawner.resolveItemData(this.fakePickItem(this.fakeVariables(nil, itemData)))).toBe(
            itemData)
        unitwind:expect(this.pickSpawner.resolveItemData(this.fakePickItem(this.fakeVariables(itemData, nil)))).toBe(
            itemData)
    end)

    unitwind:test("resolveItemData returns nil when all tarray slots are nil", function ()
        unitwind:expect(this.pickSpawner.resolveItemData(this.fakePickItem(this.fakeVariables(nil)))).toBe(nil)
    end)

    unitwind:finish()
end

---@private
---@param variables any
---@return tes3itemStack
function this.fakePickItem(variables)
    ---@diagnostic disable-next-line: missing-fields
    return { variables = variables } --[[@as tes3itemStack]]
end

-- Builds a fake variables object whose __ipairs yields every slot in order,
-- including nil ones — matching sol2's begin()..end() container iteration.
-- (Standard Lua ipairs would stop at the first nil; __ipairs overrides that.)
---@private
function this.fakeVariables(...)
    local slots = { ... }
    local count = select('#', ...)
    return setmetatable({}, {
        __ipairs = function (_)
            local i = 0
            return function ()
                i = i + 1
                if i <= count then
                    return i, slots[i]
                end
            end
        end,
    })
end

return this
