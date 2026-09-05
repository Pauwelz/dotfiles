#!/bin/bash
# Bootstrap: install chezmoi and the Bitwarden CLI, log in, then run chezmoi init --apply.
# Usage: sh -c "$(curl -fsSL https://raw.githubusercontent.com/Pauwelz/dotfiles/main/install.sh)" [-- --branch <name>]
set -euo pipefail

REPO="pauwelz"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:/snap/bin:$PATH"

if ! command -v chezmoi > /dev/null; then
  echo "Installing chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN_DIR"
fi

if ! command -v bw > /dev/null; then
  if command -v snap > /dev/null; then
    echo "Installing Bitwarden CLI (snap)..."
    sudo snap install bw
  else
    echo "snap not available; skipping Bitwarden CLI. chezmoi init will prompt for the work email." >&2
  fi
fi

if command -v bw > /dev/null; then
  if [ "$(bw status | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')" = "unauthenticated" ]; then
    echo "Logging in to Bitwarden..."
    bw login
  fi
  if [ -z "${BW_SESSION:-}" ]; then
    BW_SESSION="$(bw unlock --raw)"
    export BW_SESSION
  fi
fi

exec chezmoi init --apply "$REPO" "$@"
