local QBCore = exports['qb-core']:GetCoreObject()
local isOpen = false

local function getPublicConfig()
    return {
        locale = Config.Locale,
        title = Config.UI.title,
        subtitle = Config.UI.subtitle,
        theme = Config.UI.theme,
        currency = Config.UI.currency,
        showSeller = Config.UI.showSeller,
        allowOwnPurchase = Config.AllowOwnPurchase,
        tax = Config.Taxes,
        expiration = Config.Expiration,
        limits = {
            price = Config.PriceLimits,
            quantity = Config.QuantityLimits
        },
        imagePath = Config.Inventory.imagePath,
        fallbackImage = Config.Inventory.fallbackImage,
        badges = Config.ItemBadges,
        categoryLabels = Config.CategoryLabels,
        rarityLabels = Config.RarityLabels,
        accounts = Config.Accounts
    }
end

local function setNuiOpen(state)
    isOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function notify(message, notifyType)
    if isOpen then
        SendNUIMessage({
            action = 'toast',
            message = message,
            toastType = notifyType or 'info'
        })
    else
        QBCore.Functions.Notify(message, notifyType or 'primary')
    end
end

local function requestData(callback)
    QBCore.Functions.TriggerCallback('qb-marketplace:server:getData', function(result)
        callback(result or { success = false, message = Lang('error_server') })
    end)
end

local function openMarketplace()
    if isOpen then return end

    requestData(function(result)
        if not result.success then
            notify(result.message or Lang('error_server'), 'error')
            return
        end

        setNuiOpen(true)
        SendNUIMessage({
            action = 'open',
            config = getPublicConfig(),
            data = result.data
        })
    end)
end

RegisterCommand(Config.OpenCommand, openMarketplace, false)

if Config.Keybind.enabled then
    RegisterKeyMapping(
        Config.OpenCommand,
        Config.Keybind.description or 'Open marketplace',
        'keyboard',
        Config.Keybind.key or 'F6'
    )
end

RegisterNetEvent('qb-marketplace:client:open', openMarketplace)

RegisterNetEvent('qb-marketplace:client:notify', function(message, notifyType)
    notify(message, notifyType)
end)

RegisterNUICallback('close', function(_, cb)
    setNuiOpen(false)
    SendNUIMessage({ action = 'close' })
    cb({ success = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    requestData(cb)
end)

RegisterNUICallback('createListing', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-marketplace:server:createListing', function(result)
        cb(result or { success = false, message = Lang('error_server') })
    end, data)
end)

RegisterNUICallback('buyListing', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-marketplace:server:buyListing', function(result)
        cb(result or { success = false, message = Lang('error_server') })
    end, data)
end)

RegisterNUICallback('cancelListing', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-marketplace:server:cancelListing', function(result)
        cb(result or { success = false, message = Lang('error_server') })
    end, data)
end)

RegisterNUICallback('withdrawEarnings', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-marketplace:server:withdrawEarnings', function(result)
        cb(result or { success = false, message = Lang('error_server') })
    end, data)
end)
