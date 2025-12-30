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
