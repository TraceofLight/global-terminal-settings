let integration = open "/tmp/openclaude-integration-from-generator.nu"

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

print "OPENCLAUDE_GENERATOR_OK"
