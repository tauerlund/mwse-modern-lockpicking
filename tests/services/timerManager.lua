---@class timerManagerTests : test
local this = {}

---@private
this.timerManager = require("tauer.modern-lockpicking.services.timers.timerManager")

---@public
---@param unitwind UnitWind
function this.run(unitwind)
    unitwind:start("Modern Lockpicking: timerManager")

    unitwind:test("Started timer is active with the given duration", function ()
        local cancel = this.eventName("duration")

        local t = this.timerManager.start({
            durationInSeconds = 10,
            cancelOn = { cancel },
        })

        unitwind:expect(t.state).toBe(timer.active)
        unitwind:expect(t.duration).toBe(10)

        event.trigger(cancel)
    end)

    unitwind:test("Cancellation event cancels the timer", function ()
        local cancel = this.eventName("cancel")

        local t = this.timerManager.start({
            durationInSeconds = 10,
            cancelOn = { cancel },
        })

        event.trigger(cancel)

        unitwind:expect(t.state).toBe(timer.expired)
    end)

    unitwind:test("Pause event pauses the timer", function ()
        local pause = this.eventName("pause.pause")
        local cancel = this.eventName("pause.cancel")

        local t = this.timerManager.start({
            durationInSeconds = 10,
            pauseOn = { pause },
            cancelOn = { cancel },
        })

        event.trigger(pause)

        unitwind:expect(t.state).toBe(timer.paused)

        event.trigger(cancel)
    end)

    unitwind:test("Resume event resumes a paused timer", function ()
        local pause = this.eventName("resume.pause")
        local resume = this.eventName("resume.resume")
        local cancel = this.eventName("resume.cancel")

        local t = this.timerManager.start({
            durationInSeconds = 10,
            pauseOn = { pause },
            resumeOn = { resume },
            cancelOn = { cancel },
        })

        event.trigger(pause)
        event.trigger(resume)

        unitwind:expect(t.state).toBe(timer.active)

        event.trigger(cancel)
    end)

    unitwind:test("Pause only affects the timer that registered it", function ()
        local pauseA = this.eventName("isolation.pauseA")
        local cancelA = this.eventName("isolation.cancelA")
        local pauseB = this.eventName("isolation.pauseB")
        local cancelB = this.eventName("isolation.cancelB")

        local a = this.timerManager.start({
            durationInSeconds = 10,
            pauseOn = { pauseA },
            cancelOn = { cancelA },
        })
        local b = this.timerManager.start({
            durationInSeconds = 10,
            pauseOn = { pauseB },
            cancelOn = { cancelB },
        })

        event.trigger(pauseA)

        unitwind:expect(a.state).toBe(timer.paused)
        unitwind:expect(b.state).toBe(timer.active)

        event.trigger(cancelA)
        event.trigger(cancelB)
    end)

    unitwind:test("Cancellation unregisters all of the timer's event handlers", function ()
        local cancelA = this.eventName("cleanup.cancelA")
        local cancelB = this.eventName("cleanup.cancelB")
        local pause = this.eventName("cleanup.pause")
        local resume = this.eventName("cleanup.resume")

        -- Spy on event.register to capture the handlers the timer creates internally,
        -- since they are anonymous closures we cannot reference any other way.
        ---@type { evt: string, callback: function }[]
        local recorded = {}
        local originalRegister = event.register
        unitwind:mock(event, "register", function (evt, callback, options)
            table.insert(recorded, { evt = evt, callback = callback })
            return originalRegister(evt, callback, options)
        end)

        this.timerManager.start({
            durationInSeconds = 10,
            cancelOn = { cancelA, cancelB },
            pauseOn = { pause },
            resumeOn = { resume },
        })

        unitwind:unmock(event, "register")

        event.trigger(cancelA)

        local stillRegistered = 0
        for _, entry in ipairs(recorded) do
            if event.isRegistered(entry.evt, entry.callback) then
                stillRegistered = stillRegistered + 1
            end
        end

        -- Two cancellation handlers, one pause, one resume.
        unitwind:expect(#recorded >= 4).toBe(true)
        unitwind:expect(stillRegistered).toBe(0)
    end)

    unitwind:finish()
end

--- Namespaced event name so test events cannot collide with the mod's own events.
---@private
---@param suffix string
---@return string
function this.eventName(suffix)
    return string.format("tauer.modern-lockpicking.tests.timerManager.%s", suffix)
end

return this
