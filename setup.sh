#!/bin/bash

echo "🚀 Iniciando o setup do Fedora para Web Dev..."

# 1. Atualizar o sistema
sudo dnf upgrade -y

# 2. Instalar ferramentas essenciais de build e utilitários
sudo dnf groupinstall "Development Tools" -y
sudo dnf install -y curl wget git fastfetch zsh util-linux-user

# 3. Adicionar repositório do VS Code e instalar
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code

# 4. Instalar Docker
sudo dnf install docker-cli containerd
sudo dnf install docker-compose
sudo dnf install docker-compose-switch
sudo systemctl enable --now docker

# 5. Instalar FNM (Fast Node Manager) - Melhor que NVM para performance
curl -fsSL https://fnm.vercel.app/install | bash
# Ativar FNM temporariamente para a sessão atual do script
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env)"

# 6. Instalar Node.js (LTS) e o Claude Code
fnm install --lts
curl -fsSL https://claude.ai/install.sh | bash

# 7. Instalar o Google Chrome (Essencial para Dev)
sudo dnf install -y fedora-workstation-repositories
curl -fsS https://dl.brave.com/install.sh | sh

# Setup Git profile
git config --global user.name "Nuno Alexandre"
git config --global user.email "nunnomalex@gmail.com"

echo "✅ Setup concluído! Por favor, reinicia o PC para aplicar as permissões do Docker."
