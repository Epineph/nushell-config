#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# nushell-config-bootstrap.sh
#
# Regenerate the repo tree for a reproducible Nushell config (Nu 0.109+).
# Keeps local/*.local.nu untouched.
# -----------------------------------------------------------------------------

set -euo pipefail

function die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

function help_text() {
  cat <<'EOF'
nushell-config-bootstrap.sh

USAGE
  ./nushell-config-bootstrap.sh [--repo-dir PATH] [--force]

OPTIONS
  --repo-dir PATH
      Target directory to write files into. Default: current working directory.

  --force
      Overwrite existing tracked files (creates .bak timestamps).

  -h, --help
      Show this help.
EOF
}

function run_help_pager() {
  local pager="${HELP_PAGER:-}"
  if [[ -z "$pager" ]]; then
    if command -v less >/dev/null 2>&1; then
      pager='less -R'
    else
      pager='cat'
    fi
  fi
  help_text | eval "$pager"
}

function stamp() {
  date '+%Y%m%d-%H%M%S'
}

repo_dir="$(pwd -P)"
force="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir)
      [[ $# -ge 2 ]] || die "--repo-dir requires a PATH argument"
      repo_dir="$2"
      shift 2
      ;;
    --force)
      force="1"
      shift
      ;;
    -h|--help)
      run_help_pager
      exit 0
      ;;
    *)
      die "Unknown argument: $1 (use --help)"
      ;;
  esac
done

repo_dir="$(mkdir -p "$repo_dir" && cd "$repo_dir" && pwd -P)"

function write_file() {
  local path="$1"
  local mode="${2:-0644}"

  # Never overwrite per-machine local overrides.
  if [[ "$path" == */local/*.local.nu && -e "$path" ]]; then
    return 0
  fi

  if [[ -e "$path" && "$force" != "1" ]]; then
    die "Refusing to overwrite existing file: $path (use --force)"
  fi

  mkdir -p "$(dirname "$path")"

  if [[ -e "$path" && "$force" == "1" ]]; then
    cp -a "$path" "${path}.bak.$(stamp)" 2>/dev/null || true
  fi

  local tmp
  tmp="$(mktemp)"
  cat >"$tmp"
  install -m "$mode" "$tmp" "$path"
  rm -f "$tmp"
}

write_file "$repo_dir/README.md" 0644 <<'EOF'
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
EOF

write_file "$repo_dir/INSTALL.md" 0644 <<'EOF'
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
EOF

write_file "$repo_dir/.gitignore" 0644 <<'EOF'
# Per-machine overrides (tracked templates exist alongside these)
local/*.local.nu

# Optional local scratch
.local/
EOF

write_file "$repo_dir/.gitattributes" 0644 <<'EOF'
* text=auto eol=lf
EOF

write_file "$repo_dir/.editorconfig" 0644 <<'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false
EOF

write_file "$repo_dir/scripts/install.sh" 0755 <<'EOF'
#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# scripts/install.sh
#
# Install thin wrappers into ~/.config/nushell that source this repo.
# -----------------------------------------------------------------------------

set -euo pipefail

function die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

function stamp() {
  date '+%Y%m%d-%H%M%S'
}

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
nu_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nushell"

mkdir -p "$nu_dir"

for f in env.nu config.nu; do
  if [[ -e "$nu_dir/$f" ]]; then
    mv -f "$nu_dir/$f" "$nu_dir/$f.bak.$(stamp)"
  fi
done

cat >"$nu_dir/env.nu" <<EOF
# Wrapper installed by scripts/install.sh
source-env "$repo_root/env.nu"
EOF

cat >"$nu_dir/config.nu" <<EOF
# Wrapper installed by scripts/install.sh
source "$repo_root/config.nu"
EOF

printf 'Installed wrappers:\n  %s\n  %s\n' \
  "$nu_dir/env.nu" "$nu_dir/config.nu"
printf 'Repo entry points:\n  %s\n  %s\n' \
  "$repo_root/env.nu" "$repo_root/config.nu"
EOF

write_file "$repo_dir/env.nu" 0644 <<'EOF'
# -----------------------------------------------------------------------------
# env.nu (Nu 0.109+)
# Environment variables only. Loaded before config.nu.
# -----------------------------------------------------------------------------

def cmd-exists [name: string] -> bool {
  not (which $name | is-empty)
}

mkdir $nu.cache-dir | ignore

if (cmd-exists nvim) {
  $env.EDITOR = "nvim"
  $env.VISUAL = "nvim"
} else if (cmd-exists vim) {
  $env.EDITOR = "vim"
  $env.VISUAL = "vim"
} else {
  $env.EDITOR = "vi"
  $env.VISUAL = "vi"
}

$env.PAGER = ($env.PAGER? | default "less -R")
$env.HELP_PAGER = ($env.HELP_PAGER? | default "less -R")

# PATH in Nushell is a list (commonly exposed as $env.path).
$env.path ++= [
  ($env.HOME | path join ".local" "bin")
  "/usr/local/bin"
]

# Optional: cache carapace init once.
let carapace_cache = ($nu.cache-dir | path join "carapace.nu")
if (cmd-exists carapace) and (not ($carapace_cache | path exists)) {
  carapace _carapace nushell | save --force $carapace_cache
}

# Optional: cache zoxide init once.
let zoxide_cache = ($nu.cache-dir | path join "zoxide.nu")
if (cmd-exists zoxide) and (not ($zoxide_cache | path exists)) {
  zoxide init nushell | save --force $zoxide_cache
}

let local_env = ($env.FILE_PWD | path join "local" "env.local.nu")
if ($local_env | path exists) {
  source-env $local_env
}
EOF

write_file "$repo_dir/config.nu" 0644 <<'EOF'
# -----------------------------------------------------------------------------
# config.nu (Nu 0.109+)
# Configure $env.config and then source init.nu.
# -----------------------------------------------------------------------------

def cmd-exists [name: string] -> bool {
  not (which $name | is-empty)
}

let fish_completer = {|spans: list<string>|
  if not (cmd-exists fish) { return null }
  fish --command $'complete "--do-complete=($spans | str join " ")"'
  | from tsv --flexible --noheaders --no-infer
  | rename value description
}

let carapace_completer = {|spans: list<string>|
  if not (cmd-exists carapace) { return null }
  carapace $spans.0 nushell ...$spans | from json
}

let external_completer = {|spans: list<string>|
  let expanded_alias = (
    scope aliases
    | where name == $spans.0
    | get -o 0.expansion
  )

  let spans = if $expanded_alias != null {
    $spans | skip 1 | prepend ($expanded_alias | split row ' ' | take 1)
  } else {
    $spans
  }

  match $spans.0 {
    git => $fish_completer
    nu => $fish_completer
    _ => $carapace_completer
  } | do $in $spans
}

$env.config = ($env.config | upsert show_banner false)
$env.config = ($env.config | upsert edit_mode "vi")
$env.config = ($env.config | upsert buffer_editor ($env.EDITOR | default "nvim"))

$env.config = ($env.config | upsert history {
  max_size: 200_000
  sync_on_enter: true
  file_format: "sqlite"
  isolation: true
})

$env.config = ($env.config | upsert completions {
  case_sensitive: false
  quick: true
  partial: true
  algorithm: "fuzzy"
  external: {
    enable: true
    completer: $external_completer
  }
})

# Source cached integrations generated in env.nu, if present.
let carapace_cache = ($nu.cache-dir | path join "carapace.nu")
if ($carapace_cache | path exists) { source $carapace_cache }

let zoxide_cache = ($nu.cache-dir | path join "zoxide.nu")
if ($zoxide_cache | path exists) { source $zoxide_cache }

source ($env.FILE_PWD | path join "init.nu")
EOF

write_file "$repo_dir/init.nu" 0644 <<'EOF'
# -----------------------------------------------------------------------------
# init.nu (Nu 0.109+)
# Explicitly load modules and scripts. Nothing is implicit.
# -----------------------------------------------------------------------------

let root = $env.FILE_PWD

use ($root | path join "modules" "stdlib.nu") *
use ($root | path join "modules" "lib.nu") *

source ($root | path join "prompt.nu")
source ($root | path join "alias.nu")

let local_init = ($root | path join "local" "init.local.nu")
if ($local_init | path exists) {
  source $local_init
}
EOF

write_file "$repo_dir/prompt.nu" 0644 <<'EOF'
# -----------------------------------------------------------------------------
# prompt.nu (Nu 0.109+)
# Prefer starship if installed; otherwise a minimal prompt.
# -----------------------------------------------------------------------------

def cmd-exists [name: string] -> bool {
  not (which $name | is-empty)
}

def prompt-cwd [] -> string {
  $env.PWD | str replace $env.HOME "~"
}

def prompt-git-branch [] -> string {
  try { ^git rev-parse --abbrev-ref HEAD | str trim } catch { "" }
}

def prompt-left [] -> string {
  let cwd = (prompt-cwd)
  let br = (prompt-git-branch)
  if ($br | is-empty) { $cwd } else { $"($cwd) ($br)" }
}

if (cmd-exists starship) {
  $env.STARSHIP_SHELL = "nu"

  $env.PROMPT_COMMAND = {||
    let dur = ($env.CMD_DURATION_MS? | default 0)
    let st = ($env.LAST_EXIT_CODE? | default 0)
    ^starship prompt --cmd-duration $dur --status $st
  }

  $env.PROMPT_COMMAND_RIGHT = {|| "" }
  $env.PROMPT_INDICATOR = {|| "" }
} else {
  $env.PROMPT_COMMAND = {|| $"(prompt-left)\n〉 " }
  $env.PROMPT_COMMAND_RIGHT = {|| "" }
  $env.PROMPT_INDICATOR = {|| "" }
}
EOF

write_file "$repo_dir/alias.nu" 0644 <<'EOF'
# -----------------------------------------------------------------------------
# alias.nu
# Conservative aliases. Avoid overriding Nu builtins by default.
# -----------------------------------------------------------------------------

alias q = exit
alias c = clear

alias e = edit
alias v = nvim

alias gs = ^git status
alias gl = ^git log --oneline --decorate -n 20
EOF

write_file "$repo_dir/modules/stdlib.nu" 0644 <<'EOF'
# -----------------------------------------------------------------------------
# modules/stdlib.nu
# Small helpers used by other modules/scripts.
# -----------------------------------------------------------------------------

export def unwrap-only [] {
  let head = ($in | take 2)
  let n = ($head | length)

  if $n == 1 {
    $head | first
  } else if $n == 0 {
    error make { msg: "unwrap-only: input is empty" }
  } else {
    error make { msg: "unwrap-only: input has length > 1" }
  }
}
EOF

write_file "$repo_dir/modules/lib.nu" 0644 <<'EOF'
# -----------------------------------------------------------------------------
# modules/lib.nu
# Small optional utilities (guard external tools in the command bodies).
# -----------------------------------------------------------------------------

def cmd-exists [name: string] -> bool {
  not (which $name | is-empty)
}

export def edit [path?: string] {
  let p = ($path | default ".") | path expand
  let ed = ($env.EDITOR? | default "nvim")
  ^($ed) $p
}

export def vscode [path?: string] {
  if not (cmd-exists code) {
    error make { msg: "VS Code CLI 'code' not found in PATH." }
  }
  let p = ($path | default ".") | path expand
  ^code $p
}
EOF

write_file "$repo_dir/local/env.local.example.nu" 0644 <<'EOF'
# local/env.local.nu (example)
# Sourced via `source-env` from env.nu if local/env.local.nu exists.
#
# Example:
# $env.path ++= [($env.HOME | path join "bin")]
EOF

write_file "$repo_dir/local/init.local.example.nu" 0644 <<'EOF'
# local/init.local.nu (example)
# Sourced from init.nu if local/init.local.nu exists.
#
# Example:
# $env.config = ($env.config | upsert edit_mode "vi")
EOF

if [[ ! -e "$repo_dir/local/env.local.nu" ]]; then
  write_file "$repo_dir/local/env.local.nu" 0644 <<'EOF'
# local/env.local.nu
# Per-machine environment customizations (gitignored).
EOF
fi

if [[ ! -e "$repo_dir/local/init.local.nu" ]]; then
  write_file "$repo_dir/local/init.local.nu" 0644 <<'EOF'
# local/init.local.nu
# Per-machine behavioral customizations (gitignored).
EOF
fi

chmod 0755 "$repo_dir/scripts/install.sh"

printf 'Generated repo tree in: %s\n' "$repo_dir"
printf 'Next steps:\n'
printf '  1) ./scripts/install.sh\n'
printf '  2) nu\n'
