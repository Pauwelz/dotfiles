#!/bin/bash
# Render every chezmoi script template with the current config and lint it.
# Usage: lint-scripts.sh [script-prefix-expected-empty ...]
# Prefixes (e.g. "20" or "run_once_before_20") name scripts that must render to
# nothing for the current prompt answers; every other script is shellchecked.
set -euo pipefail

expected_empty=("$@")
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

is_expected_empty() {
  local base="$1" p
  for p in "${expected_empty[@]}"; do
    case "$base" in
      "$p"*|run_*_"$p"-*|run_*_before_"$p"-*|run_*_after_"$p"-*) return 0 ;;
    esac
  done
  return 1
}

for f in .chezmoiscripts/*.tmpl; do
  base="$(basename "$f")"
  chezmoi execute-template < "$f" > "$tmp"
  size="$(wc -c < "$tmp")"
  if is_expected_empty "$base"; then
    if [ "$size" -ne 0 ]; then
      echo "FAIL: $base should render empty but has $size bytes" >&2
      cat "$tmp"
      exit 1
    fi
    echo "== $base: empty (expected)"
  else
    if [ "$size" -eq 0 ]; then
      echo "FAIL: $base rendered empty but was expected to have content" >&2
      exit 1
    fi
    echo "== $base"
    shellcheck -s bash "$tmp"
    bash -n "$tmp"
  fi
done

echo "== .chezmoiexternal.toml.tmpl"
chezmoi execute-template < .chezmoiexternal.toml.tmpl
