# Codex macOS installer

This directory contains a `curl ... | bash`-ready installer for `Codex CLI` on macOS.
If Homebrew is missing and the current user is a macOS Administrator, the script will prompt for the administrator password and continue automatically.

## Files

- `install-codex-macos.sh`: installs or updates Homebrew, Node.js, npm global prefix, Codex CLI, PATH setup, and optional API-key login.

## Host it

Upload `install-codex-macos.sh` to any HTTPS URL that serves the raw file, for example:

- GitHub repo raw URL
- GitHub Gist raw URL
- OSS / COS / S3 static file URL

Example raw URL:

```text
https://raw.githubusercontent.com/<your-org>/<your-repo>/main/codex-installer/install-codex-macos.sh
```

## Distribute it

Browser login after install:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-org>/<your-repo>/main/codex-installer/install-codex-macos.sh | bash
```

API key login in one shot:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-org>/<your-repo>/main/codex-installer/install-codex-macos.sh | OPENAI_API_KEY='sk-xxx' bash
```

Skip login and only install environment:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-org>/<your-repo>/main/codex-installer/install-codex-macos.sh | CODEX_SKIP_LOGIN=1 bash
```

## What it handles

- macOS check
- Administrator precheck before attempting a fresh Homebrew install
- Automatic `sudo` authentication prompt for first-time Homebrew install
- Xcode Command Line Tools precheck
- Homebrew install and shell init
- Node.js install
- npm global prefix moved to `~/.npm-global` to avoid `sudo`
- PATH persistence for future terminals
- `@openai/codex` install or update
- Auto login when `OPENAI_API_KEY` is provided

## What still may require user action

- A first-time Homebrew install requires a macOS Administrator account.
- The script can prompt for an administrator password, but it cannot turn a non-admin macOS user into an admin.
- The first install of Xcode Command Line Tools may open an Apple prompt.
- The first Homebrew install may ask for the macOS account password.
- If `OPENAI_API_KEY` is not provided, the user still needs to run `codex login`.
