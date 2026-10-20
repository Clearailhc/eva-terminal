#!/usr/bin/env bash
# Install the EVA-00 local theme for the current user (zsh or bash). Idempotent; no root needed.
#   local/install.sh            # adds the banner to the rc file of your login shell
#   local/install.sh ~/.bashrc  # or name the rc file explicitly
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-$(basename "${SHELL:-bash}")}" in
  zsh) RC=~/.zshrc ;; bash) RC=~/.bashrc ;; *) RC=$1 ;;
esac

mkdir -p ~/.local/bin ~/.local/share/eva00
install -m755 "$ROOT/bin/eva02" "$ROOT/bin/eva00" ~/.local/bin/   # eva00 runs on the eva02 engine
cp "$ROOT"/share/eva00/avatar-*.ans ~/.local/share/eva00/

touch "$RC"
cp "$RC" "$RC.bak.$(date +%Y%m%d-%H%M%S)"
sed -i '/^# >>> eva00 >>>$/,/^# <<< eva00 <<<$/d' "$RC"
cat "$ROOT/local/shell.snippet" >> "$RC"
echo "· installed into $RC — open a new terminal, or run: eva"
