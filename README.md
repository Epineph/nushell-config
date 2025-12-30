# Nushell Config (Nu 0.109+)

A reproducible Nushell configuration with **explicit wiring** and **clean layering**

Nushell only auto-loads two files at startup:

- `$nu.env-path` (typically `~/.config/nushell/env.nu`)
- `$nu.config-path` (typically `~/.config/nushell/config.nu`)

This repo keeps those as thin wrappers (installed by `scripts/install.sh`) and loads
everything else explicitly via `init.nu`.

## Layout

 `env.nu`  
  Environment variables only (`$env.EDITOR`, `$env.PATH`, optional zoxide/carapace
  cache generation, etc.). Loads `local/env.local.nu` if present.

- `config.nu`  
  Shell configuration (`$env.config`, history, completions, hooks) and then
  `source`s `init.nu`.

- `init.nu`  
  The orchestrator. Explicitly `use`s modules and `source`s scripts. Loads
  `local/init.local.nu` if present.

- `modules/`  
  Nushell “modules” (`export def ...`) loaded with `use ... *`.

- `prompt.nu`, `alias.nu`  
  Scripts loaded with `source` that install prompt and conservative aliases,

- `local/`
  Per-machine overrides. `local/*.example.nu` are tracked templates,
  `local/*.local.nu` are ignored by default (safe for machine-specific secrets).

## Quick start

```bash
./scripts/install.sh
nu
```

# Verify what is actually loaded

## Inside `nu`

```nu
$nu.env-path
$nu.config-path

scope commands | where name =~ '^(edit|vscode|sublime|browse)$'
scope aliases
$env.EDITOR
$env.config.edit_mode
```

If a command/alias is absent, it is not being loaded. This repo avoids implicit
autoloading by design.
