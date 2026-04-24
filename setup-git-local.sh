#!/bin/bash

set -e

log() { echo ""; echo ">>> $1"; }

log "🔑 Configurando chave SSH e integração com KDE Wallet..."

# ── 1. Instalar ksshaskpass ───────────────────────────────────────────────────
log "[1/4] Instalando ksshaskpass..."
sudo dnf install -y ksshaskpass

# ── 2. Gerar chave SSH ed25519 (se não existir) ───────────────────────────────
log "[2/4] Verificando chave SSH..."
SSH_KEY="$HOME/.ssh/id_ed25519"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$SSH_KEY" ]; then
  echo ""
  echo "  Nenhuma chave encontrada — a gerar ed25519."
  echo "  Define uma senha forte quando pedido (o KWallet vai guardá-la)."
  echo ""
  ssh-keygen -t ed25519 -C "nunnomalex@gmail.com" -f "$SSH_KEY"
  chmod 600 "$SSH_KEY"
  echo "✓ Chave gerada em $SSH_KEY"
else
  echo "✓ Chave já existe em $SSH_KEY — a saltar geração."
fi

# ── 3. Systemd user ssh-agent + variáveis de ambiente ────────────────────────
log "[3/4] Ativando ssh-agent via systemd e configurando ambiente KDE..."

# Activate the persistent systemd user socket for ssh-agent
systemctl --user enable --now ssh-agent \
  && echo "✓ ssh-agent ativado via systemd" \
  || echo "⚠  Não foi possível ativar o ssh-agent via systemd — continua na mesma."

# KDE sources every *.sh script inside this directory at session start,
# BEFORE any app or autostart entry runs. This is the right place to set
# SSH_ASKPASS and SSH_AUTH_SOCK so VS Code, terminal emulators, and git GUIs
# all inherit them without any extra config.
mkdir -p "$HOME/.config/plasma-workspace/env"
cat > "$HOME/.config/plasma-workspace/env/ssh-agent.sh" << 'EOF'
#!/bin/sh
# SSH agent — sourced by KDE Plasma at session startup
export SSH_ASKPASS=/usr/bin/ksshaskpass
export SSH_ASKPASS_REQUIRE=prefer
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
EOF
chmod +x "$HOME/.config/plasma-workspace/env/ssh-agent.sh"
echo "✓ Ambiente KDE configurado em ~/.config/plasma-workspace/env/ssh-agent.sh"

# Also wire SSH_AUTH_SOCK into fish config so terminal sessions see the agent
FISH_CONFIG="$HOME/.config/fish/config.fish"
mkdir -p "$HOME/.config/fish"
if ! grep -q "SSH_AUTH_SOCK" "$FISH_CONFIG" 2>/dev/null; then
  printf '\n# SSH agent socket — systemd user ssh-agent\nset -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket\n' >> "$FISH_CONFIG"
  echo "✓ SSH_AUTH_SOCK adicionado ao config.fish"
else
  echo "✓ SSH_AUTH_SOCK já está no config.fish — a saltar."
fi

# ── 4. Adicionar chave ao agente via ksshaskpass → KWallet ───────────────────
log "[4/4] Adicionando chave ao agente — o KWallet vai pedir a senha uma única vez..."

export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
export SSH_ASKPASS=/usr/bin/ksshaskpass
export SSH_ASKPASS_REQUIRE=prefer

# ssh-add with </dev/null forces it to use SSH_ASKPASS instead of the terminal,
# which triggers the ksshaskpass GUI → KWallet stores the passphrase permanently.
if ssh-add "$SSH_KEY" </dev/null; then
  echo "✓ Chave adicionada ao agente — passphrase guardada no KWallet para sempre."
else
  echo ""
  echo "⚠  A janela do KWallet não apareceu (sessão gráfica KDE não está ativa?)."
  echo "   Corre manualmente após fazer login no KDE:"
  echo ""
  echo "     SSH_ASKPASS=/usr/bin/ksshaskpass ssh-add ~/.ssh/id_ed25519 </dev/null"
  echo ""
fi

# ── Chave pública para o GitHub ───────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════════"
echo "  Adiciona esta chave pública ao GitHub:"
echo "  https://github.com/settings/ssh/new"
echo "══════════════════════════════════════════════════════════════════"
cat "${SSH_KEY}.pub"
echo "══════════════════════════════════════════════════════════════════"
