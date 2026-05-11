#!/bin/bash

set -e

log() { echo ""; echo ">>> $1"; }

log "🖥️  XFCE Setup — rofi + dark theme + keybindings"

# 1. Install rofi
log "[1/3] Installing rofi..."
if ! command -v rofi &>/dev/null; then
  sudo dnf install -y rofi
else
  echo "rofi already installed"
fi

# 2. Dark theme
log "[2/3] Applying dark theme..."

# GTK theme (Adwaita-dark is always available on Fedora)
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark" 2>/dev/null || \
  xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "Adwaita-dark"

# Icon theme
xfconf-query -c xsettings -p /Net/IconThemeName -s "Adwaita" 2>/dev/null || \
  xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "Adwaita"

# Window manager theme
xfconf-query -c xfwm4 -p /general/theme -s "Default-hdpi" 2>/dev/null || true

# Tell GTK apps to prefer dark
xfconf-query -c xsettings -p /Gtk/ApplicationPreferDarkTheme -s 1 2>/dev/null || \
  xfconf-query -c xsettings -p /Gtk/ApplicationPreferDarkTheme -n -t int -s 1

# 3. Keyboard shortcuts
log "[3/3] Setting keyboard shortcuts..."

# Ctrl+Alt+T → ghostty
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Alt>t" -s "ghostty" 2>/dev/null || \
  xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Alt>t" -n -t string -s "ghostty"

xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Primary><Alt>t" -s "ghostty" 2>/dev/null || \
  xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Primary><Alt>t" -n -t string -s "ghostty"

# Super+Space → rofi
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>space" -s "rofi -show drun" 2>/dev/null || \
  xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>space" -n -t string -s "rofi -show drun"

log "✅ XFCE setup done. Log out and back in for theme to fully apply."
