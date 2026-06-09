---@class visualsPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
---@param services serviceCollection
function this.initialize(template, services)
	local settings = services.settings

	local translations = services.translations
	local translationKeys = services.enums.translationKeys

	local page = template:createSideBarPage({
		label = translations.get(translationKeys.mcmHeaderVisuals)
	})

	page:createOnOffButton({
		label = translations.get(translationKeys.mcmLitRenderingLabel),
		description = translations.get(translationKeys.mcmLitRenderingDesc),
		variable = mwse.mcm.createTableVariable({
			id = "litRendering",
			table = settings,
		}),
	})

	page:createOnOffButton({
		label = translations.get(translationKeys.mcmVisualsLabelEnableDof),
		description = translations.get(translationKeys.mcmVisualsDescEnableDof),
		variable = mwse.mcm.createTableVariable({
			id = "enableDof",
			table = settings,
		}),
	})
end

return this
