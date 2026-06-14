Locales = Locales or {}

local function replaceParams(message, params)
    if not params then return message end

    for key, value in pairs(params) do
        message = message:gsub('{' .. key .. '}', tostring(value))
    end

    return message
end

function Lang(key, params)
    local locale = (Config and Config.Locale) or 'en'
    local dictionary = Locales[locale] or Locales.en or {}
    local message = dictionary[key] or key

    return replaceParams(message, params)
end
