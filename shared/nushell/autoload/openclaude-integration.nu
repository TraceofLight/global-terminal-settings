def __terminal_bootstrap_openclaude_permission_modes [] {
  ["acceptEdits", "bypassPermissions", "default", "dontAsk", "plan"]
}

if (which openclaude | is-not-empty) {
  extern "openclaude" [
    prompt?: string
    ...args: string
    --add-dir: string
    --agent: string
    --allowed-tools: string
    --append-system-prompt: string
    --continue(-c)
    --debug(-d): string
    --disallowed-tools: string
    --effort: string
    --help(-h)
    --model: string
    --name(-n): string
    --permission-mode: string@__terminal_bootstrap_openclaude_permission_modes
    --print(-p)
    --provider: string
    --resume(-r): string
    --settings: string
    --version(-v)
    --worktree(-w): string
  ]

  extern "openclaude agents" [
    ...args: string
    --help(-h)
  ]

  extern "openclaude auth" [
    ...args: string
    --help(-h)
  ]

  extern "openclaude doctor" [
    ...args: string
    --help(-h)
  ]

  extern "openclaude install" [
    target?: string
    ...args: string
    --help(-h)
  ]

  extern "openclaude mcp" [
    ...args: string
    --help(-h)
  ]

  extern "openclaude plugin" [
    ...args: string
    --help(-h)
  ]

  extern "openclaude plugins" [
    ...args: string
    --help(-h)
  ]

  extern "openclaude setup-token" [
    ...args: string
    --help(-h)
  ]

  extern "openclaude update" [
    ...args: string
    --help(-h)
  ]

  extern "openclaude upgrade" [
    ...args: string
    --help(-h)
  ]
}
