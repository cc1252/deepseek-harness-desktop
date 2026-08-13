# Security policy

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting feature when available.
Do not publish API keys, session data, local paths, or an unpatched exploit in
a public issue.

## Supported releases

Only the newest GitHub Release is supported. This community project and the
upstream Harness are pre-release software and carry no warranty.

## Secrets

The wrapper never embeds an API key. Harness may read provider credentials from
its settings or inherited environment variables. Never attach your user-data
directory or `desktop.log` to a public issue without reviewing it first.
