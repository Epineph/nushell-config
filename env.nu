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
