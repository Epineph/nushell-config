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
