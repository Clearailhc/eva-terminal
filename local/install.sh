#!/usr/bin/env bash
# Install the local (NERV) theme for the current user (zsh or bash). Idempotent; no root needed.
#   local/install.sh                 # unit EVA-00, into the rc file of your login shell
#   EVA_UNIT=01 local/install.sh     # pick a unit (see: bin/eva02 units)
#   local/install.sh ~/.bashrc       # or name the rc file explicitly
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UNIT=${EVA_UNIT:-00}
case "${1:-$(basename "${SHELL:-bash}")}" in
  zsh) RC=~/.zshrc ;; bash) RC=~/.bashrc ;; *) RC=$1 ;;
esac

mkdir -p ~/.local/bin ~/.local/share/eva-terminal
install -m755 "$ROOT/bin/eva02" "$ROOT/bin/eva00" ~/.local/bin/   # eva00 runs on the eva02 engine
cp -r "$ROOT/share/units" ~/.local/share/eva-terminal/
rm -rf ~/.local/share/eva00   # avatars used to live here

touch "$RC"
cp "$RC" "$RC.bak.$(date +%Y%m%d-%H%M%S)"
sed -i '/^# >>> eva00 >>>$/,/^# <<< eva00 <<<$/d' "$RC"
sed "s/__EVA_UNIT__/$UNIT/" "$ROOT/local/shell.snippet" >> "$RC"
echo "· installed unit $UNIT into $RC — open a new terminal, or run: eva"
