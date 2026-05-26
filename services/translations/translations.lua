---@class translations
local this = {}

---@public
---@param key TRANSLATION_KEY
function this.get(key)
	return mwse.loadTranslations("tauer.modern-lockpicking")(key)
end

return this
