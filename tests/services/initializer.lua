---@class initializerTests : test
local this = {}

---@private
this.initializerPath = "Data Files/MWSE/mods/tauer/modern-lockpicking/initializer.lua"

---@public
---@param unitwind UnitWind
function this.run(unitwind)
    unitwind:start("Modern Lockpicking: initializer")

    --- Name assignment ---

    unitwind:test("Service name is assigned from the table key", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local service = {}
        -- Act
        initializer.initialize({ myService = service }, {})
        -- Assert
        unitwind:expect(service.name).toBe("myService")
    end)

    unitwind:test("Services in unnamedServices are excluded from name assignment", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local service = {}
        -- Act
        initializer.initialize({
            myService = service,
            unnamedServices = function () return { service } end,
        }, {})
        -- Assert
        unitwind:expect(service.name).toBe(nil)
    end)

    unitwind:test("A service that already has a name is not overwritten", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local service = { name = "existingName" }
        -- Act
        initializer.initialize({ myService = service }, {})
        -- Assert
        unitwind:expect(service.name).toBe("existingName")
    end)

    unitwind:test("Services are named normally when unnamedServices is absent", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local service = {}
        -- Act
        initializer.initialize({ myService = service }, {})
        -- Assert
        unitwind:expect(service.name).toBe("myService")
    end)

    --- Service initialization ---

    unitwind:test("Services receive the services collection on initialize", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local receivedServices = nil
        local services = {}
        local service = {
            name = "s",
            initialize = function (s)
                receivedServices = s; return true
            end,
        }
        -- Act
        initializer.initialize(services, { service })
        -- Assert
        unitwind:expect(receivedServices).toBe(services)
    end)

    unitwind:test("Services are initialized in the given order", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local order = {}
        local serviceA = {
            name = "a",
            initialize = function ()
                table.insert(order, "a"); return true
            end
        }
        local serviceB = {
            name = "b",
            initialize = function ()
                table.insert(order, "b"); return true
            end
        }
        -- Act
        initializer.initialize({}, { serviceA, serviceB })
        -- Assert
        unitwind:expect(order[1]).toBe("a")
        unitwind:expect(order[2]).toBe("b")
    end)

    unitwind:test("Successfully initialized service is marked as initialized", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local service = { name = "s", initialize = function () return true end }
        -- Act
        initializer.initialize({}, { service })
        -- Assert
        unitwind:expect(service.initialized).toBe(true)
    end)

    unitwind:test("Failed service initialization stops the remaining services from initializing", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local laterCalled = false
        local failing = { name = "failing", initialize = function () return false, "broke" end }
        local later = {
            name = "later",
            initialize = function ()
                laterCalled = true; return true
            end
        }
        -- Act
        initializer.initialize({}, { failing, later })
        -- Assert
        unitwind:expect(laterCalled).toBe(false)
    end)

    unitwind:test("Failed initialization calls uninitialize on already-initialized services", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local uninitializeCalled = false
        local first = {
            name = "first",
            initialize = function () return true end,
            uninitialize = function () uninitializeCalled = true end,
        }
        local failing = { name = "failing", initialize = function () return false, "error" end }
        -- Act
        initializer.initialize({}, { first, failing })
        -- Assert
        unitwind:expect(uninitializeCalled).toBe(true)
    end)

    unitwind:test("Uninitialize is not called on services that did not get to initialize", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local uninitializeCalled = false
        local failing = { name = "failing", initialize = function () return false, "error" end }
        local notReached = {
            name = "notReached",
            initialize = function () return true end,
            uninitialize = function () uninitializeCalled = true end,
        }
        -- Act
        initializer.initialize({}, { failing, notReached })
        -- Assert
        unitwind:expect(uninitializeCalled).toBe(false)
    end)

    unitwind:test("Uninitialize is skipped for services that have no uninitialize method", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local first = { name = "first", initialize = function () return true end }
        local failing = { name = "failing", initialize = function () return false, "error" end }
        -- Act
        initializer.initialize({}, { first, failing })
        -- Assert
        unitwind:expect(first.initialized).toBe(true)
    end)

    --- Dependencies ---

    unitwind:test("Service initializes when its dependency was already initialized", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local reached = false
        local dep = { name = "dep", initialize = function () return true end }
        local dependent = {
            name = "dependent",
            dependencies = function () return { dep } end,
            initialize = function ()
                reached = true; return true
            end,
        }
        -- Act
        initializer.initialize({}, { dep, dependent })
        -- Assert
        unitwind:expect(reached).toBe(true)
    end)

    unitwind:test("Service with an uninitialized dependency fails", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local reached = false
        local dep = { name = "dep" }
        local dependent = {
            name = "dependent",
            dependencies = function () return { dep } end,
            initialize = function ()
                reached = true; return true
            end,
        }
        -- dep is not in the initialization list, so it is never marked initialized
        -- Act
        initializer.initialize({}, { dependent })
        -- Assert
        unitwind:expect(reached).toBe(false)
    end)

    unitwind:test("Dependencies function receives the services collection", function ()
        -- Arrange
        local initializer = dofile(this.initializerPath)
        local receivedServices = nil
        local services = {}
        local dep = { name = "dep", initialize = function () return true end }
        local dependent = {
            name = "dependent",
            dependencies = function (s)
                receivedServices = s; return { dep }
            end,
            initialize = function () return true end,
        }
        -- Act
        initializer.initialize(services, { dep, dependent })
        -- Assert
        unitwind:expect(receivedServices).toBe(services)
    end)

    unitwind:finish()
end

return this
