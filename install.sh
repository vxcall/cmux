#!/bin/sh
# mux installer — run via: curl -fsSL <url> | sh
set -e

RELEASE_URL="https://github.com/craigsc/cmux/releases/latest/download"

INSTALL_DIR="$HOME/.mux"
INSTALL_PATH="$INSTALL_DIR/mux.sh"

# Download
mkdir -p "$INSTALL_DIR"
echo "Downloading mux..."
curl -fsSL "$RELEASE_URL/mux.sh" -o "$INSTALL_PATH"
curl -fsSL "$RELEASE_URL/VERSION" | tr -d '[:space:]' > "$INSTALL_DIR/VERSION"

# Clear stale update-check cache from any previous install
rm -f "$INSTALL_DIR/.latest_version" "$INSTALL_DIR/.last_check"

# Detect shell rc file
case "$SHELL" in
  */zsh)  RC_FILE="$HOME/.zshrc" ;;
  *)      RC_FILE="$HOME/.bashrc" ;;
esac

SOURCE_LINE='source "$HOME/.mux/mux.sh"'

# Idempotently add source line
if ! grep -qF '.mux/mux.sh' "$RC_FILE" 2>/dev/null; then
  printf '\n# mux\n%s\n' "$SOURCE_LINE" >> "$RC_FILE"
  echo "Added source line to $RC_FILE"
else
  echo "Source line already in $RC_FILE"
fi

echo ""
echo "mux installed! To start using it:"
echo "  source $RC_FILE"
