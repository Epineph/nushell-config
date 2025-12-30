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
