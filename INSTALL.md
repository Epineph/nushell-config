# `INSTALL.md`

```md
# Installation

## Requirements

- Nushell **0.109+**
- Optional but supported:
  - `nvim` (preferred editor)
  - `less` (pager)
  - `starship` (prompt)
  - `zoxide` (directory jumping)
  - `carapace` (external completions)
  - `fzf` (interactive browsing)
```

None of the optional tools are required; features are guarded.
## Install (recommended)
From the repo root:

```bash
chmod +x ./scripts/install.sh
./scripts/install.sh
```

This installs **thin wrapper** files into:

* `~/.config/nushell/env.nu`

* `~/.config/nushell/config.nu`
  
The wrappers simply `source-env / source` the repo `env.nu` and `config.nu`.
Any existing files are backed up with a timestamp suffix.

## Customize per machine (recommended)

Edit the ignored local override files:

* `local/env.local.nu`
Environment-only overrides (extra PATH entries, env vars, etc.)

* `local/init.local.nu`
Behavioral overrides (additional aliases, keybindings, hooks, etc.)

Templates are provided as:

* `local/env.local.example.nu`

* `local/env.local.example.nu`

# Uninstall

## Remove the wrapper files:

```bash
rm -f ~/.config/nushell/env.nu ~/.config/nushell/config.nu
```

Optionally restore one of the backups created by `scripts/install.sh` (the files
will have a `.bak.YYYYMMDD-HHMMSS` suffix)

## Troubleshooting

**“Many files are not used”**
That is expected unless `init.nu` loads them. This repo is intentionally explicit:
only `env.nu` and `config.nu` are entry points; everything else must be imported.

**Prompt/aliases not applied**
Inside `nu`, check:

```nu
$env.PROMPT_COMMAND
scope aliases | length
```

If these are unset/empty, `prompt.nu` / `alias.nu` are not being sourced from
`init.nu`

If you want, I can also generate a minimal `LICENSE` (MIT) and a `CHANGELOG.md` skeleton, but these two files are sufficient to make the repo self-explanatory and reproducible.
::contentReference[oaicite:0]{index=0}
