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

	page:createOnOffButton({
		label = translations.get(translationKeys.mcmVisualsLabelShowLockLevel),
		description = translations.get(translationKeys.mcmVisualsDescShowLockLevel),
		variable = mwse.mcm.createTableVariable({
			id = "showLockLevel",
			table = settings,
		}),
	})

	page:createOnOffButton({
		label = translations.get(translationKeys.mcmVisualsLabelShowPickHealth),
		description = translations.get(translationKeys.mcmVisualsDescShowPickHealth),
		variable = mwse.mcm.createTableVariable({
			id = "showPickHealth",
			table = settings,
		}),
	})

	page:createSlider({
		label = translations.get(translationKeys.mcmVisualsLabelLockDistance),
		description = translations.get(translationKeys.mcmVisualsDescLockDistance),
		min = 0.5,
		max = 2.0,
		step = 0.05,
		jump = 0.25,
		decimalPlaces = 2,
		variable = mwse.mcm.createTableVariable({
			id = "lockDistanceFactor",
			table = settings,
		}),
	})
end

return this
