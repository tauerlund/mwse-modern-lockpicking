local EVENTS = require("tauer.modern-lockpicking.services.events.enums.EVENTS")
local TRANSLATION_KEY = require("tauer.modern-lockpicking.services.translations.enums.TRANSLATION_KEY")

---@class difficultyPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
---@param services serviceCollection
function this.initialize(template, services)
	local translations = services.translations
	local settings = services.mcmSettings

	local page = template:createSideBarPage({
		label = translations.get(TRANSLATION_KEY.mcmHeaderDifficulty)
	})

	local sweetSpotCategory = page:createCategory({
		label = translations.get(TRANSLATION_KEY
			.mcmDifficultyCategorySweetSpot)
	})

	sweetSpotCategory:createSlider({
		label = translations.get(TRANSLATION_KEY.mcmDifficultyLabelSecurityFactor),
		description = translations.get(TRANSLATION_KEY.mcmDifficultyDescSecurityFactor),
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
		label = translations.get(TRANSLATION_KEY.mcmDifficultyLabelLockLevelFactor),
		description = translations.get(TRANSLATION_KEY.mcmDifficultyDescLockLevelFactor),
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
		label = translations.get(TRANSLATION_KEY.mcmDifficultyLabelQualityFactor),
		description = translations.get(TRANSLATION_KEY.mcmDifficultyDescQualityFactor),
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
		label = translations.get(TRANSLATION_KEY.mcmDifficultyLabelMaxRadius),
		description = translations.get(TRANSLATION_KEY.mcmDifficultyDescMaxRadius),
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
		label = translations.get(TRANSLATION_KEY
			.mcmDifficultyCategoryPickDamage)
	})

	pickDamageCategory:createSlider({
		label = translations.get(TRANSLATION_KEY.mcmDifficultyLabelBaseRate),
		description = translations.get(TRANSLATION_KEY.mcmDifficultyDescBaseRate),
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
		label = translations.get(TRANSLATION_KEY
			.mcmDifficultyCategoryGradient)
	})

	gradientCategory:createSlider({
		label = translations.get(TRANSLATION_KEY.mcmDifficultyLabelGradientFactor),
		description = translations.get(TRANSLATION_KEY.mcmDifficultyDescGradientFactor),
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
		label = translations.get(TRANSLATION_KEY.mcmDifficultyLabelResetToDefaults),
		description = translations.get(TRANSLATION_KEY.mcmDifficultyDescResetToDefaults),
		callback = function ()
			local defaults = settings.defaults.difficulty
			for k, v in pairs(defaults) do
				settings.mcm.difficulty[k] = v
			end
			settings.save()
			event.trigger(EVENTS.settingsUpdated)
		end,
	})
end

return this
