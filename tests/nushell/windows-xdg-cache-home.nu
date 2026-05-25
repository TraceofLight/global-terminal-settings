let actual_cache_home = ($env.XDG_CACHE_HOME? | default "")
if $actual_cache_home != $env.NU_TEST_EXPECTED_XDG_CACHE_HOME {
  print $"expected XDG_CACHE_HOME=($env.NU_TEST_EXPECTED_XDG_CACHE_HOME), got ($actual_cache_home)"
  exit 1
}
