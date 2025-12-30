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
