Config = {}

Config.ResourceName = "qb-marketplace-community"
Config.MenuTitle = "Marketplace"
Config.Command = "marketplace"
Config.EnableKeybind = false
Config.Keybind = "F4"

Config.Inventory = "qb"
Config.Mysql = "oxmysql"

Config.PayoutAccount = "cash"
Config.PurchaseAccount = "cash"

Config.MinPrice = 1
Config.MaxPrice = 100000000
Config.MaxQuantityPerListing = 1000
Config.MaxActiveListingsPerPlayer = 50

Config.AllowBuyOwnOffers = false
Config.ShowSellerName = false

Config.EnableExpiration = true
Config.DefaultExpirationHours = 168

Config.EnableDiscordLogs = false
Config.DiscordWebhook = ""

Config.BlacklistedItems = {
    weapon_pistol = true,
}

Config.ItemImagesPath = "nui://qb-inventory/html/images/"

Config.Locale = "fr"

Config.RateLimits = {
    createListings = { interval = 5000, max = 2 },
    buyOffer = { interval = 2500, max = 2 },
    cancelOffer = { interval = 2500, max = 2 },
    withdrawEarnings = { interval = 5000, max = 1 },
}

Config.Locales = {
    fr = {
        sale_created = "Vente créée",
        purchase_success = "Achat réussi",
        offer_cancelled = "Offre annulée",
        earnings_withdrawn = "Gains retirés",
        inventory_error = "Erreur inventaire",
        not_enough_money = "Argent insuffisant",
        offer_unavailable = "Offre indisponible",
        invalid_price = "Prix invalide",
        invalid_quantity = "Quantité invalide",
        rate_limited = "Veuillez patienter avant de réessayer",
        own_offer_blocked = "Vous ne pouvez pas acheter votre propre offre",
    },
    en = {
        sale_created = "Listing created",
        purchase_success = "Purchase completed",
        offer_cancelled = "Listing cancelled",
        earnings_withdrawn = "Earnings withdrawn",
        inventory_error = "Inventory error",
        not_enough_money = "Not enough money",
        offer_unavailable = "Offer unavailable",
        invalid_price = "Invalid price",
        invalid_quantity = "Invalid quantity",
        rate_limited = "Please wait before trying again",
        own_offer_blocked = "You cannot buy your own listing",
    }
}
