---@class testSuite
local this = {}

---@public
this.enabled = true

---@private
this.root = "Data Files\\MWSE\\mods\\tauer\\modern-lockpicking\\tests"

---@private
this.folders = {
    "services",
}

---@private
this.logger = mwse.Logger.new()

---@public
function this.run()
    local framework = include("unitwind") --[[@as UnitWind]]
    if not framework then
        this.logger:info("UnitWind is not installed; skipping unit tests.")
        return
    end

    local unitwind = framework.new({
        enabled = true,
        highlight = false,
        exitAfter = false,
    }) --[[@as UnitWind]]

    local tests = this.resolveTests()
    for _, test in ipairs(tests) do
        test.run(unitwind)
    end
end

---@private
---@return test[]
function this.resolveTests()
    ---@type test[]
    local tests = {}

    for _, folder in ipairs(this.folders) do
        local directory = string.format("%s\\%s", this.root, folder)

        if not lfs.directoryexists(directory) then
            this.logger:error("Test directory '%s' does not exist", directory)
            return tests
        end

        for file in lfs.dir(directory) do
            if file:match("%.lua$") then
                local test = require(string.format("tauer.modern-lockpicking.tests.%s.%s", folder,
                    file:gsub("%.lua$", ""))) --[[@as test]]
                table.insert(tests, test)
            end
        end
    end

    return tests
end

return this
