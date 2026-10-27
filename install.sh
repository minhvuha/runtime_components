#!/usr/bin/env bash

set -eu
FILES=".bashrc .zshrc .vimrc .gdbinit"
OMZ_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

DRY_RUN=0
INSTALL_OMZ=1
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=1 ;;
    --no-omz)     INSTALL_OMZ=0 ;;
    -h|--help)    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)            echo "unknown option: $arg  (try --help)" >&2; exit 1 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "$0")" && pwd -P)"
STAMP="$(date +%Y%m%d-%H%M%S)"

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "          would run: $*"
  else
    "$@"
  fi
}

install_file() {
  local src="$REPO_DIR/$1"
  local dest="$HOME/$1"
  if [ ! -e "$src" ]; then
    echo "skip      .$1  (no $1 in this repo)"
    return
  fi
  if [ -f "$dest" ] && [ ! -L "$dest" ] && cmp -s "$src" "$dest"; then
    echo "ok        .$1"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local bak="$dest.backup-$STAMP"
    n=1
    while [ -e "$bak" ] || [ -L "$bak" ]; do
      bak="$dest.backup-$STAMP-$n"; n=$((n + 1))
    done
    echo "backup    .$1  ->  ${bak##*/}"
    run mv "$dest" "$bak"
  fi
  echo "copy      $1  ->  ~/$1"
  run cp "$src" "$dest"
}

setup_gitconfig() {
  local src="$REPO_DIR/.gitconfig"
  local dest="$HOME/.gitconfig.rc"
  if [ ! -e "$src" ]; then
    echo "skip      gitconfig  (no gitconfig in this repo)"
    return
  fi
  if git config -f "$src" --get user.name >/dev/null 2>&1 || git config -f "$src" --get user.email >/dev/null 2>&1; then
    echo "WARNING   $src has a [user] section."
    return
  fi
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    echo "ok        .gitconfig.rc"
  else
    echo "copy      .gitconfig  ->  ~/.gitconfig.rc"
    run cp "$src" "$dest"
  fi
  if git config --global --get-all include.path 2>/dev/null | grep -qxF "$dest"; then
    echo "ok        .gitconfig.rc  (already included)"
  else
    echo "include   .gitconfig.rc  (added to ~/.gitconfig)"
    run git config --global --add include.path "$dest"
  fi
}

for f in $FILES; do
  install_file "$f"
done
setup_gitconfig

# Install cowsay into ~/.local (no root needed)
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
git clone https://github.com/cowsay-org/cowsay.git
cd cowsay
make install prefix=$HOME/.local

# Add the train cow used by boilersay (site-cows is on cowsay's default path)
mkdir -p "$HOME/.local/share/cowsay/site-cows"
cp "$DOTFILES_DIR/train.cow" "$HOME/.local/share/cowsay/site-cows/"
