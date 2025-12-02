# ubuntu-kit

A modern Ubuntu CLI toolkit — install essential dev tools and utilities in one command.

Perfect for setting up new Ubuntu servers, VM instances, or fresh installations with modern CLI tools.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/takashito/ubuntu-kit/main/install.sh | sudo bash
```

## What Gets Installed

### Modern CLI Tools

| Tool | Replaces | Description |
|------|----------|-------------|
| **eza** | `ls` | Modern ls with icons, git integration |
| **bat** | `cat` | Syntax highlighting, git integration |
| **ripgrep** (rg) | `grep` | Faster, smarter search |
| **fd** | `find` | Simpler, faster file finding |
| **fzf** | - | Fuzzy finder for files and history |
| **zoxide** | `cd` | Smarter directory jumping |
| **yazi** | - | Terminal file manager |
| **glow** | - | Markdown renderer |
| **httpie** | `curl` | User-friendly HTTP client |
| **jq** | - | JSON processor |
| **ncdu** | `du` | Interactive disk usage |
| **btop** | `top`/`htop` | Beautiful system monitor |
| **tldr** | `man` | Simplified man pages |

### Shell Enhancements

- **bash-completion** - Tab completion for commands
- **fzf integration** - Ctrl+R for history, Ctrl+T for files
- **fzf-tab** - Fuzzy tab completion for cd/z
- **History settings** - No duplicates, append mode

### Docker Shortcuts

Run `dhelp` to see the full cheat sheet. Highlights:

```bash
dcp           # docker compose up -d + logs
dcd           # docker compose down
dps           # docker ps
dbash <c>     # exec -it /bin/bash
dsh <c>       # exec -it /bin/sh
dlgf <c>      # docker logs -f
```

## Aliases & Commands

### File Navigation

```bash
ls            # eza --color=auto
ll            # eza -alh
la            # eza -al
lt            # eza --tree
cd <dir>      # zoxide + auto-list
z <partial>   # Jump to frecent directory
y             # yazi file manager (cd on exit)
```

### Modern Replacements

```bash
cat file.py   # bat with syntax highlighting
grep pattern  # ripgrep
find name     # fd
```

### Utilities

```bash
h GET url     # httpie
glow file.md  # Render markdown
Ctrl+R        # Fuzzy search history
Ctrl+T        # Fuzzy search files
```

## Features

- **Smart defaults** - Pre-configured with sensible settings
- **Shell integration** - FZF keybindings, zoxide, aliases
- **Safe** - Backs up your `.bashrc` before modifying
- **Remote-friendly** - Designed for server/cloud setup
- **Idempotent** - Safe to run multiple times

## Requirements

- Ubuntu 20.04, 22.04, or 24.04 LTS
- Root/sudo access
- Internet connection

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/takashito/ubuntu-kit/main/uninstall.sh | sudo bash
```

Or run locally:

```bash
sudo ./uninstall.sh
```

## Security

Always inspect scripts before running them:

```bash
curl -fsSL https://raw.githubusercontent.com/takashito/ubuntu-kit/main/install.sh | less
```

## License

MIT License - see LICENSE file for details.
