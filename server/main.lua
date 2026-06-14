local QBCore = exports['qb-core']:GetCoreObject()

local playerLocks = {}
local rateLimits = {}
local listingLocks = {}

local function now()
    return os.time()
end

local function toInt(value)
    local number = tonumber(value)
    if not number then return nil end
    return math.floor(number)
end

local function validItemName(itemName)
    if type(itemName) ~= 'string' then return nil end
    itemName = itemName:lower()
    if not itemName:match('^[%w_%-]+$') then return nil end
    return itemName
end

local function trim(value)
    return (value or ''):gsub('^%s*(.-)%s*$', '%1')
end

local function playerName(Player)
    local charinfo = Player.PlayerData.charinfo or {}
    local fullName = trim((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''))
    return fullName ~= '' and fullName or GetPlayerName(Player.PlayerData.source)
end

local function formatMoney(amount)
    return ('%s%s'):format(Config.UI.currency or '$', amount)
end

local function getBadge(itemName)
    local badge = Config.ItemBadges[itemName] or {}
    return {
        category = badge.category or 'misc',
        rarity = badge.rarity or 'common'
    }
end

local function getItemLabel(itemName)
    local shared = QBCore.Shared.Items[itemName]
    return shared and shared.label or itemName
end

local function getItemImage(itemName)
    if Config.Inventory.imagePath and Config.Inventory.imagePath ~= '' then
        return Config.Inventory.imagePath:format(itemName)
    end

    return Config.Inventory.fallbackImage or ''
end

local function taxAmount(amount)
    if not Config.Taxes.enabled then return 0 end

    local raw = amount * ((Config.Taxes.percentage or 0) / 100)
    if Config.Taxes.round == 'ceil' then return math.ceil(raw) end
    if Config.Taxes.round == 'nearest' then return math.floor(raw + 0.5) end
    return math.floor(raw)
end

local function isAdmin(source)
    return source == 0 or QBCore.Functions.HasPermission(source, Config.Admin.permission or 'admin')
end

local function rateLimited(source, action)
    local interval = Config.RateLimit[action] or 1000
    local key = ('%s:%s'):format(source, action)
    local current = GetGameTimer()

    if rateLimits[key] and current - rateLimits[key] < interval then
        return true
    end

    rateLimits[key] = current
    return false
end

local function guarded(source, action, cb, handler)
    if rateLimited(source, action) then
        cb({ success = false, message = Lang('error_rate_limited') })
        return
    end

    local key = ('%s:%s'):format(source, action)
    if playerLocks[key] then
        cb({ success = false, message = Lang('error_busy') })
        return
    end

    playerLocks[key] = true
    local ok, result = pcall(handler)
    playerLocks[key] = nil

    if not ok then
        listingLocks = {}
        print(('[qb-marketplace] %s failed: %s'):format(action, result))
        cb({ success = false, message = Lang('error_server') })
        return
    end

    cb(result)
end

local function sendDiscordLog(title, fields)
    if not Config.Logs.enabled or not Config.Logs.webhook or Config.Logs.webhook == '' then
        return
    end

    local embedFields = {}
    for key, value in pairs(fields or {}) do
        embedFields[#embedFields + 1] = {
            name = key,
            value = tostring(value),
            inline = true
        }
    end

    PerformHttpRequest(Config.Logs.webhook, function() end, 'POST', json.encode({
        username = Config.Logs.username or 'QB Marketplace',
        embeds = {{
            title = title,
            color = Config.Logs.color or 5793266,
            fields = embedFields,
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') }
        }}
    }), { ['Content-Type'] = 'application/json' })
end

local function expireListings()
    if not Config.Expiration.enabled then return 0 end

    return MySQL.update.await([[
        UPDATE marketplace_listings
        SET status = 'expired', updated_at = NOW()
        WHERE status = 'active' AND expires_at IS NOT NULL AND expires_at <= NOW()
    ]]) or 0
end

local function deleteOldClosedListings()
    local days = tonumber(Config.Expiration.deleteClosedAfterDays)
    if not days or days <= 0 then return 0 end

    local cutoff = os.date('%Y-%m-%d %H:%M:%S', now() - (math.floor(days) * 86400))

    return MySQL.update.await([[
        DELETE FROM marketplace_listings
        WHERE status = 'cancelled'
        AND updated_at < ?
    ]], { cutoff }) or 0
end

local function sanitizeListing(row)
    if not row then return nil end

    row.price = tonumber(row.price) or 0
    row.quantity = tonumber(row.quantity) or 0
    row.id = tonumber(row.id)
    row.seller = Config.UI.showSeller and row.seller_name or nil
    row.seller_name = nil
    return row
end

local function fetchOffers()
    local rows = MySQL.query.await([[
        SELECT id, seller_citizenid, seller_name, item_name, item_label, item_image,
               quantity, price, rarity, category, expires_at, created_at
        FROM marketplace_listings
        WHERE status = 'active'
        ORDER BY created_at DESC
        LIMIT ?
    ]], { Config.UI.maxOffers or 250 }) or {}

    for index, row in ipairs(rows) do
        rows[index] = sanitizeListing(row)
    end

    return rows
end

local function fetchMyListings(citizenid)
    local rows = MySQL.query.await([[
        SELECT id, item_name, item_label, item_image, quantity, price, rarity, category,
               status, expires_at, created_at
        FROM marketplace_listings
        WHERE seller_citizenid = ? AND status IN ('active', 'expired')
        ORDER BY created_at DESC
    ]], { citizenid }) or {}

    for index, row in ipairs(rows) do
        rows[index] = sanitizeListing(row)
    end

    return rows
end

local function fetchHistory(citizenid)
    local rows = MySQL.query.await([[
        SELECT id, listing_id, item_name, item_label, quantity, unit_price, gross_amount,
               tax_amount, net_amount, buyer_name, withdrawn, created_at, withdrawn_at
        FROM marketplace_sales
        WHERE seller_citizenid = ?
        ORDER BY created_at DESC
        LIMIT ?
    ]], { citizenid, Config.UI.maxHistory or 100 }) or {}

    local pending = 0
    for _, row in ipairs(rows) do
        row.id = tonumber(row.id)
        row.quantity = tonumber(row.quantity) or 0
        row.unit_price = tonumber(row.unit_price) or 0
        row.gross_amount = tonumber(row.gross_amount) or 0
        row.tax_amount = tonumber(row.tax_amount) or 0
        row.net_amount = tonumber(row.net_amount) or 0
        row.withdrawn = row.withdrawn == 1 or row.withdrawn == true

        if not row.withdrawn then
            pending = pending + row.net_amount
        end
    end

    return rows, pending
end

local function getInventory(Player)
    local inventory = Player.PlayerData.items or {}
    local aggregated = {}

    for _, item in pairs(inventory) do
        if item and item.name and item.amount and item.amount > 0 then
            local itemName = validItemName(item.name)

            if itemName and not Config.BlacklistItems[itemName] then
                local badge = getBadge(itemName)
                local existing = aggregated[itemName]

                if existing then
                    existing.amount = existing.amount + item.amount
                else
                    aggregated[itemName] = {
                        name = itemName,
                        label = item.label or getItemLabel(itemName),
                        amount = item.amount,
                        image = getItemImage(itemName),
                        rarity = badge.rarity,
                        category = badge.category
                    }
                end
            end
        end
    end

    local items = {}
    for _, item in pairs(aggregated) do
        items[#items + 1] = item
    end

    table.sort(items, function(a, b)
        return a.label:lower() < b.label:lower()
    end)

    return items
end

local function buildData(Player)
    if Config.Expiration.cleanupOnOpen then
        expireListings()
    end

    local citizenid = Player.PlayerData.citizenid
    local history, pending = fetchHistory(citizenid)
    local offers = fetchOffers()
    local myListings = fetchMyListings(citizenid)

    return {
        inventory = getInventory(Player),
        offers = offers,
        myListings = myListings,
        history = history,
        stats = {
            offers = #offers,
            myListings = #myListings,
            pendingEarnings = pending,
            taxPercent = Config.Taxes.enabled and Config.Taxes.percentage or 0
        }
    }
end

local function refreshed(Player, message)
    return {
        success = true,
        message = message,
        data = buildData(Player)
    }
end

QBCore.Functions.CreateCallback('qb-marketplace:server:getData', function(source, cb)
    guarded(source, 'refresh', cb, function()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return { success = false, message = Lang('error_player') } end

        return {
            success = true,
            data = buildData(Player)
        }
    end)
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:createListing', function(source, cb, data)
    guarded(source, 'create', cb, function()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return { success = false, message = Lang('error_player') } end

        local itemName = validItemName(data and data.itemName)
        local quantity = toInt(data and data.quantity)
        local price = toInt(data and data.price)

        if not itemName or not QBCore.Shared.Items[itemName] then
            return { success = false, message = Lang('error_invalid_item') }
        end

        if Config.BlacklistItems[itemName] then
            return { success = false, message = Lang('error_item_blacklisted') }
        end

        if not quantity or quantity < Config.QuantityLimits.min or quantity > Config.QuantityLimits.max then
            return { success = false, message = Lang('error_invalid_quantity') }
        end

        if not price or price < Config.PriceLimits.min or price > Config.PriceLimits.max then
            return { success = false, message = Lang('error_invalid_price') }
        end

        local item = Player.Functions.GetItemByName(itemName)
        if not item or (item.amount or 0) < quantity then
            return { success = false, message = Lang('error_item_missing') }
        end

        local removed = Player.Functions.RemoveItem(itemName, quantity)
        if not removed then
            return { success = false, message = Lang('error_item_missing') }
        end

        local badge = getBadge(itemName)
        local expiresAt = nil
        if Config.Expiration.enabled then
            expiresAt = os.date('%Y-%m-%d %H:%M:%S', now() + ((Config.Expiration.hours or 72) * 3600))
        end

        local insertId = MySQL.insert.await([[
            INSERT INTO marketplace_listings
                (seller_citizenid, seller_name, item_name, item_label, item_image,
                 quantity, price, rarity, category, expires_at, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')
        ]], {
            Player.PlayerData.citizenid,
            playerName(Player),
            itemName,
            getItemLabel(itemName),
            getItemImage(itemName),
            quantity,
            price,
            badge.rarity,
            badge.category,
            expiresAt
        })

        if not insertId then
            Player.Functions.AddItem(itemName, quantity)
            return { success = false, message = Lang('error_server') }
        end

        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'remove', quantity)
        sendDiscordLog(Lang('log_listing_created'), {
            Seller = playerName(Player),
            Item = itemName,
            Quantity = quantity,
            Price = formatMoney(price)
        })

        return refreshed(Player, Lang('success_listing_created'))
    end)
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:buyListing', function(source, cb, data)
    guarded(source, 'buy', cb, function()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return { success = false, message = Lang('error_player') } end

        local listingId = toInt(data and data.listingId)
        local quantity = toInt(data and data.quantity)

        if not listingId or not quantity or quantity < Config.QuantityLimits.min or quantity > Config.QuantityLimits.max then
            return { success = false, message = Lang('error_invalid_quantity') }
        end

        if listingLocks[listingId] then
            return { success = false, message = Lang('error_busy') }
        end

        listingLocks[listingId] = true
        expireListings()

        local listing = MySQL.single.await([[
            SELECT *
            FROM marketplace_listings
            WHERE id = ? AND status = 'active'
            LIMIT 1
        ]], { listingId })

        if not listing or (tonumber(listing.quantity) or 0) < quantity then
            listingLocks[listingId] = nil
            return { success = false, message = Lang('error_listing_missing') }
        end

        if not Config.AllowOwnPurchase and listing.seller_citizenid == Player.PlayerData.citizenid then
            listingLocks[listingId] = nil
            return { success = false, message = Lang('error_own_purchase') }
        end

        local unitPrice = tonumber(listing.price) or 0
        local gross = unitPrice * quantity
        local account = Config.Accounts.buyerPayment or 'bank'
        local money = Player.PlayerData.money and Player.PlayerData.money[account] or 0

        if gross <= 0 or money < gross then
            listingLocks[listingId] = nil
            return { success = false, message = Lang('error_not_enough_money') }
        end

        local paid = Player.Functions.RemoveMoney(account, gross, 'qb-marketplace-purchase')
        if not paid then
            listingLocks[listingId] = nil
            return { success = false, message = Lang('error_not_enough_money') }
        end

        local added = Player.Functions.AddItem(listing.item_name, quantity)
        if not added then
            Player.Functions.AddMoney(account, gross, 'qb-marketplace-refund')
            listingLocks[listingId] = nil
            return { success = false, message = Lang('error_inventory_full') }
        end

        local remaining = (tonumber(listing.quantity) or 0) - quantity
        local status = remaining <= 0 and 'sold' or 'active'
        local tax = taxAmount(gross)
        local net = gross - tax

        local ok = MySQL.transaction.await({
            {
                query = [[
                    UPDATE marketplace_listings
                    SET quantity = ?, status = ?, updated_at = NOW()
                    WHERE id = ? AND status = 'active'
                ]],
                values = { remaining, status, listingId }
            },
            {
                query = [[
                    INSERT INTO marketplace_sales
                        (listing_id, seller_citizenid, buyer_citizenid, item_name, item_label,
                         quantity, unit_price, gross_amount, tax_amount, net_amount,
                         seller_name, buyer_name)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ]],
                values = {
                    listingId,
                    listing.seller_citizenid,
                    Player.PlayerData.citizenid,
                    listing.item_name,
                    listing.item_label,
                    quantity,
                    unitPrice,
                    gross,
                    tax,
                    net,
                    listing.seller_name,
                    playerName(Player)
                }
            }
        })

        listingLocks[listingId] = nil

        if not ok then
            Player.Functions.RemoveItem(listing.item_name, quantity)
            Player.Functions.AddMoney(account, gross, 'qb-marketplace-refund')
            return { success = false, message = Lang('error_server') }
        end

        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[listing.item_name], 'add', quantity)
        sendDiscordLog(Lang('log_purchase'), {
            Buyer = playerName(Player),
            Seller = listing.seller_name,
            Item = listing.item_name,
            Quantity = quantity,
            Gross = formatMoney(gross),
            Tax = formatMoney(tax),
            Net = formatMoney(net)
        })

        return refreshed(Player, Lang('success_purchase'))
    end)
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:cancelListing', function(source, cb, data)
    guarded(source, 'cancel', cb, function()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return { success = false, message = Lang('error_player') } end

        local listingId = toInt(data and data.listingId)
        if not listingId then return { success = false, message = Lang('error_listing_missing') } end

        if listingLocks[listingId] then
            return { success = false, message = Lang('error_busy') }
        end

        listingLocks[listingId] = true
        expireListings()

        local listing = MySQL.single.await([[
            SELECT *
            FROM marketplace_listings
            WHERE id = ? AND status IN ('active', 'expired')
            LIMIT 1
        ]], { listingId })

        if not listing then
            listingLocks[listingId] = nil
            return { success = false, message = Lang('error_listing_missing') }
        end

        if listing.seller_citizenid ~= Player.PlayerData.citizenid then
            listingLocks[listingId] = nil
            return { success = false, message = Lang('error_not_owner') }
        end

        local quantity = tonumber(listing.quantity) or 0
        local returned = Player.Functions.AddItem(listing.item_name, quantity)
        if not returned then
            listingLocks[listingId] = nil
            return { success = false, message = Lang('error_inventory_full') }
        end

        local updated = MySQL.update.await([[
            UPDATE marketplace_listings
            SET status = 'cancelled', updated_at = NOW()
            WHERE id = ? AND seller_citizenid = ? AND status IN ('active', 'expired')
        ]], { listingId, Player.PlayerData.citizenid })

        listingLocks[listingId] = nil

        if not updated or updated < 1 then
            Player.Functions.RemoveItem(listing.item_name, quantity)
            return { success = false, message = Lang('error_server') }
        end

        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[listing.item_name], 'add', quantity)
        sendDiscordLog(Lang('log_listing_cancelled'), {
            Seller = playerName(Player),
            Item = listing.item_name,
            Quantity = quantity
        })

        return refreshed(Player, Lang('success_listing_cancelled'))
    end)
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:withdrawEarnings', function(source, cb, data)
    guarded(source, 'withdraw', cb, function()
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return { success = false, message = Lang('error_player') } end

        local ids = {}
        if data and type(data.ids) == 'table' then
            for _, id in ipairs(data.ids) do
                local numeric = toInt(id)
                if numeric then ids[#ids + 1] = numeric end
            end
        end

        local query = [[
            SELECT id, net_amount
            FROM marketplace_sales
            WHERE seller_citizenid = ? AND withdrawn = 0
        ]]
        local params = { Player.PlayerData.citizenid }

        if #ids > 0 then
            local placeholders = {}
            for _, id in ipairs(ids) do
                placeholders[#placeholders + 1] = '?'
                params[#params + 1] = id
            end
            query = query .. (' AND id IN (%s)'):format(table.concat(placeholders, ','))
        end

        local rows = MySQL.query.await(query, params) or {}
        if #rows == 0 then
            return { success = false, message = Lang('error_no_earnings') }
        end

        local total = 0
        local transaction = {}
        for _, row in ipairs(rows) do
            total = total + (tonumber(row.net_amount) or 0)
            transaction[#transaction + 1] = {
                query = [[
                    UPDATE marketplace_sales
                    SET withdrawn = 1, withdrawn_at = NOW()
                    WHERE id = ? AND seller_citizenid = ? AND withdrawn = 0
                ]],
                values = { row.id, Player.PlayerData.citizenid }
            }
        end

        if total <= 0 then
            return { success = false, message = Lang('error_no_earnings') }
        end

        local ok = MySQL.transaction.await(transaction)
        if not ok then
            return { success = false, message = Lang('error_server') }
        end

        Player.Functions.AddMoney(Config.Accounts.sellerPayout or 'bank', total, 'qb-marketplace-withdraw')
        sendDiscordLog(Lang('log_withdraw'), {
            Seller = playerName(Player),
            Amount = formatMoney(total),
            Sales = #rows
        })

        return refreshed(Player, Lang('success_withdraw', { amount = formatMoney(total) }))
    end)
end)

RegisterCommand(Config.Admin.cleanupCommand, function(source)
    if not isAdmin(source) then return end

    local expired = expireListings()
    local deleted = deleteOldClosedListings()
    local message = Lang('admin_cleanup_done', { expired = expired, deleted = deleted })

    if source == 0 then
        print(('[qb-marketplace] %s'):format(message))
    else
        TriggerClientEvent('qb-marketplace:client:notify', source, message, 'success')
    end
end, false)

local function scheduleCleanup()
    if not Config.Expiration.serverCleanup then return end

    local interval = math.max(5, tonumber(Config.Expiration.cleanupIntervalMinutes) or 60) * 60000
    SetTimeout(interval, function()
        expireListings()
        deleteOldClosedListings()
        scheduleCleanup()
    end)
end

CreateThread(function()
    Wait(2000)
    scheduleCleanup()
end)
