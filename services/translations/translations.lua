---@class translations
local this = {}

---@public
---@param key translationKeys
function this.get(key)
	return mwse.loadTranslations("tauer.modern-lockpicking")(key)
end

return this
