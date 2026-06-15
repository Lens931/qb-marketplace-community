# qb-marketplace-community

![FiveM](https://img.shields.io/badge/FiveM-QBCore-54b9ff?style=for-the-badge)
![Inventory](https://img.shields.io/badge/Inventory-qb--inventory-9a7cff?style=for-the-badge)
![Database](https://img.shields.io/badge/Database-oxmysql-7ef0b2?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-ffd166?style=for-the-badge)

A clean open-source marketplace resource for FiveM servers using QBCore.

`qb-marketplace-community` lets players list items, browse offers, buy from other players, manage their own listings, and withdraw sale earnings through a simple in-game NUI.

The resource is built to stay readable, configurable, and easy to extend.

![Marketplace preview](docs/screenshots/marketplace-preview.png)

## Features

### Player Marketplace

* List inventory items for sale.
* Browse active offers.
* Search and filter listings.
* Sort offers by price or date.
* Buy full or partial quantities.
* Cancel your own listings.
* Recover remaining items from cancelled listings.
* View sales history.
* Withdraw completed sale earnings.
* Optional seller name display.

### Interface

* Transparent in-game NUI.
* Responsive layout for 1080p and 1440p.
* Item cards with category and rarity badges.
* Confirmations, loading states, empty states and notifications.
* Built-in themes:

  * `purple`
  * `blue`
  * `dark`

### Economy Configuration

* Configurable currency symbol.
* Buyer account: `cash` or `bank`.
* Seller payout account.
* Optional marketplace tax.
* Price and quantity limits.
* Listing expiration.
* Item blacklist.
* Option to prevent players from buying their own listings.

### Admin / Server

* Discord logs for:

  * listing creation
  * purchases
  * cancellations
  * withdrawals
* Cleanup command for expired listings.
* SQL indexes for common marketplace queries.
* oxmysql transactions for sensitive actions.
* No permanent client loop.

## Requirements

* `qb-core`
* `qb-inventory`
* `oxmysql`

## Installation

1. Place the resource in your server resources folder:

```text
resources/[qb]/qb-marketplace-community
```

2. Import the SQL file:

```sql
source sql/install.sql;
```

3. Add the resource to your server config:

```cfg
ensure oxmysql
ensure qb-core
ensure qb-inventory
ensure qb-marketplace-community
```

4. Edit the configuration file:

```text
shared/config.lua
```

5. Open the marketplace in game with:

```text
/marketplace
```

Or use the configured keybind if enabled.

## Configuration

Most settings are available in:

```text
shared/config.lua
```

Example:

```lua
Config.Locale = 'fr'

Config.UI = {
    title = 'QB Marketplace',
    subtitle = 'Community exchange',
    theme = 'purple',
    currency = '$',
    showSeller = true
}

Config.Taxes = {
    enabled = true,
    percentage = 5,
    round = 'floor'
}
```

You can configure:

* UI title, subtitle, theme and currency;
* locale;
* command and keybind;
* buyer and seller money accounts;
* tax percentage and rounding;
* listing expiration;
* cleanup retention;
* item blacklist;
* price and quantity limits;
* Discord webhook logs;
* item categories;
* rarity badges.

## Security

The NUI is only used as an interface. Marketplace actions are validated server-side.

The server checks:

* item names;
* item quantities;
* prices;
* item blacklist;
* player inventory before creating a listing;
* buyer funds before purchase;
* listing ownership before cancellation;
* total price, tax and seller payout;
* duplicate or spammed actions through locks and rate limits.

Purchases and withdrawals use oxmysql transactions to reduce the risk of duplicated items or money.

## Performance

The resource is designed to stay light during normal gameplay.

* No permanent client thread.
* NUI only opens when requested.
* Scheduled cleanup instead of tight loops.
* Indexed SQL tables for listings and history.
* Marketplace data is refreshed only when needed.

## Locales

Lua locales:

```text
locales/fr.lua
locales/en.lua
```

NUI locales:

```text
client/nui/locales.js
```

Set the active language in `shared/config.lua`:

```lua
Config.Locale = 'fr'
```

Available by default:

* French
* English

## Database

The install file is located here:

```text
sql/install.sql
```

It creates:

* `marketplace_listings`
* `marketplace_sales`

Sales history is kept separate from listings so old sales can remain available even after expired listings are cleaned up.

## Screenshot Preview

The README preview is generated from the NUI demo mode.

In game, the demo background is not used. The interface renders over the player camera.

To regenerate the preview locally:

```powershell
chrome --headless --disable-gpu --window-size=1440,900 --screenshot=docs/screenshots/marketplace-preview.png client/nui/index.html?demo=1
```

## Current Framework Support

Current version:

* QBCore
* qb-inventory
* oxmysql

Planned support:

* Qbox
* ox_inventory
* optional bridge layer for easier framework support

The goal is to keep the marketplace logic separated from framework-specific inventory, player and money functions where possible.

## Roadmap

Planned improvements:

* ox_inventory adapter.
* Server-side pagination for very large economies.
* Optional listing fee.
* Admin audit dashboard.
* More marketplace analytics.
* More locale packs.

## Contributing

Pull requests are welcome.

Useful contributions include:

* translations;
* inventory adapters;
* bug fixes with clear reproduction steps;
* UI improvements;
* security hardening;
* framework compatibility work.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Support

This is a community open-source resource.

Issues and suggestions can be posted on GitHub. Please include clear steps, screenshots, logs or error messages when reporting a bug.

## License

MIT License.

Credit is appreciated. Please keep the original copyright notice when redistributing or modifying the resource.
