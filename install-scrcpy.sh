#!/bin/bash

set -e

log() { echo ""; echo ">>> $1"; }

log "Installing scrcpy (Android screen mirror/control)..."

INSTALL_BIN="/usr/local/bin"
INSTALL_ICONS="/usr/local/share/icons/hicolor/256x256/apps"
INSTALL_MAN="/usr/local/share/man/man1"
INSTALL_DESKTOP="/usr/local/share/applications"
TMP_DIR="/tmp/scrcpy-install"

# Fetch latest release tag from GitHub
log "Fetching latest scrcpy release..."
LATEST=$(curl -s "https://api.github.com/repos/Genymobile/scrcpy/releases/latest" | grep -Po '"tag_name": "\Kv[^"]*')
VERSION="${LATEST#v}"
ARCHIVE="scrcpy-linux-x86_64-v${VERSION}.tar.gz"
URL="https://github.com/Genymobile/scrcpy/releases/download/${LATEST}/${ARCHIVE}"

log "Downloading scrcpy v${VERSION}..."
mkdir -p "$TMP_DIR"
curl -fsSL "$URL" -o "$TMP_DIR/$ARCHIVE"
tar -xzf "$TMP_DIR/$ARCHIVE" -C "$TMP_DIR"

EXTRACTED="$TMP_DIR/scrcpy-linux-x86_64-v${VERSION}"

log "Installing binaries..."
sudo install -m 755 "$EXTRACTED/scrcpy" "$INSTALL_BIN/scrcpy"
sudo install -m 755 "$EXTRACTED/adb"    "$INSTALL_BIN/adb"

log "Installing scrcpy server..."
sudo install -m 644 "$EXTRACTED/scrcpy-server" "$INSTALL_BIN/scrcpy-server"

log "Installing man page..."
sudo mkdir -p "$INSTALL_MAN"
sudo install -m 644 "$EXTRACTED/scrcpy.1" "$INSTALL_MAN/scrcpy.1"

log "Installing icon..."
sudo mkdir -p "$INSTALL_ICONS"
sudo install -m 644 "$EXTRACTED/icon.png" "$INSTALL_ICONS/scrcpy.png"

log "Creating .desktop launcher..."
sudo tee "$INSTALL_DESKTOP/scrcpy.desktop" > /dev/null << 'EOF'
[Desktop Entry]
Name=scrcpy
Comment=Display and control Android device over USB or TCP/IP
Exec=scrcpy
Icon=scrcpy
Terminal=false
Type=Application
Categories=Utility;
EOF

log "Refreshing icon and desktop caches..."
sudo gtk-update-icon-cache "$INSTALL_ICONS/../../../" 2>/dev/null || true
sudo update-desktop-database "$INSTALL_DESKTOP" 2>/dev/null || true

log "Cleaning up..."
rm -rf "$TMP_DIR"

log "Done! scrcpy $(scrcpy --version 2>&1 | head -1) installed."
echo ""
echo "Usage:"
echo "  1. Enable USB Debugging on Android (Settings > Developer Options)"
echo "  2. Connect device via USB"
echo "  3. Run: scrcpy"
echo "  4. Or wirelessly: scrcpy --tcpip=<device-ip>"
