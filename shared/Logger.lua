local MWSELogger = require("logging.logger")

---@class LoggerFactoryFoo
local this = {}

---@enum
local LOG_LEVEL = {
	trace = "TRACE",
	debug = "DEBUG",
	info = "INFO",
	warn = "WARN",
	error = "ERROR",
	none = "NONE",
}

return MWSELogger.new({
	name = "Modern Lockpicking",
	logLevel = LOG_LEVEL.debug, --TODO: Change to INFO before full release,
	includeTimestamp = false,
})
