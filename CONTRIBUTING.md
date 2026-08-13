# Contributing

Thanks for helping improve this unofficial desktop wrapper.

## Development

```powershell
npm ci
npm run setup
npm run dev
```

Run source checks before opening a pull request:

```powershell
npm run check
```

For packaging changes, also run `npm run build:windows` and verify both the
installer and portable executable.

## Scope

This repository owns only the desktop integration layer. Changes to agent
behavior, sessions, workspaces, model providers, or the Harness web interface
normally belong upstream in `deepseek-ai/deepseek-harness`.

Keep dependency versions pinned, do not commit `node_modules`, downloaded Node
runtimes, API keys, local Harness data, build output, or code-signing material.
