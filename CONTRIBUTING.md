# Contributing

Thanks for helping improve `qb-marketplace-community`.

## Good First Contributions

- Add or improve translations.
- Add item badge presets.
- Improve README examples.
- Report compatibility notes for specific QBCore/qb-inventory versions.
- Improve UI polish without reintroducing a black in-game overlay.

## Pull Request Checklist

- Keep changes focused.
- Do not commit secrets, webhooks or server-specific config.
- Keep the NUI transparent over the game.
- Validate browser JavaScript with:

```powershell
node --check client\nui\app.js
```

- Test in game when changing Lua callbacks, inventory behavior or SQL.
- Update README or CHANGELOG when behavior changes.

## Code Style

- Keep functions small and named clearly.
- Validate all NUI data server-side.
- Prefer config-driven behavior over hardcoded server assumptions.
- Avoid permanent client threads.
- Avoid obfuscated code.

## Security

Security-related issues should be handled through [SECURITY.md](SECURITY.md), not public issues.
