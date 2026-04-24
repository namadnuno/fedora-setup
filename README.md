# Fedora Dev Setup

One-shot script to bootstrap a web dev environment on Fedora KDE.

## What it installs

| Tool | Purpose |
|------|---------|
| gcc, gcc-c++, make | build essentials |
| curl, wget, git | essentials |
| fastfetch | system info |
| fish | default shell |
| ghostty | terminal emulator |
| fzf | fuzzy finder (required by fzf.fish) |
| VS Code | editor |
| Docker + Compose | containers |
| FNM + Node.js LTS | Node version manager |
| Claude Code | AI coding assistant |
| Brave Browser | browser |

### Fish plugins (via Fisher)

| Plugin | Purpose |
|--------|---------|
| `PatrickF1/fzf.fish` | Fuzzy search history, files and processes (`Ctrl+R`, `Ctrl+F`) |
| `jethrokuan/z` | Jump to frecent directories (`z foo` instead of `cd /long/path`) |
| `jorgebucaran/autopair.fish` | Auto-close brackets, quotes and braces while typing |
| `meaningful-ooo/sponge` | Removes failed commands from history |
| `franciscolourenco/done` | Desktop notification when a long-running command finishes |
| `jorgebucaran/hydro` | Minimal async prompt with git status and Node version |

## KDE configuration

- `Ctrl+Alt+T` → launches Ghostty (removed from Konsole)
- Caps Lock remapped to Escape

Takes effect on next login.

## Usage

```bash
chmod +x setup.sh
./setup.sh
```

Reboot after — required for Docker group permissions and shell change to apply.

## Post-install

- Log into VS Code extensions, Claude Code, etc.
- Verify Docker works without sudo: `docker run hello-world`
- Verify Ghostty shortcut: `Ctrl+Alt+T`
- FNM is auto-configured for fish via `fnm env`

## Notes

- Git pre-configured for `Nuno Alexandre <nunnomalex@gmail.com>`
- FNM chosen over NVM for performance
- Brave installed via official install script
- Script is idempotent — safe to re-run
