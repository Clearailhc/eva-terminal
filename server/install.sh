#!/usr/bin/env bash
# Install the EVA-02 GPU-server theme on a remote host over ssh. Idempotent; no root needed.
#   server/install.sh user@host                    # display name = the host's short hostname
#   EVA02_NAME=h100 server/install.sh user@host     # or pick a short name for banner / prompt / tmux
set -euo pipefail
HOST=${1:?usage: server/install.sh user@host}
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

ssh "$HOST" 'mkdir -p ~/.local/bin ~/.local/share/eva02 ~/.config'
scp -q "$ROOT/bin/eva02" "$HOST":.local/bin/eva02
scp -q "$ROOT"/share/eva02/avatar-*.ans "$HOST":.local/share/eva02/
scp -q "$ROOT"/server/starship.toml "$ROOT"/server/tmux.conf "$ROOT"/server/bashrc.snippet "$HOST":.local/share/eva02/

ssh "$HOST" "EVA02_NAME='${EVA02_NAME:-}' bash -s" <<'REMOTE'
set -euo pipefail
S=~/.local/share/eva02
chmod +x ~/.local/bin/eva02
ts=$(date +%Y%m%d-%H%M%S)

if ! command -v starship >/dev/null && [[ ! -x ~/.local/bin/starship ]]; then
  echo "· downloading starship"
  arch=$(uname -m); [[ $arch == arm64 ]] && arch=aarch64
  curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-$arch-unknown-linux-musl.tar.gz" \
    | tar -xz -C ~/.local/bin starship
fi

for f in starship.toml:.config/starship.toml tmux.conf:.tmux.conf; do
  src=$S/${f%%:*} dst=~/${f#*:}
  if [[ -f $dst ]] && ! cmp -s "$src" "$dst"; then cp "$dst" "$dst.bak.$ts"; fi
  cp "$src" "$dst"
done
tmux source-file ~/.tmux.conf 2>/dev/null || true

name=${EVA02_NAME:-$(hostname -s)}
cp ~/.bashrc ~/.bashrc.bak.$ts
sed -i '/^# >>> eva02 >>>$/,/^# <<< eva02 <<<$/d' ~/.bashrc
sed "s/__EVA02_NAME__/$name/" $S/bashrc.snippet >> ~/.bashrc
echo "· installed as '$name' (bashrc backup: ~/.bashrc.bak.$ts)"
REMOTE
