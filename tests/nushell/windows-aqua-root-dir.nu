let actual_root = ($env.AQUA_ROOT_DIR? | default "")
if $actual_root != $env.NU_TEST_EXPECTED_AQUA_ROOT_DIR {
  print $"expected AQUA_ROOT_DIR=($env.NU_TEST_EXPECTED_AQUA_ROOT_DIR), got ($actual_root)"
  exit 1
}

let expected_bin = ($env.NU_TEST_EXPECTED_AQUA_ROOT_DIR | path join "bin")
let actual_first_path = ($env.PATH | first)
if $actual_first_path != $expected_bin {
  print $"expected first PATH entry=($expected_bin), got ($actual_first_path)"
  exit 1
}
