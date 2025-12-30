# nushell-config (Nu 0.109+)

A reproducible Nushell configuration with explicit wiring:

- Nushell loads `env.nu` first, then `config.nu`.
- This repo keeps those as the only entry points and routes everything through
  `init.nu`.
- Per-machine overrides live in `local/` and are gitignored by default.

## Repo layout

- `env.nu`
  Environment variables only. Optionally generates cache files for integrations
  (carapace/zoxide) and then applies `local/env.local.nu` if present.

- `config.nu`
  Sets `$env.config` (history, completions, etc.), sources integration caches,
  then sources `init.nu`.

- `init.nu`
  Orchestrates everything explicitly: `use` modules, `source` scripts, then
  loads `local/init.local.nu` if present.

- `modules/`
  Reusable commands (`export def ...`) loaded via `use modules/<file>.nu *`.

- `prompt.nu`, `alias.nu`
  Sourced scripts that define prompt behavior and conservative aliases.

- `local/`
  Per-machine overrides:
  - `local/*.example.nu` are tracked templates
  - `local/*.local.nu` are ignored (safe for machine-specific settings)

## Install

```bash
chmod +x ./scripts/install.sh
./scripts/install.sh
nu
```

## Verify inside `nu`

```nu
$nu.env-path
$nu.config-path

scope modules
scope aliases | length
$env.EDITOR
$env.config.edit_mode
```
