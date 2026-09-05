#!/bin/bash
# Compare the version pins in .chezmoidata/packages.yaml with the latest
# upstream releases and, unless --check is given, rewrite the outdated ones.
# Usage: update-versions.sh [--check]
#   --check  report only; exit 1 when any pin is outdated
# Needs curl and jq. Export GITHUB_TOKEN to lift the anonymous API rate limit.
set -euo pipefail

cd "$(dirname "$0")/../.."
FILE=.chezmoidata/packages.yaml

check_only=false
case "${1:-}" in
  --check) check_only=true ;;
  "") ;;
  *) echo "Usage: $0 [--check]" >&2; exit 2 ;;
esac

# yaml key | source | transform. Keys must be unique in $FILE.
# Sources: github:<owner>/<repo> (latest release tag) or k8s-stable (dl.k8s.io).
# Transform strip-v removes the leading v where the pin is used in file names.
SOURCES=(
  "nerd_fonts_version|github:ryanoasis/nerd-fonts|"
  "kubectl|k8s-stable|"
  "helm|github:helm/helm|"
  "k9s|github:derailed/k9s|"
  "kubectx|github:ahmetb/kubectx|"
  "k3d|github:k3d-io/k3d|"
  "tilt|github:tilt-dev/tilt|strip-v"
  "dash_to_panel|github:home-sweet-gnome/dash-to-panel|"
  "tailscale_qs|github:tailscale-qs/tailscale-gnome-qs|"
)

auth=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
  auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

latest_version() {
  local source="$1" transform="$2" tag
  case "$source" in
    github:*)
      tag="$(curl -fsS "${auth[@]}" -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${source#github:}/releases/latest" | jq -r .tag_name)"
      ;;
    k8s-stable)
      tag="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
      ;;
    *) echo "Unknown source $source" >&2; return 1 ;;
  esac
  if [ -z "$tag" ] || [ "$tag" = "null" ]; then
    echo "No release found for $source" >&2
    return 1
  fi
  if [ "$transform" = "strip-v" ]; then
    tag="${tag#v}"
  fi
  printf '%s\n' "$tag"
}

current_version() {
  local key="$1" matches
  matches="$(grep -cE "^\s*${key}: \"[^\"]+\"" "$FILE" || true)"
  if [ "$matches" -ne 1 ]; then
    echo "Expected exactly one '$key:' pin in $FILE, found $matches" >&2
    return 1
  fi
  sed -nE "s/^\s*${key}: \"([^\"]+)\".*/\1/p" "$FILE"
}

outdated=0
printf '%-20s %-12s %-12s\n' KEY CURRENT LATEST
for entry in "${SOURCES[@]}"; do
  IFS='|' read -r key source transform <<< "$entry"
  current="$(current_version "$key")"
  latest="$(latest_version "$source" "$transform")"
  if [ "$current" = "$latest" ]; then
    printf '%-20s %-12s %-12s\n' "$key" "$current" "$latest"
    continue
  fi
  outdated=$((outdated + 1))
  printf '%-20s %-12s %-12s  <- outdated\n' "$key" "$current" "$latest"
  if [ "$check_only" = false ]; then
    sed -i -E "s|^(\s*${key}: )\"[^\"]+\"|\1\"${latest}\"|" "$FILE"
  fi
done

if [ "$outdated" -eq 0 ]; then
  echo "All pins are current."
elif [ "$check_only" = true ]; then
  echo "$outdated pin(s) outdated. Run without --check to update $FILE." >&2
  exit 1
else
  echo "Updated $outdated pin(s) in $FILE. Review with git diff, then run chezmoi apply."
fi
