source ($nu.default-config-dir | path join "autoload" | path join "openclaude-integration.nu")

let commands = (help commands | where name =~ '^openclaude( |$)' | get name)

if ($commands | is-empty) {
  error make {
    msg: "OpenClaude extern commands were not registered"
  }
}

print "OPENCLAUDE_EXTERN_REGISTRATION_OK"
