#!/bin/bash
# chezmoi read-source-state pre hook: make sure the Bitwarden CLI is installed,
# pointed at the EU cloud and logged in before templates call bitwardenFields.
# Runs on every chezmoi command that reads the source state, so it must exit
# quickly when nothing is needed. The leading dot keeps chezmoi from managing it.
set -euo pipefail

BW_SERVER="https://vault.bitwarden.eu"
export PATH="/snap/bin:$PATH"

if ! command -v bw > /dev/null; then
  if [ "$(uname -s)" != "Linux" ] || ! command -v snap > /dev/null; then
    echo "bw not installed and snap unavailable; Bitwarden-backed templates will be skipped." >&2
    exit 0
  fi
  echo "Installing Bitwarden CLI (snap)..." >&2
  sudo snap install bw
fi

status_json="$(bw status)"
status="$(sed -n 's/.*"status":"\([^"]*\)".*/\1/p' <<< "$status_json")"
server="$(sed -n 's/.*"serverUrl":"\([^"]*\)".*/\1/p' <<< "$status_json")"

if [ "$status" = "unauthenticated" ]; then
  # The server can only be changed while logged out.
  if [ "$server" != "$BW_SERVER" ]; then
    echo "Pointing Bitwarden CLI at $BW_SERVER..." >&2
    bw config server "$BW_SERVER"
  fi
  # Log in once, interactively, if a terminal is attached. Unlocking is done by
  # chezmoi itself (bitwarden.unlock = auto) or via an exported BW_SESSION.
  if [ -t 0 ]; then
    echo "Logging in to Bitwarden..." >&2
    bw login
  fi
elif [ "$server" != "$BW_SERVER" ]; then
  echo "Warning: bw is logged in to ${server:-the default server}, not $BW_SERVER. Run 'bw logout' and re-run chezmoi to switch." >&2
fi
