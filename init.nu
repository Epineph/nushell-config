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
