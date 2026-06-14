# Troubleshooting

## `/marketplace` does nothing

Check that `qb-core` is running before this resource and that `ensure qb-marketplace-community` is present in `server.cfg`.

## Offers do not save

Import `sql/marketplace.sql` and confirm `oxmysql` is connected to the correct database.

## Item images are missing

Verify `Config.ItemImagesPath` and confirm images exist in your inventory resource.

## Players cannot list an item

Check `Config.BlacklistedItems`, price limits, quantity limits and the player's actual server-side inventory.

## Purchases fail under spam clicking

This is expected protection. The resource rate-limits purchases and locks offer actions briefly to reduce duplicate submissions.
