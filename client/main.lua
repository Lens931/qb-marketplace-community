local QBCore = exports['qb-core']:GetCoreObject()
local isOpen = false

local function locale(key)
    local lang = Config.Locales[Config.Locale] or Config.Locales.en or {}
    return lang[key] or key
end

local function notify(message, notifyType)
    QBCore.Functions.Notify(message, notifyType or 'primary')
end

local function closeMarketplace()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMarketplace()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        config = {
            title = Config.MenuTitle,
            itemImagesPath = Config.ItemImagesPath,
            showSellerName = Config.ShowSellerName,
            allowBuyOwnOffers = Config.AllowBuyOwnOffers,
            minPrice = Config.MinPrice,
            maxPrice = Config.MaxPrice,
            maxQuantity = Config.MaxQuantityPerListing,
            locale = Config.Locale,
        }
    })
end

RegisterCommand(Config.Command, openMarketplace, false)

if Config.EnableKeybind then
    RegisterKeyMapping(Config.Command, ('Open %s'):format(Config.MenuTitle), 'keyboard', Config.Keybind)
end

RegisterNetEvent('qb-marketplace:client:open', openMarketplace)
RegisterNetEvent('qb-marketplace:client:close', closeMarketplace)

RegisterNetEvent('qb-marketplace:client:refresh', function()
    if isOpen then
        SendNUIMessage({ action = 'refresh' })
    end
end)

RegisterNetEvent('qb-marketplace:client:notify', function(message, notifyType)
    notify(message, notifyType)
    if isOpen then
        SendNUIMessage({ action = 'toast', message = message, toastType = notifyType or 'primary' })
    end
end)

RegisterNUICallback('close', function(_, cb)
    closeMarketplace()
    cb({ ok = true })
end)

local function nuiCallback(name)
    RegisterNUICallback(name, function(data, cb)
        QBCore.Functions.TriggerCallback(('qb-marketplace:server:%s'):format(name), function(response)
            cb(response or { ok = false, message = locale('offer_unavailable') })
        end, data or {})
    end)
end

nuiCallback('getInitialData')
nuiCallback('createListings')
nuiCallback('buyOffer')
nuiCallback('cancelOffer')
nuiCallback('withdrawEarnings')
nuiCallback('getOffers')
nuiCallback('getMyOffers')
nuiCallback('getSalesHistory')

RegisterNUICallback('refreshOffers', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-marketplace:server:getOffers', function(response) cb(response) end, data or {})
end)

RegisterNUICallback('refreshMyOffers', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-marketplace:server:getMyOffers', function(response) cb(response) end, data or {})
end)

RegisterNUICallback('refreshHistory', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-marketplace:server:getSalesHistory', function(response) cb(response) end, data or {})
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
