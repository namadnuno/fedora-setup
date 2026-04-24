# Fedora Dev Setup

One-shot script to bootstrap a web dev environment on Fedora.

## What it installs

| Tool | Purpose |
|------|---------|
| Development Tools (group) | gcc, make, etc. |
| curl, wget, git | essentials |
| fastfetch | system info |
| zsh | shell |
| VS Code | editor |
| Docker + Compose | containers |
| FNM + Node.js LTS | Node version manager |
| Claude Code | AI coding assistant |
| Brave Browser | browser |

## Usage

```bash
chmod +x setup.sh
./setup.sh
```

Reboot after — required for Docker group permissions to apply.

## Post-install

- Configure zsh (e.g. install oh-my-zsh, set as default shell via `chsh`)
- Add FNM to your shell profile (`~/.zshrc` or `~/.bashrc`):
  ```bash
  eval "$(fnm env --use-on-cd)"
  ```
- Log into VS Code extensions, Claude Code, etc.
- Verify Docker works without sudo: `docker run hello-world`

## Notes

- Git is pre-configured for `Nuno Alexandre <nunnomalex@gmail.com>`
- FNM chosen over NVM for performance
- Brave installed via official install script
