# Security Policy

## Supported versions

Security fixes target the latest public release of `qb-marketplace-community`.

## Reporting a vulnerability

Please report vulnerabilities privately to the repository owner before public disclosure. Include reproduction steps, expected impact and any relevant server logs.

## Security design

- Client input is never trusted.
- Prices and totals are recalculated on the server.
- Inventory and money mutations happen on the server.
- SQL queries use parameter binding.
- Sensitive callbacks are rate limited.
- Offer purchases use guarded quantity updates to reduce race conditions.
