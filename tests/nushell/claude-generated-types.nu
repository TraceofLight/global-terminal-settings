let integration = open "/tmp/claude-integration-from-generator.nu"

if not ($integration | str contains "--name: string") {
  error make { msg: "Expected --name to accept a string argument" }
}

if not ($integration | str contains "--worktree: string") {
  error make { msg: "Expected --worktree to accept a string argument" }
}

if not ($integration | str contains "  --tmux\n") {
  error make { msg: "Expected --tmux to be a switch option" }
}

print "CLAUDE_GENERATED_TYPES_OK"
