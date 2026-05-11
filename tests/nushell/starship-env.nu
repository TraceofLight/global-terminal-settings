let actual_config_home = ($env.XDG_CONFIG_HOME? | default "")
if $actual_config_home != $env.NU_TEST_EXPECTED_XDG_CONFIG_HOME {
  print $"expected XDG_CONFIG_HOME=($env.NU_TEST_EXPECTED_XDG_CONFIG_HOME), got ($actual_config_home)"
  exit 1
}

let actual_starship_config = ($env.STARSHIP_CONFIG? | default "")
if $actual_starship_config != $env.NU_TEST_EXPECTED_STARSHIP_CONFIG {
  print $"expected STARSHIP_CONFIG=($env.NU_TEST_EXPECTED_STARSHIP_CONFIG), got ($actual_starship_config)"
  exit 1
}
