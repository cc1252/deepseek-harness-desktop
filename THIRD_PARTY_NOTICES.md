# Third-party notices

DeepSeek Harness Desktop is an independent, unofficial wrapper. It is not
affiliated with, endorsed by, or distributed by DeepSeek.

## DeepSeek Harness

- Project: `deepseek-ai/deepseek-harness`
- Package: `@deepseek-ai/dsh`
- Bundled version: `0.1.0-rc.6`
- License: MIT
- Copyright: Copyright (c) 2026 DeepSeek
- Source: https://github.com/deepseek-ai/deepseek-harness

The whale icon in `build/deepseek-harness.svg` is copied unchanged from the
official package at
`@deepseek-ai/dsh-web-frontend/dist/favicon.svg` and remains attributed to the
upstream project under its MIT license.

## Electron

- Bundled version: `43.4.0`
- License: MIT and bundled Chromium third-party licenses
- Source: https://github.com/electron/electron

Electron's distribution includes `LICENSE.electron.txt` and
`LICENSES.chromium.html` beside the application executable.

## Node.js

- Bundled version: `24.19.0`
- License: MIT and bundled third-party licenses
- Source: https://github.com/nodejs/node

The official Node.js license is included in the application resources as
`harness/runtime/NODE-LICENSE.txt`.

## npm runtime dependencies

The build process generates `build/THIRD_PARTY_LICENSES.txt` from every npm
package bundled below `harness/node_modules`. The generated file is included
in each Windows distribution under `resources/licenses/`.
