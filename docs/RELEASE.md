# Release Notes Draft

Use this as the first GitHub release body.

## qb-marketplace-community v2.0.0

Premium open-source QBCore marketplace for FiveM servers.

This release turns the resource into a real marketplace product surface: transparent glass UI, large responsive panel, secure server callbacks, configurable economy controls, seller history, taxes, expiration, Discord logs and FR/EN locales.

### Highlights

- No more black in-game NUI rectangle.
- Larger marketplace layout for 1080p and 1440p.
- Sell, Offers, My Offers, History and Settings tabs.
- Search, filters, sorting, item cards, badges, confirmations, toasts, loader and skeleton states.
- Configurable tax, expiration, accounts, blacklist, limits, keybind and seller display.
- Server-side validation for every critical action.
- oxmysql schema with indexes.
- GitHub-ready docs, templates, license and contribution guide.

### Recommended Launch Post

```markdown
Just released qb-marketplace-community v2.0.0.

A premium-feeling open-source marketplace for FiveM/QBCore:
- transparent glass NUI, no black overlay
- seller history + withdrawable gains
- taxes, expiration, logs, badges, themes
- FR/EN locales
- strict server-side validation

Stars and feedback help shape the ox_inventory adapter.
```

### Release Checklist

- [ ] Import `sql/install.sql`.
- [ ] Configure `shared/config.lua`.
- [ ] Add a Discord webhook only after testing locally.
- [ ] Test `/marketplace` in game.
- [ ] Verify sell, buy, cancel and withdraw flows.
- [ ] Attach `docs/screenshots/marketplace-preview.png` to the GitHub release.
- [ ] Tag the release as `v2.0.0`.
