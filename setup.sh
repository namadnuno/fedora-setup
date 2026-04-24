#!/bin/bash

set -e

log() { echo ""; echo ">>> $1"; }

log "🚀 Iniciando o setup do Fedora para Web Dev..."

# 1. Atualizar o sistema
log "[1/12] Atualizando o sistema..."
sudo dnf upgrade -y

# 2. Instalar ferramentas essenciais de build e utilitários
log "[2/12] Instalando ferramentas essenciais..."
sudo dnf install -y \
  gcc gcc-c++ make \
  curl wget git \
  fastfetch zsh fish util-linux-user \
  ghostty fzf \
  ripgrep fd-find bat eza git-delta jq \
  neovim lazygit

# 3. Adicionar repositório do VS Code e instalar
log "[3/12] Instalando VS Code..."
if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
fi
sudo dnf install -y code

# 4. Instalar Docker
log "[4/12] Instalando Docker..."
sudo dnf install -y docker-cli containerd docker-compose docker-compose-switch
sudo systemctl enable --now docker

# 5. Instalar FNM (Fast Node Manager)
log "[5/12] Instalando FNM..."
export PATH="$HOME/.local/share/fnm:$PATH"
if ! command -v fnm &>/dev/null; then
  curl -fsSL https://fnm.vercel.app/install | bash
fi
#eval "$(fnm env)"

# 6. Instalar Node.js (LTS) e o Claude Code
log "[6/12] Instalando Node.js LTS e Claude Code..."
if ! fnm list | grep -q "lts"; then
  fnm install --lts
fi
fnm use lts-latest

if ! command -v claude &>/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# 7. Instalar Brave Browser
log "[7/12] Instalando Brave Browser..."
sudo dnf install -y fedora-workstation-repositories
if ! command -v brave-browser &>/dev/null; then
  curl -fsS https://dl.brave.com/install.sh | sh
fi

# 8. Set fish as default shell
log "[8/12] Configurando Fish como shell padrão..."
FISH_PATH="$(which fish)"
if [ "$SHELL" != "$FISH_PATH" ]; then
  grep -qxF "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells
  chsh -s "$FISH_PATH"
fi

# 9. Fisher + Fish plugins
log "[9/12] Instalando Fisher e plugins do Fish..."
if ! fish -c "type -q fisher" &>/dev/null; then
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

# fisher install is idempotent — skips already-installed plugins
fish -c "fisher install \
  PatrickF1/fzf.fish \
  jethrokuan/z \
  jorgebucaran/autopair.fish \
  meaningful-ooo/sponge \
  franciscolourenco/done \
  jorgebucaran/hydro"

# 10. Instalar lazydocker
log "[10/12] Instalando lazydocker..."
if ! command -v lazydocker &>/dev/null; then
  LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz" -o /tmp/lazydocker.tar.gz
  tar xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
  sudo install /tmp/lazydocker /usr/local/bin/lazydocker
  rm /tmp/lazydocker.tar.gz /tmp/lazydocker
fi

# 11. Instalar LazyVim
log "[11/12] Instalando LazyVim..."
if [ ! -d "$HOME/.config/nvim" ]; then
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
fi

# 12. KDE configuration
log "[12/12] Configurando KDE (atalhos e teclado)..."
if command -v kwriteconfig6 &>/dev/null; then
  KWRITE="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
  KWRITE="kwriteconfig5"
else
  echo "kwriteconfig not found, skipping KDE config"
  KWRITE=""
fi

if [ -n "$KWRITE" ]; then
  # Ctrl+Alt+T → Ghostty (remove from Konsole, assign to Ghostty)
  $KWRITE --file kglobalshortcutsrc --group "org.kde.konsole.desktop" --key "_launch" "none,Ctrl+Alt+T,Konsole"
  $KWRITE --file kglobalshortcutsrc --group "com.mitchellh.ghostty.desktop" --key "_launch" "Ctrl+Alt+T,none,Ghostty"

  # Caps Lock as Escape
  $KWRITE --file kxkbrc --group Layout --key Options "caps:escape"
fi

# Setup Git profile
log "Configurando Git..."
git config --global user.name "Nuno Alexandre"
git config --global user.email "nunnomalex@gmail.com"

log "✅ Setup concluído! Por favor, reinicia o PC para aplicar as permissões do Docker."
