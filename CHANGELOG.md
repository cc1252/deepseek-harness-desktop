# Changelog

## 0.1.1 - 2026-09-24

- Update the bundled DeepSeek Harness from `0.1.0-rc.6` to `0.1.7-rc.1`.
- Refresh the complete Harness dependency lockfile and audited install-script list.
- Preserve the new Web access token when loading the UI without writing it to logs.
- Prevent Harness from opening a separate browser window at desktop startup.
- Refresh the bundled upstream icon.
- Keep the desktop shell, Electron, and bundled Node.js versions unchanged.

## 0.1.0 - 2026-08-13

- Initial open-source release.
- Bundle DeepSeek Harness `0.1.0-rc.6`, Electron `43.4.0`, and Node.js
  `24.19.0`.
- Add a frameless custom title bar with minimize, maximize/restore, and close.
- Use the official whale icon from the upstream Harness package.
- Provide reproducible Windows runtime preparation, NSIS installer, portable
  executable, license inventory, checksums, and GitHub Release automation.
- Keep the installer in the standard per-user directory to avoid legacy
  Windows path-length limits in deeply nested upstream dependencies.
