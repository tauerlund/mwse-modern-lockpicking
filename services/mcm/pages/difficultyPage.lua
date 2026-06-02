---@class difficultyPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
---@param services serviceCollection
function this.initialize(template, services)
	local settings = services.mcmSettings

	local translations = services.translations
	local translationKeys = services.enums.translationKeys

	local page = template:createSideBarPage({
		label = translations.get(translationKeys.mcmHeaderDifficulty)
	})

	local sweetSpotCategory = page:createCategory({
		label = translations.get(translationKeys
			.mcmDifficultyCategorySweetSpot)
	})

	sweetSpotCategory:createSlider({
		label = translations.get(translationKeys.mcmDifficultyLabelSecurityFactor),
		description = translations.get(translationKeys.mcmDifficultyDescSecurityFactor),
		min = 0.1,
		max = 10.0,
		step = 0.1,
		jump = 0.5,
		decimalPlaces = 1,
		variable = mwse.mcm.createTableVariable({
			id = "securityFactor",
			table = settings.mcm.difficulty,
		}),
	})

	sweetSpotCategory:createSlider({
		label = translations.get(translationKeys.mcmDifficultyLabelLockLevelFactor),
		description = translations.get(translationKeys.mcmDifficultyDescLockLevelFactor),
		min = 0.1,
		max = 20.0,
		step = 0.1,
		jump = 1.0,
		decimalPlaces = 1,
		variable = mwse.mcm.createTableVariable({
			id = "lockLevelFactor",
			table = settings.mcm.difficulty,
		}),
	})

	sweetSpotCategory:createSlider({
		label = translations.get(translationKeys.mcmDifficultyLabelQualityFactor),
		description = translations.get(translationKeys.mcmDifficultyDescQualityFactor),
		min = 0.1,
		max = 10.0,
		step = 0.1,
		jump = 0.5,
		decimalPlaces = 1,
		variable = mwse.mcm.createTableVariable({
			id = "qualityFactor",
			table = settings.mcm.difficulty,
		}),
	})

	sweetSpotCategory:createSlider({
		label = translations.get(translationKeys.mcmDifficultyLabelMaxRadius),
		description = translations.get(translationKeys.mcmDifficultyDescMaxRadius),
		min = 5,
		max = 89,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable({
			id = "maxSweetSpotRadius",
			table = settings.mcm.difficulty,
		}),
	})

	local pickDamageCategory = page:createCategory({
		label = translations.get(translationKeys
			.mcmDifficultyCategoryPickDamage)
	})

	pickDamageCategory:createSlider({
		label = translations.get(translationKeys.mcmDifficultyLabelBaseRate),
		description = translations.get(translationKeys.mcmDifficultyDescBaseRate),
		min = 0.1,
		max = 5.0,
		step = 0.1,
		jump = 0.5,
		decimalPlaces = 1,
		variable = mwse.mcm.createTableVariable({
			id = "baseRate",
			table = settings.mcm.difficulty,
		}),
	})

	local gradientCategory = page:createCategory({
		label = translations.get(translationKeys
			.mcmDifficultyCategoryGradient)
	})

	gradientCategory:createSlider({
		label = translations.get(translationKeys.mcmDifficultyLabelGradientFactor),
		description = translations.get(translationKeys.mcmDifficultyDescGradientFactor),
		min = 0.0,
		max = 10.0,
		step = 0.1,
		jump = 0.5,
		decimalPlaces = 1,
		variable = mwse.mcm.createTableVariable({
			id = "gradientFactor",
			table = settings.mcm.difficulty,
		}),
	})

	gradientCategory:createButton({
		label = translations.get(translationKeys.mcmDifficultyLabelResetToDefaults),
		description = translations.get(translationKeys.mcmDifficultyDescResetToDefaults),
		callback = function ()
			local defaults = settings.defaults.difficulty
			for k, v in pairs(defaults) do
				settings.mcm.difficulty[k] = v
			end
			settings.save()
			event.trigger(services.enums.events.settingsUpdated)
		end,
	})
end

return this
