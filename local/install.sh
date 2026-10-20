#!/usr/bin/env bash
# Install the local (NERV) theme for the current user (zsh or bash). Idempotent; no root needed.
#   local/install.sh                 # into the rc file of your login shell (unit: EVA-00, or your saved choice)
#   EVA_UNIT=01 local/install.sh     # also switch unit (same as running `eva-unit 01` afterwards)
#   local/install.sh ~/.bashrc       # or name the rc file explicitly
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
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
cat "$ROOT/local/shell.snippet" >> "$RC"
if [[ -n ${EVA_UNIT:-} ]]; then EVA_UNIT= ~/.local/bin/eva02 use "$EVA_UNIT" >/dev/null; fi
echo "· installed into $RC — open a new terminal, or run: eva  (switch units: eva-unit)"
