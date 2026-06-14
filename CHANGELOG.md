# Changelog

All notable changes to this project are documented here.

## 2.0.0 - Premium Open Source Release

### Added

- Premium transparent glassmorphism NUI.
- Larger responsive panel for 1080p and 1440p.
- Sell, offers, my offers, history and settings tabs.
- Search, category filters and price/date sorting.
- Item cards with rarity and category badges.
- Confirmations, toasts, loader and skeleton states.
- FR/EN Lua and NUI locales.
- Configurable title, theme, currency, accounts, taxes, expiration, blacklist, limits, keybind, Discord logs and seller display.
- Seller history with withdrawable net earnings.
- Listing cancellation with item return.
- Configurable marketplace tax.
- Listing expiration and admin cleanup.
- Strict server validation, rate limits and listing locks.
- oxmysql transactions for purchase and withdrawal flows.
- SQL schema with indexes.
- GitHub-ready README, license, contributing guide, security policy and issue templates.

### Changed

- Replaced the old menu-style NUI with a marketplace product interface.
- Removed escrow/binary resource artifacts from the open-source release.
- Removed the dependency on `mysql-async` in favor of `oxmysql`.

### Fixed

- Removed the in-game black NUI backing rectangle by making the CEF root explicitly transparent and avoiding runtime `backdrop-filter` compositing.
