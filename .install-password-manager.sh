#!/bin/bash
# chezmoi read-source-state pre hook: make sure the Bitwarden CLI is installed and
# logged in before templates call bitwardenFields. Runs on every chezmoi command
# that reads the source state, so it must exit quickly when nothing is needed.
# The leading dot keeps chezmoi from managing this file.
set -euo pipefail

export PATH="/snap/bin:$PATH"

if ! command -v bw > /dev/null; then
  if [ "$(uname -s)" != "Linux" ] || ! command -v snap > /dev/null; then
    echo "bw not installed and snap unavailable; Bitwarden-backed templates will be skipped." >&2
    exit 0
  fi
  echo "Installing Bitwarden CLI (snap)..." >&2
  sudo snap install bw
fi

# Log in once, interactively, if a terminal is attached. Unlocking is done by
# chezmoi itself (bitwarden.unlock = auto) or via an exported BW_SESSION.
if [ -t 0 ] && [ "$(bw status | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')" = "unauthenticated" ]; then
  echo "Logging in to Bitwarden..." >&2
  bw login
fi
