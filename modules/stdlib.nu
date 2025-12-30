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
