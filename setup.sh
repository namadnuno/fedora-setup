#!/bin/bash

set -e

log() { echo ""; echo ">>> $1"; }

log "🚀 Iniciando o setup do Fedora para Web Dev..."

# 1. Atualizar o sistema
log "[1/13] Atualizando o sistema..."
sudo dnf upgrade -y

# 2. Instalar ferramentas essenciais de build e utilitários
log "[2/13] Instalando ferramentas essenciais..."
sudo dnf install -y \
  gcc gcc-c++ make \
  curl wget git \
  fastfetch zsh fish util-linux-user \
  ghostty fzf \
  ripgrep fd-find bat eza git-delta jq \
  neovim lazygit

# 3. Adicionar repositório do VS Code e instalar
log "[3/13] Instalando VS Code..."
if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
fi
sudo dnf install -y code

# 4. Instalar Docker
log "[4/13] Instalando Docker..."
sudo dnf install -y docker-cli containerd docker-compose docker-compose-switch
sudo systemctl enable --now docker

# 5. Instalar FNM (Fast Node Manager)
log "[5/13] Instalando FNM..."
export PATH="$HOME/.local/share/fnm:$PATH"
if ! command -v fnm &>/dev/null; then
  curl -fsSL https://fnm.vercel.app/install | bash
fi
#eval "$(fnm env)"

# 6. Instalar Node.js (LTS) e o Claude Code
log "[6/13] Instalando Node.js LTS e Claude Code..."
if ! fnm list | grep -q "lts"; then
  fnm install --lts
fi
fnm use lts-latest

if ! command -v claude &>/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# 7. Instalar Brave Browser
log "[7/13] Instalando Brave Browser..."
sudo dnf install -y fedora-workstation-repositories
if ! command -v brave-browser &>/dev/null; then
  curl -fsS https://dl.brave.com/install.sh | sh
fi

# 8. Set fish as default shell
log "[8/13] Configurando Fish como shell padrão..."
FISH_PATH="$(which fish)"
if [ "$SHELL" != "$FISH_PATH" ]; then
  grep -qxF "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells
  chsh -s "$FISH_PATH"
fi

# 9. Fisher + Fish plugins
log "[9/13] Instalando Fisher e plugins do Fish..."
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

# 10. Seed config.fish with PATH and tool initializations
log "[10/13] Configurando config.fish..."
FISH_CONFIG="$HOME/.config/fish/config.fish"
mkdir -p "$HOME/.config/fish"
if [ ! -f "$FISH_CONFIG" ]; then
  cat > "$FISH_CONFIG" << 'FISHEOF'
# ── Path additions ───────────────────────────────────────────────────────────

# User local binaries: claude, pip-installed tools, etc.
fish_add_path $HOME/.local/bin

# FNM — Fast Node Manager (node version switching + auto-switch per project)
fish_add_path $HOME/.local/share/fnm
fnm env --use-on-cd --shell fish | source
FISHEOF
  echo "config.fish criado em $FISH_CONFIG"
else
  echo "config.fish já existe — a adicionar entradas em falta..."
  if ! grep -q "\.local/bin" "$FISH_CONFIG"; then
    printf '\n# User local binaries: claude, pip-installed tools, etc.\nfish_add_path $HOME/.local/bin\n' >> "$FISH_CONFIG"
  fi
  if ! grep -q "fnm env" "$FISH_CONFIG"; then
    printf '\n# FNM — Fast Node Manager (node version switching + auto-switch per project)\nfish_add_path $HOME/.local/share/fnm\nfnm env --use-on-cd --shell fish | source\n' >> "$FISH_CONFIG"
  fi
fi

# 11. Instalar lazydocker
log "[11/13] Instalando lazydocker..."
if ! command -v lazydocker &>/dev/null; then
  LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz" -o /tmp/lazydocker.tar.gz
  tar xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
  sudo install /tmp/lazydocker /usr/local/bin/lazydocker
  rm /tmp/lazydocker.tar.gz /tmp/lazydocker
fi

# 12. Instalar LazyVim
log "[12/13] Instalando LazyVim..."
if [ ! -d "$HOME/.config/nvim" ]; then
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
fi

# 13. KDE configuration
log "[13/13] Configurando KDE (atalhos e teclado)..."
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
fi

# Setup Git profile
log "Configurando Git..."
git config --global user.name "Nuno Alexandre"
git config --global user.email "nunnomalex@gmail.com"

# SSH key + KDE KWallet integration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/setup-git-local.sh"

log "✅ Setup concluído! Por favor, reinicia o PC para aplicar as permissões do Docker."
```

Here's what was added/changed:

**New step 10 — seeds `~/.config/fish/config.fish` with:**

- `fish_add_path $HOME/.local/bin` — makes `claude` (and any other user-local binary) discoverable since the native Claude installer drops the binary at `~/.local/bin/claude`
- `fish_add_path $HOME/.local/share/fnm` — puts the `fnm` binary itself on the PATH
- `fnm env --use-on-cd --shell fish | source` — bootstraps FNM's fish integration and enables automatic version switching when you `cd` into a project with a `.node-version` or `.nvmrc` file

The step is **idempotent**: if `config.fish` already exists (e.g. you're re-running the script), it appends only the missing entries rather than overwriting the whole file. All other step numbers were bumped from a `/12` total to `/13`.
