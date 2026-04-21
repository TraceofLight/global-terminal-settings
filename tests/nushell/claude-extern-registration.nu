source ($nu.default-config-dir | path join "autoload" | path join "claude-integration.nu")

let commands = (help commands | where name =~ '^claude( |$)' | get name)

if ($commands | is-empty) {
  error make {
    msg: "Claude extern commands were not registered"
  }
}

print "CLAUDE_EXTERN_REGISTRATION_OK"
