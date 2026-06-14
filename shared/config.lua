Config = {}

Config.Locale = 'fr'

Config.OpenCommand = 'marketplace'

Config.Keybind = {
    enabled = true,
    key = 'F6',
    description = 'Open marketplace'
}

Config.UI = {
    title = 'QB Marketplace',
    subtitle = 'Community exchange',
    theme = 'purple', -- dark, purple, blue
    currency = '$',
    showSeller = true,
    maxOffers = 250,
    maxHistory = 100
}

Config.Accounts = {
    buyerPayment = 'bank',
    sellerPayout = 'bank'
}

Config.Taxes = {
    enabled = true,
    percentage = 5,
    round = 'floor' -- floor, ceil, nearest
}

Config.Expiration = {
    enabled = true,
    hours = 72,
    cleanupOnOpen = true,
    serverCleanup = true,
    cleanupIntervalMinutes = 60,
    deleteClosedAfterDays = 30
}

Config.AllowOwnPurchase = false

Config.PriceLimits = {
    min = 1,
    max = 1000000
}

Config.QuantityLimits = {
    min = 1,
    max = 250
}

Config.RateLimit = {
    refresh = 600,
    create = 1500,
    buy = 1200,
    cancel = 1200,
    withdraw = 1500
}

Config.BlacklistItems = {
    money = true,
    cash = true,
    bank = true,
    black_money = true,
    markedbills = true
}

Config.Inventory = {
    resource = 'qb-inventory',
    imagePath = 'nui://qb-inventory/html/images/%s.png',
    fallbackImage = ''
}

Config.ItemBadges = {
    lockpick = { category = 'tools', rarity = 'common' },
    advancedlockpick = { category = 'tools', rarity = 'rare' },
    weapon_pistol = { category = 'weapons', rarity = 'epic' },
    radio = { category = 'electronics', rarity = 'uncommon' }
}

Config.RarityLabels = {
    common = 'Common',
    uncommon = 'Uncommon',
    rare = 'Rare',
    epic = 'Epic',
    legendary = 'Legendary'
}

Config.CategoryLabels = {
    misc = 'Misc',
    tools = 'Tools',
    weapons = 'Weapons',
    electronics = 'Electronics',
    food = 'Food',
    medical = 'Medical'
}

Config.Logs = {
    enabled = false,
    webhook = '',
    username = 'QB Marketplace',
    color = 5793266
}

Config.Admin = {
    cleanupCommand = 'marketplacecleanup',
    permission = 'admin'
}
