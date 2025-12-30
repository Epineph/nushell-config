# Installation

## Requirements

- Nushell **0.109+**

Optional (features are guarded; absence is fine):

- `nvim` or `vim` (editor)
- `less` (pager)
- `starship` (prompt)
- `zoxide` (directory jumping)
- `carapace` (external completions)
- `fish` (nice completions for `git` / `nu` if you want it)

## Install (recommended)

From the repo root:

```bash
chmod +x ./scripts/install.sh
./scripts/install.sh
```

This writes thin wrapper files into:

- `~/.config/nushell/env.nu`
- `~/.config/nushell/config.nu`

Any existing files are backed up with a timestamp suffix.

## Per-machine customization (recommended)

Edit the ignored local override files:

- `local/env.local.nu`
  Environment-only overrides (PATH entries, env vars, machine-specific values)

- `local/init.local.nu`
  Behavioral overrides (aliases, keybindings, hooks, extra `use`/`source`)

Templates are provided as:

- `local/env.local.example.nu`
- `local/init.local.example.nu`

## Uninstall

```bash
rm -f ~/.config/nushell/env.nu ~/.config/nushell/config.nu
```

Optionally restore a backup created by `scripts/install.sh`.

## Troubleshooting

### “Many files are not used”
Expected unless they are loaded by `init.nu`. This repo is intentionally explicit.

### Prompt/aliases not applied
Inside `nu`:

```nu
$env.PROMPT_COMMAND
scope aliases | length
```
