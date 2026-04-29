#!/usr/bin/env bash

set -euo pipefail

SCRIPT_VERSION="2026-04-29"
BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
NPM_GLOBAL_PREFIX_DEFAULT="${HOME}/.npm-global"

log() {
  printf '[codex-installer] %s\n' "$*"
}

warn() {
  printf '[codex-installer] WARN: %s\n' "$*" >&2
}

fail() {
  printf '[codex-installer] ERROR: %s\n' "$*" >&2
  exit 1
}

append_line_once() {
  local file="$1"
  local line="$2"

  mkdir -p "$(dirname "$file")"
  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf '\n%s\n' "$line" >>"$file"
  fi
}

detect_profiles() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
    zsh)
      printf '%s\n' "${HOME}/.zprofile"
      printf '%s\n' "${HOME}/.zshrc"
      ;;
    bash)
      printf '%s\n' "${HOME}/.bash_profile"
      printf '%s\n' "${HOME}/.bashrc"
      ;;
    *)
      printf '%s\n' "${HOME}/.profile"
      ;;
  esac
}

persist_path_line() {
  local line="$1"
  while IFS= read -r profile; do
    append_line_once "$profile" "$line"
  done < <(detect_profiles)
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "This installer only supports macOS."
  fi
}

ensure_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    return 0
  fi

  warn "Xcode Command Line Tools are not installed."
  warn "Launching Apple's installer. After it finishes, rerun this command."
  xcode-select --install || true
  exit 1
}

init_homebrew_env() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
  fi

  if [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return 0
  fi

  return 1
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    init_homebrew_env
    return 0
  fi

  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "${BREW_INSTALL_URL}")"
  init_homebrew_env || fail "Homebrew installed but brew shellenv could not be initialized."

  if [[ -x /opt/homebrew/bin/brew ]]; then
    persist_path_line 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  elif [[ -x /usr/local/bin/brew ]]; then
    persist_path_line 'eval "$(/usr/local/bin/brew shellenv)"'
  fi
}

ensure_node() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    log "Node.js already present: $(node -v)"
    return 0
  fi

  log "Installing Node.js via Homebrew..."
  brew install node
}

ensure_npm_prefix() {
  local current_prefix
  current_prefix="$(npm config get prefix 2>/dev/null || true)"

  if [[ "$current_prefix" != "$NPM_GLOBAL_PREFIX_DEFAULT" ]]; then
    log "Configuring npm global prefix at ${NPM_GLOBAL_PREFIX_DEFAULT}..."
    mkdir -p "${NPM_GLOBAL_PREFIX_DEFAULT}"
    npm config set prefix "${NPM_GLOBAL_PREFIX_DEFAULT}"
  fi

  persist_path_line 'export PATH="$HOME/.npm-global/bin:$PATH"'
  export PATH="${HOME}/.npm-global/bin:${PATH}"
}

install_or_update_codex() {
  if command -v codex >/dev/null 2>&1; then
    log "Updating Codex CLI..."
    npm install -g @openai/codex
    return 0
  fi

  log "Installing Codex CLI..."
  npm install -g @openai/codex
}

ensure_codex_path() {
  if command -v codex >/dev/null 2>&1; then
    return 0
  fi

  local npm_bin
  npm_bin="$(npm bin -g 2>/dev/null || true)"
  if [[ -n "$npm_bin" && -x "${npm_bin}/codex" ]]; then
    export PATH="${npm_bin}:${PATH}"
    return 0
  fi

  fail "Codex CLI installed but was not found in PATH."
}

login_codex() {
  if codex login status >/dev/null 2>&1; then
    log "Codex is already authenticated."
    return 0
  fi

  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    log "Logging in with OPENAI_API_KEY..."
    printf '%s' "${OPENAI_API_KEY}" | codex login --with-api-key
    return 0
  fi

  if [[ "${CODEX_SKIP_LOGIN:-0}" == "1" ]]; then
    warn "Skipped login because CODEX_SKIP_LOGIN=1."
    return 0
  fi

  warn "No OPENAI_API_KEY found."
  warn "Next step:"
  warn "  1. Run: codex login"
  warn "  2. Or rerun this installer with OPENAI_API_KEY set."
}

print_summary() {
  local codex_path codex_version node_version npm_version
  codex_path="$(command -v codex || true)"
  codex_version="$(codex -V 2>/dev/null || true)"
  node_version="$(node -v 2>/dev/null || true)"
  npm_version="$(npm -v 2>/dev/null || true)"

  log "Install complete."
  log "Version: ${SCRIPT_VERSION}"
  log "Node: ${node_version}"
  log "npm: ${npm_version}"
  log "Codex: ${codex_version}"
  log "Codex path: ${codex_path}"
  log "If 'codex' is not available in your current shell, open a new terminal window."
}

main() {
  ensure_macos
  ensure_clt
  ensure_homebrew
  ensure_node
  ensure_npm_prefix
  install_or_update_codex
  ensure_codex_path
  login_codex
  print_summary
}

main "$@"
