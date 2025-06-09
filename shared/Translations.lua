---@class Translations
local this = {}

---@public
---@param key string
function this.Get(key)
	return mwse.loadTranslations("tauer.modern-lockpicking")(key)
end

return this
