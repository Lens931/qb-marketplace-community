# Installation

1. Place the resource in your FiveM resources folder.
2. Import `sql/marketplace.sql` into the same database used by QBCore.
3. Ensure dependencies first in `server.cfg`:

```cfg
ensure oxmysql
ensure qb-core
ensure qb-inventory
ensure qb-marketplace-community
```

4. Restart the server or run `refresh` then `ensure qb-marketplace-community`.
5. In game, run `/marketplace`.
