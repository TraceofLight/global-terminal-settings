let integration = open "/tmp/openclaude-integration-generated.nu"

for required in [
  "--dangerously-skip-permissions"
  "--allow-dangerously-skip-permissions"
  "--debug-file"
  "--system-prompt"
  "--tmux"
] {
  if not ($integration | str contains $required) {
    error make { msg: $"Missing generated option: ($required)" }
  }
}

print "OPENCLAUDE_GENERATED_OPTIONS_OK"
