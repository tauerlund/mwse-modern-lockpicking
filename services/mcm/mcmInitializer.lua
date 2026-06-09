---@class mcmInitializer : initializedService
local this = {}

--- @private
--- @type mcmPage[]
this.pages = {
	require("tauer.modern-lockpicking.services.mcm.pages.controlsPage"),
	require("tauer.modern-lockpicking.services.mcm.pages.difficultyPage"),
	require("tauer.modern-lockpicking.services.mcm.pages.visualsPage"),
	require("tauer.modern-lockpicking.services.mcm.pages.debuggingPage")
}

---@private
this.headerImagePath = "textures\\tauer\\modern-lockpicking\\logo.tga"

---@private
---@type mcmSettings
this.settings = nil

---@private
---@type enums
this.enums = nil

---@public
---@param services serviceCollection
---@return boolean, string|nil
function this.initialize(services)
	this.settings = services.mcmSettings
	this.enums = services.enums
	local translationKeys = services.enums.translationKeys

	local template = mwse.mcm.createTemplate({
		name = services.translations.get(translationKeys.modName),
		headerImagePath = this.headerImagePath,
		onClose = this.onClose
	})

	for _, page in ipairs(this.pages) do
		page.initialize(template, services)
	end

	template:register()

	return true, nil
end

---@private
function this.onClose()
	this.settings.save()
	event.trigger(this.enums.events.settingsUpdated)
end

return this
