# Security Policy

## Supported Version

Security fixes target the latest public release.

## Reporting A Vulnerability

Please do not open a public GitHub issue for exploitable bugs.

Report privately with:

- reproduction steps;
- affected version or commit;
- server framework versions;
- expected and actual behavior;
- any relevant logs without secrets.

## Security Principles

This resource treats the NUI as untrusted. The server must always validate:

- item name;
- item ownership;
- quantity;
- price;
- account balances;
- listing ownership;
- withdrawal ownership;
- own-purchase rules.

Pull requests that weaken server-side validation will not be accepted.
