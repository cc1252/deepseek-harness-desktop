# Architecture

```text
BrowserWindow (frameless shell)
├─ shell.html
│  └─ preload.js -> narrow window-control IPC
└─ WebContentsView
   └─ http://127.0.0.1:<random port> (official Harness UI)
        └─ bundled node.exe runs @deepseek-ai/dsh web --port 0
```

## Why two renderers?

The frameless `BrowserWindow` owns the trusted title bar. The official Harness
page is attached as a separate `WebContentsView` below it. This prevents the
remote-style local web application from receiving Electron or Node.js access
while keeping the native window controls responsive.

## Startup

1. Electron creates the hidden frameless shell and loads `shell.html`.
2. The shell is shown with a lightweight startup view.
3. The main process starts the pinned Node.js runtime with
   `@deepseek-ai/dsh web --port 0`.
4. It parses the loopback URL printed by Harness.
5. A sandboxed `WebContentsView` loads that URL and fills the area below the
   42-pixel title bar.

## Shutdown

`before-quit` stops the child Harness process. The application uses a
single-instance lock so a second launch activates the existing window instead
of starting a second local service.

## Trust boundaries

- `shell.html` is packaged application code and may access only the API exposed
  by `preload.js`.
- Harness content has no preload script and no Node.js integration.
- IPC messages are accepted only when their sender is the shell web contents.
- Navigation remains inside the discovered loopback origin; ordinary external
  HTTP(S) links open in the system browser.
