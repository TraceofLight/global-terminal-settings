let integration = open "/tmp/claude-integration-from-generator.nu"

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

print "CLAUDE_GENERATOR_OK"
