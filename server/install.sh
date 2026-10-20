#!/usr/bin/env bash
# Install the GPU-server theme on a remote host over ssh. Idempotent; no root needed.
#   server/install.sh user@host                              # unit EVA-02, name = short hostname
#   EVA_UNIT=01 EVA02_NAME=h100 server/install.sh user@host  # pick a unit and a short display name
set -euo pipefail
HOST=${1:?usage: server/install.sh user@host}
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UNIT=${EVA_UNIT:-02}

ssh "$HOST" 'mkdir -p ~/.local/bin ~/.local/share/eva02 ~/.local/share/eva-terminal ~/.config'
scp -q "$ROOT/bin/eva02" "$HOST":.local/bin/eva02
scp -qr "$ROOT/share/units" "$HOST":.local/share/eva-terminal/
scp -q "$ROOT"/server/starship.toml "$ROOT"/server/tmux.conf "$ROOT"/server/bashrc.snippet "$HOST":.local/share/eva02/

ssh "$HOST" "EVA02_NAME='${EVA02_NAME:-}' UNIT='$UNIT' bash -s" <<'REMOTE'
set -euo pipefail
S=~/.local/share/eva02
chmod +x ~/.local/bin/eva02
rm -f $S/avatar-*.ans $S/asuka-*.ans   # avatars now live in ~/.local/share/eva-terminal/units/<unit>/
ts=$(date +%Y%m%d-%H%M%S)

if ! command -v starship >/dev/null && [[ ! -x ~/.local/bin/starship ]]; then
  echo "· downloading starship"
  arch=$(uname -m); [[ $arch == arm64 ]] && arch=aarch64
  curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-$arch-unknown-linux-musl.tar.gz" \
    | tar -xz -C ~/.local/bin starship
fi

# configs are templates: fill in the unit's colours, back up anything different that was there
for f in starship.toml:.config/starship.toml tmux.conf:.tmux.conf; do
  src=$S/${f%%:*} dst=~/${f#*:}
  EVA_UNIT=$UNIT ~/.local/bin/eva02 template < "$src" > "$src.out"
  if [[ -f $dst ]] && ! cmp -s "$src.out" "$dst"; then cp "$dst" "$dst.bak.$ts"; fi
  mv "$src.out" "$dst"
done
tmux source-file ~/.tmux.conf 2>/dev/null || true

name=${EVA02_NAME:-$(hostname -s)}
cp ~/.bashrc ~/.bashrc.bak.$ts
sed -i '/^# >>> eva02 >>>$/,/^# <<< eva02 <<<$/d' ~/.bashrc
sed -e "s/__EVA02_NAME__/$name/" -e "s/__EVA_UNIT__/$UNIT/" $S/bashrc.snippet >> ~/.bashrc
echo "· installed unit $UNIT as '$name' (bashrc backup: ~/.bashrc.bak.$ts)"
REMOTE
