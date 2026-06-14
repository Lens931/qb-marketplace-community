local QBCore = exports['qb-core']:GetCoreObject()
local rateBuckets, locks = {}, {}

local function t(key) local l=Config.Locales[Config.Locale] or Config.Locales.en or {}; return l[key] or key end
local function player(src) return QBCore.Functions.GetPlayer(src) end
local function cid(p) return p and p.PlayerData and p.PlayerData.citizenid end
local function pname(p) local c=p.PlayerData.charinfo or {}; return (('%s %s'):format(c.firstname or '', c.lastname or '')):gsub('^%s*(.-)%s*$', '%1') end
local function isBlacklisted(item) return Config.BlacklistedItems[string.lower(tostring(item or ''))] == true end
local function validInt(v) v=tonumber(v); if not v then return nil end; v=math.floor(v); if v < 1 then return nil end; return v end
local function itemDef(name) return QBCore.Shared.Items[name] or QBCore.Shared.Items[string.lower(name or '')] end
local function itemLabel(name) local d=itemDef(name); return d and d.label or name end
local function itemWeight(name) local d=itemDef(name); return d and d.weight or 0 end
local function imageFor(name) local d=itemDef(name); return d and d.image or (name .. '.png') end

local function logDiscord(title, description)
    if not Config.EnableDiscordLogs or Config.DiscordWebhook == '' then return end
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({ embeds={{ title=title, description=description, color=5793266 }} }), { ['Content-Type']='application/json' })
end

local function rateLimit(src, action)
    local cfg = Config.RateLimits[action]
    if not cfg then return true end
    local now = GetGameTimer()
    rateBuckets[src] = rateBuckets[src] or {}
    local bucket = rateBuckets[src][action] or { reset = now + cfg.interval, count = 0 }
    if now > bucket.reset then bucket = { reset = now + cfg.interval, count = 0 } end
    bucket.count = bucket.count + 1
    rateBuckets[src][action] = bucket
    return bucket.count <= cfg.max
end

AddEventHandler('playerDropped', function() rateBuckets[source] = nil end)

local function response(ok, message, data) return { ok = ok, message = message, data = data } end
local function notify(src, key, typ) TriggerClientEvent('qb-marketplace:client:notify', src, t(key), typ or (key:find('invalid') and 'error' or 'primary')) end

local function getInventoryItems(p)
    local out, items = {}, p.PlayerData.items or {}
    for _, it in pairs(items) do
        if it and it.name and (it.amount or 0) > 0 and not isBlacklisted(it.name) then
            out[#out+1] = { name=it.name, label=it.label or itemLabel(it.name), amount=it.amount, weight=it.weight or itemWeight(it.name), image=it.image or imageFor(it.name), metadata=it.info or it.metadata or {} }
        end
    end
    table.sort(out, function(a,b) return a.label < b.label end)
    return out
end

local function expirationSql()
    if not Config.EnableExpiration then return 'NULL' end
    return ('DATE_ADD(NOW(), INTERVAL %d HOUR)'):format(tonumber(Config.DefaultExpirationHours) or 168)
end

QBCore.Functions.CreateCallback('qb-marketplace:server:getInitialData', function(src, cb)
    local p=player(src); if not p then cb(response(false, 'no player')); return end
    local seller=cid(p)
    local offers = MySQL.query.await('SELECT * FROM marketplace_offers WHERE quantity > 0 AND (expires_at IS NULL OR expires_at > NOW()) ORDER BY created_at DESC LIMIT 120') or {}
    local my = MySQL.query.await('SELECT * FROM marketplace_offers WHERE seller_citizenid = ? AND quantity > 0 ORDER BY created_at DESC', { seller }) or {}
    local hist = MySQL.query.await('SELECT *, (SELECT COALESCE(SUM(total_price),0) FROM marketplace_sales WHERE seller_citizenid = ? AND withdrawn = 0) AS pending_total FROM marketplace_sales WHERE seller_citizenid = ? ORDER BY created_at DESC LIMIT 80', { seller, seller }) or {}
    cb(response(true, 'ok', { inventory=getInventoryItems(p), offers=offers, myOffers=my, sales=hist, pendingEarnings=(hist[1] and hist[1].pending_total or 0), citizenid=seller }))
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:getOffers', function(_, cb)
    cb(response(true, 'ok', MySQL.query.await('SELECT * FROM marketplace_offers WHERE quantity > 0 AND (expires_at IS NULL OR expires_at > NOW()) ORDER BY created_at DESC LIMIT 200') or {}))
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:getMyOffers', function(src, cb)
    local p=player(src); if not p then cb(response(false,'no player')); return end
    cb(response(true, 'ok', MySQL.query.await('SELECT * FROM marketplace_offers WHERE seller_citizenid = ? AND quantity > 0 ORDER BY created_at DESC', { cid(p) }) or {}))
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:getSalesHistory', function(src, cb)
    local p=player(src); if not p then cb(response(false,'no player')); return end
    local rows = MySQL.query.await('SELECT * FROM marketplace_sales WHERE seller_citizenid = ? ORDER BY created_at DESC LIMIT 100', { cid(p) }) or {}
    local pending = MySQL.scalar.await('SELECT COALESCE(SUM(total_price),0) FROM marketplace_sales WHERE seller_citizenid = ? AND withdrawn = 0', { cid(p) }) or 0
    cb(response(true, 'ok', { sales=rows, pendingEarnings=pending }))
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:createListings', function(src, cb, data)
    if not rateLimit(src, 'createListings') then cb(response(false, t('rate_limited'))); return end
    local p=player(src); if not p then cb(response(false,'no player')); return end
    local listings=data and data.listings or {}; if type(listings)~='table' or #listings < 1 then cb(response(false,t('invalid_quantity'))); return end
    local active = MySQL.scalar.await('SELECT COUNT(*) FROM marketplace_offers WHERE seller_citizenid = ? AND quantity > 0', { cid(p) }) or 0
    if active + #listings > Config.MaxActiveListingsPerPlayer then cb(response(false,'Max active listings reached')); return end
    for _, l in ipairs(listings) do
        l.name=tostring(l.name or ''):lower(); l.quantity=validInt(l.quantity); l.price=validInt(l.price)
        if l.name=='' or isBlacklisted(l.name) then cb(response(false,'Blacklisted item')); return end
        if not l.quantity or l.quantity > Config.MaxQuantityPerListing then cb(response(false,t('invalid_quantity'))); return end
        if not l.price or l.price < Config.MinPrice or l.price > Config.MaxPrice then cb(response(false,t('invalid_price'))); return end
        local it=p.Functions.GetItemByName(l.name); if not it or (it.amount or 0) < l.quantity then cb(response(false,t('inventory_error'))); return end
    end
    for _, l in ipairs(listings) do
        if not p.Functions.RemoveItem(l.name, l.quantity) then cb(response(false,t('inventory_error'))); return end
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[l.name], 'remove', l.quantity)
        MySQL.insert.await(('INSERT INTO marketplace_offers (seller_citizenid, seller_name, item_name, item_label, quantity, price, metadata, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, %s)'):format(expirationSql()), { cid(p), Config.ShowSellerName and pname(p) or nil, l.name, itemLabel(l.name), l.quantity, l.price, json.encode(l.metadata or {}) })
    end
    notify(src,'sale_created','success'); logDiscord('Marketplace listing', ('%s created %d listing(s)'):format(cid(p), #listings)); cb(response(true,t('sale_created')))
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:buyOffer', function(src, cb, data)
    if not rateLimit(src, 'buyOffer') then cb(response(false, t('rate_limited'))); return end
    local p=player(src); if not p then cb(response(false,'no player')); return end
    local offerId=validInt(data and data.offerId); local qty=validInt(data and data.quantity); if not offerId or not qty then cb(response(false,t('invalid_quantity'))); return end
    local lock='offer:'..offerId; if locks[lock] then cb(response(false,t('offer_unavailable'))); return end; locks[lock]=true
    local ok,msg=false,t('offer_unavailable')
    local offer = MySQL.single.await('SELECT * FROM marketplace_offers WHERE id = ? AND quantity >= ? AND (expires_at IS NULL OR expires_at > NOW())', { offerId, qty })
    if offer and (Config.AllowBuyOwnOffers or offer.seller_citizenid ~= cid(p)) then
        local total = offer.price * qty
        if p.PlayerData.money[Config.PurchaseAccount] and p.PlayerData.money[Config.PurchaseAccount] >= total then
            local changed = MySQL.update.await('UPDATE marketplace_offers SET quantity = quantity - ? WHERE id = ? AND quantity >= ?', { qty, offerId, qty })
            if changed and changed > 0 then
                if p.Functions.RemoveMoney(Config.PurchaseAccount, total, 'marketplace-purchase') then
                    if p.Functions.AddItem(offer.item_name, qty, false, json.decode(offer.metadata or '{}') or {}) then
                        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[offer.item_name], 'add', qty)
                        MySQL.insert.await('INSERT INTO marketplace_sales (offer_id, seller_citizenid, buyer_citizenid, item_name, item_label, quantity, unit_price, total_price) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', { offerId, offer.seller_citizenid, cid(p), offer.item_name, offer.item_label, qty, offer.price, total })
                        MySQL.update.await('DELETE FROM marketplace_offers WHERE id = ? AND quantity = 0', { offerId })
                        ok,msg=true,t('purchase_success')
                    else
                        p.Functions.AddMoney(Config.PurchaseAccount, total, 'marketplace-purchase-refund')
                        MySQL.update.await('UPDATE marketplace_offers SET quantity = quantity + ? WHERE id = ?', { qty, offerId })
                        msg=t('inventory_error')
                    end
                else
                    MySQL.update.await('UPDATE marketplace_offers SET quantity = quantity + ? WHERE id = ?', { qty, offerId })
                    msg=t('not_enough_money')
                end
            end
        else msg=t('not_enough_money') end
    elseif offer and offer.seller_citizenid == cid(p) then msg=t('own_offer_blocked') end
    locks[lock]=nil; if ok then notify(src,'purchase_success','success') end; cb(response(ok,msg))
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:cancelOffer', function(src, cb, data)
    if not rateLimit(src, 'cancelOffer') then cb(response(false, t('rate_limited'))); return end
    local p=player(src); local id=validInt(data and data.offerId); if not p or not id then cb(response(false,t('offer_unavailable'))); return end
    local lock='cancel:'..id; if locks[lock] then cb(response(false,t('offer_unavailable'))); return end; locks[lock]=true
    local offer=MySQL.single.await('SELECT * FROM marketplace_offers WHERE id = ? AND seller_citizenid = ?', { id, cid(p) })
    if not offer then locks[lock]=nil; cb(response(false,t('offer_unavailable'))); return end
    local del=MySQL.update.await('DELETE FROM marketplace_offers WHERE id = ? AND seller_citizenid = ?', { id, cid(p) })
    if del and del > 0 then p.Functions.AddItem(offer.item_name, offer.quantity, false, json.decode(offer.metadata or '{}') or {}); notify(src,'offer_cancelled','success'); locks[lock]=nil; cb(response(true,t('offer_cancelled'))); return end
    locks[lock]=nil; cb(response(false,t('offer_unavailable')))
end)

QBCore.Functions.CreateCallback('qb-marketplace:server:withdrawEarnings', function(src, cb)
    if not rateLimit(src, 'withdrawEarnings') then cb(response(false, t('rate_limited'))); return end
    local p=player(src); if not p then cb(response(false,'no player')); return end
    local amount=MySQL.scalar.await('SELECT COALESCE(SUM(total_price),0) FROM marketplace_sales WHERE seller_citizenid = ? AND withdrawn = 0', { cid(p) }) or 0
    amount=tonumber(amount) or 0; if amount < 1 then cb(response(false,'No earnings')); return end
    MySQL.update.await('UPDATE marketplace_sales SET withdrawn = 1, withdrawn_at = NOW() WHERE seller_citizenid = ? AND withdrawn = 0', { cid(p) })
    p.Functions.AddMoney(Config.PayoutAccount, amount, 'marketplace-payout')
    notify(src,'earnings_withdrawn','success'); cb(response(true,t('earnings_withdrawn'), { amount=amount }))
end)
