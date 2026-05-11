let actual_config = ($env.AQUA_GLOBAL_CONFIG? | default "")
if $actual_config != $env.NU_TEST_EXPECTED_CONFIG {
  print $"expected AQUA_GLOBAL_CONFIG=($env.NU_TEST_EXPECTED_CONFIG), got ($actual_config)"
  exit 1
}

let actual_first_path = ($env.PATH | first)
if $actual_first_path != $env.NU_TEST_EXPECTED_AQUA_BIN {
  print $"expected first PATH entry=($env.NU_TEST_EXPECTED_AQUA_BIN), got ($actual_first_path)"
  exit 1
}

if ($env.PATH | where {|it| $it == $env.NU_TEST_EXPECTED_AQUA_EXE_DIR } | is-empty) {
  print $"expected PATH to contain aqua executable dir=($env.NU_TEST_EXPECTED_AQUA_EXE_DIR)"
  exit 1
}
