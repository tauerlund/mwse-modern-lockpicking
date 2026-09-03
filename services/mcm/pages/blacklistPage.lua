---@class blacklistPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
---@param services serviceCollection
function this.initialize(template, services)
	local settings = services.settings

	local translations = services.translations
	local translationKeys = services.enums.translationKeys

	template:createExclusionsPage({
		label = translations.get(translationKeys.mcmHeaderBlacklist),
		description = translations.get(translationKeys.mcmBlacklistDesc),
		leftListLabel = translations.get(translationKeys.mcmBlacklistLabelIgnored),
		rightListLabel = translations.get(translationKeys.mcmBlacklistLabelUsed),
		showAllBlocked = true,
		filters = {
			{
				label = translations.get(translationKeys.mcmBlacklistFilterLockpicks),
				type = "Object",
				objectType = tes3.objectType.lockpick,
			},
		},
		variable = mwse.mcm.createTableVariable({
			id = "pickBlacklist",
			table = settings,
		}),
	})
end

return this
