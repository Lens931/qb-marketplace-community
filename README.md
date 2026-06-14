# qb-marketplace-community

> Clean open-source QBCore marketplace system with NUI, SQL persistence, player listings, purchase flow and seller earnings.

A modern FiveM/QBCore marketplace resource rebuilt from scratch for public GitHub release by Lens931. It provides a premium glassmorphism NUI, SQL-backed player listings, strict server validation and an event-driven client designed for 0.00ms idle.

## Preview

![Preview placeholder](screenshots/.gitkeep)

## Features

- `/marketplace` command and optional configurable keybind.
- Premium vanilla HTML/CSS/JS NUI with tabs: sell, browse, my offers and history.
- QBCore inventory integration with blacklist, labels, weights, quantities and images.
- Multi-item draft listing workflow with server-side item removal only after validation.
- SQL persisted offers and seller sales history.
- Secure buy flow with server-side price recalculation, money checks and atomic quantity update.
- Seller earnings withdrawal to `cash` or `bank`.
- Listing cancellation with item return.
- Simple rate limits for sensitive actions and optional Discord logs.
- No permanent client thread, no DrawText loop and no frontend framework dependency.

## Requirements

- FiveM artifact with Lua 5.4 support.
- QBCore / `qb-core`.
- `oxmysql`.
- `qb-inventory` by default for item images and item box notifications.

## Installation

```bash
cd resources/[qb]
git clone https://github.com/Lens931/qb-marketplace-community.git
```

Import `sql/marketplace.sql`, then add this to `server.cfg` after `qb-core`, `qb-inventory` and `oxmysql`:

```cfg
ensure qb-marketplace-community
```

## SQL setup

Import the SQL file with your database tool or run:

```bash
mysql -u USER -p DATABASE < resources/[qb]/qb-marketplace-community/sql/marketplace.sql
```

## Configuration

Edit `config.lua` to change the title, command, keybind, accounts, expiration, price limits, listing limits, blacklist, item image path and locale.

## Usage

- Players open the menu with `/marketplace`.
- Sellers add inventory items to a draft, choose quantity and unit price, then confirm.
- Buyers browse active offers and buy a chosen quantity or the full listing.
- Sellers use “Mes offres” to cancel active listings.
- Sellers use “Historique” to view sales and withdraw pending earnings.

## Performance notes

The client is entirely event-driven. It registers commands, key mappings and NUI callbacks only. It does not run a permanent `CreateThread`, `Wait(0)` loop or DrawText loop, so idle usage should remain at 0.00ms while the NUI is closed.

## Security notes

The server validates inventory ownership, listing quantities, listing prices, blacklist status, buyer funds, own-offer rules and seller ownership. SQL queries use parameters. Purchases update offer quantity with a guarded SQL condition to reduce race-condition and double-click duplication risk.

## Roadmap

- v1.1 inventory adapter layer for ox_inventory and qs-inventory.
- Admin moderation panel and audit exports.
- Category filters and saved searches.
- Listing fees or taxes.
- Optional escrow payout delay.

## Contributing

Pull requests are welcome. Keep code readable, dependency-light and compatible with a clean QBCore server. Do not submit obfuscated, escrowed or private dependency code.

## License

MIT License. See `LICENSE`.
