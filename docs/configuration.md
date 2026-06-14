# Configuration

All runtime options live in `config.lua`.

- `Config.MenuTitle`: displayed NUI title.
- `Config.Command`: command name, default `marketplace`.
- `Config.EnableKeybind` / `Config.Keybind`: optional key mapping.
- `Config.PayoutAccount`: seller payout account, usually `cash` or `bank`.
- `Config.PurchaseAccount`: buyer payment account.
- `Config.MinPrice` / `Config.MaxPrice`: server-enforced price range.
- `Config.MaxQuantityPerListing`: server-enforced quantity cap.
- `Config.MaxActiveListingsPerPlayer`: active listing cap.
- `Config.AllowBuyOwnOffers`: controls self-purchases.
- `Config.ShowSellerName`: stores and shows seller display names when enabled.
- `Config.EnableExpiration` / `Config.DefaultExpirationHours`: listing expiration.
- `Config.BlacklistedItems`: item names that cannot be listed.
- `Config.ItemImagesPath`: NUI image base path.
