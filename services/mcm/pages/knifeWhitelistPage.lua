---@class knifeWhitelistPage : mcmPage
local this = {}

---@private
---@param whitelist table<string, boolean>
---@return integer
function this.countSelected(whitelist)
	local count = 0
	for _, selected in pairs(whitelist) do
		if selected then
			count = count + 1
		end
	end
	return count
end

---@private
---@return string[]
function this.getShortBlades()
	local blades = {}

	for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
		---@cast weapon tes3weapon
		if weapon.type == tes3.weaponType.shortBladeOneHand then
			table.insert(blades, weapon.id:lower())
		end
	end

	table.sort(blades)
	return blades
end

---@private
---@param page mwseMCMExclusionsPage
---@param message string
function this.guardMinimumSelection(page, message)
	local baseToggle = page.toggle
	local baseToggleFiltered = page.toggleFiltered

	---@param e tes3uiEventData
	function page:toggle(e)
		local id = e.source.text
		if self.variable.value[id] and this.countSelected(self.variable.value) <= 1 then
			tes3.messageBox(message)
			return
		end
		baseToggle(self, e)
	end

	---@param listName mwseMCMExclusionsPageListId
	function page:toggleFiltered(listName)
		local snapshot = table.copy(self.variable.value)

		baseToggleFiltered(self, listName)

		if this.countSelected(self.variable.value) > 0 then
			return
		end

		self.variable.value = snapshot
		tes3.messageBox(message)

		self.elements.outerContainer.parent:destroyChildren()
		self:create(self.elements.outerContainer.parent)
	end
end

---@public
---@param template mwseMCMTemplate
---@param services serviceCollection
function this.initialize(template, services)
	local settings = services.settings
	local defaults = services.mcmSettings.defaults

	local translations = services.translations
	local translationKeys = services.enums.translationKeys

	local page = template:createExclusionsPage({
		label = translations.get(translationKeys.mcmHeaderKnives),
		description = translations.get(translationKeys.mcmKnivesDesc),
		leftListLabel = translations.get(translationKeys.mcmKnivesLabelUsed),
		rightListLabel = translations.get(translationKeys.mcmKnivesLabelIgnored),
		showAllBlocked = true,
		filters = {
			{
				label = translations.get(translationKeys.mcmKnivesFilterShortBlades),
				callback = this.getShortBlades,
			},
		},
		variable = mwse.mcm.createTableVariable({
			id = "knifeWhitelist",
			table = settings,
			defaultSetting = table.copy(defaults.knifeWhitelist),
		}),
	})

	this.guardMinimumSelection(page, translations.get(translationKeys.mcmKnivesMinimumSelection))
end

return this
