#!/bin/bash
#
# ubuntu-kit - Modern Ubuntu CLI Toolkit
# Install essential dev tools and modern utilities in one command
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/takashito/ubuntu-kit/main/install.sh | bash
#   bash install.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Banner
echo -e "${BLUE}Installing modern CLI utilities...${NC}\n"

# Check if running on Ubuntu
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_warn "Detected $ID (not Ubuntu). Some packages may not be available."
    fi
fi

# Update package list
log_info "Updating package list..."
apt-get update -qq

# Install fundamental packages
log_info "Installing fundamental tools..."
apt-get install -y -qq \
    bat \
    httpie \
    fzf \
    ripgrep \
    fd-find \
    jq \
    ncdu \
    btop \
    git \
    curl \
    wget \
    unzip \
    tree \
    tldr \
    bash-completion

log_success "Package installation complete"

# Install eza (modern ls replacement)
log_info "Installing eza..."
if ! command -v eza &>/dev/null; then
    apt-get install -y -qq gpg
    mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    apt-get update -qq
    apt-get install -y -qq eza
    log_success "eza installed"
else
    log_info "eza already installed"
fi

# Install zoxide (smarter cd command)
log_info "Installing zoxide..."
if ! command -v zoxide &>/dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    log_success "zoxide installed"
else
    log_info "zoxide already installed"
fi

# Install glow (markdown renderer)
log_info "Installing glow..."
if ! command -v glow &>/dev/null; then
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
    apt-get update -qq
    apt-get install -y -qq glow
    log_success "glow installed"
else
    log_info "glow already installed"
fi

# Install yazi (terminal file manager)
log_info "Installing yazi..."
if ! command -v yazi &>/dev/null; then
    YAZI_VERSION=$(curl -sL https://api.github.com/repos/sxyazi/yazi/releases/latest | jq -r '.tag_name')
    curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip" -o /tmp/yazi.zip
    unzip -q /tmp/yazi.zip -d /tmp/yazi
    mv /tmp/yazi/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
    mv /tmp/yazi/yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/
    chmod +x /usr/local/bin/yazi /usr/local/bin/ya
    rm -rf /tmp/yazi /tmp/yazi.zip
    log_success "yazi installed"
else
    log_info "yazi already installed"
fi

# Create bat alias (Ubuntu names it batcat)
log_info "Creating symbolic links..."
if [ ! -f /usr/local/bin/bat ]; then
    ln -sf /usr/bin/batcat /usr/local/bin/bat
    log_success "bat -> batcat"
fi

# Create fd alias (Ubuntu names it fdfind)
if [ ! -f /usr/local/bin/fd ]; then
    ln -sf /usr/bin/fdfind /usr/local/bin/fd
    log_success "fd -> fdfind"
fi

# Determine which user's bashrc to modify
TARGET_USER="${SUDO_USER:-$USER}"
if [[ "$TARGET_USER" == "root" ]] || [[ -z "$TARGET_USER" ]]; then
    BASHRC="/root/.bashrc"
else
    BASHRC="/home/$TARGET_USER/.bashrc"
fi

log_info "Configuring shell for user: $TARGET_USER"

# Backup existing bashrc
if [[ -f "$BASHRC" ]]; then
    cp "$BASHRC" "${BASHRC}.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backed up existing .bashrc"
fi

# Check if already configured
if grep -q "ubuntu-kit" "$BASHRC" 2>/dev/null; then
    log_warn "ubuntu-kit configuration already exists in $BASHRC"
    log_warn "Remove existing config or restore from backup to reinstall"
else
    # Add shell integrations
    log_info "Adding shell integrations to $BASHRC..."
    cat >> "$BASHRC" << 'EOF'

# ============================================
# ubuntu-kit - Modern CLI Utilities
# ============================================

# Bash completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# zoxide - smarter cd
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# fzf - fuzzy finder key bindings and completion
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
[ -f /usr/share/doc/fzf/examples/completion.bash ] && source /usr/share/doc/fzf/examples/completion.bash

# fzf configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# fzf-tab: Use fzf for tab completion (bash)
# Override default completion with fzf
_fzf_complete_default() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local completions
    completions=$(compgen -f -- "$cur" 2>/dev/null)
    if [[ -n "$completions" ]]; then
        local selected
        selected=$(echo "$completions" | fzf --height 40% --reverse --border)
        if [[ -n "$selected" ]]; then
            COMPREPLY=("$selected")
        fi
    fi
}

# Enhanced completion for common commands using fzf
_fzf_complete_cd() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local dirs
    dirs=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | head -500)
    if [[ -n "$dirs" ]]; then
        local selected
        selected=$(echo "$dirs" | fzf --height 40% --reverse --border --query="$cur")
        if [[ -n "$selected" ]]; then
            COMPREPLY=("$selected")
        fi
    fi
}

# Bind fzf completion for specific commands
if command -v fzf &>/dev/null; then
    complete -F _fzf_complete_cd cd z
fi

# yazi - terminal file manager wrapper (changes dir on exit)
y() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Modern tool aliases
alias cat='bat --paging=never'
alias catp='bat'
alias ls='eza --color=auto'
alias ll='eza -alh'
alias la='eza -al'
alias l='eza -F'
alias lt='eza --tree'
alias grep='rg'
alias find='fd'

# Utility aliases
alias h='http'
alias z='zoxide'

# Wrapper for cd to use zoxide and auto-list files (interactive mode only)
cd() {
    # In non-interactive mode, use regular cd
    if [[ $- != *i* ]]; then
        builtin cd "$@"
        return
    fi

    # Interactive mode: use zoxide and auto-list
    if [ $# -eq 0 ]; then
        builtin cd && la
    else
        __zoxide_z "$@" && la
    fi
}

# Aliases for docker
alias dcd='docker compose down'
alias dcr='docker compose restart'

dcp() {
    if [ -z "$1" ]; then
        docker compose up -d && docker compose logs -f
        return 1
    fi
    docker compose up -d "$1" && docker logs -f "$1"
}

alias dps='docker ps'
alias dlg='docker logs'
alias dlgf='docker logs -f'

alias dst='docker container start'
alias dstt='docker container stop'
alias dsttt='docker stop $(docker ps -q)'
alias drs='docker container restart'

alias dx='docker exec'
alias dxit='docker exec -it'

dbash() {
    if [ -z "$1" ]; then
        echo "Usage: dbash <container_name_or_id>"
        return 1
    fi
    docker exec -it "$1" /bin/bash
}

dsh() {
    if [ -z "$1" ]; then
        echo "Usage: dsh <container_name_or_id>"
        return 1
    fi
    docker exec -it "$1" /bin/sh
}

alias dcls='docker container ls -a'
alias drm='docker container rm'
alias 'drm!'='docker container rm -f'

alias dils='docker image ls'
alias dirm='docker image rm'
alias dpu='docker pull'
alias dib='docker image build'
alias dii='docker image inspect'
alias dipu='docker image push'
alias dit='docker image tag'

alias dbl='docker build'
alias dcin='docker container inspect'

alias dnc='docker network create'
alias dncn='docker network connect'
alias dndcn='docker network disconnect'
alias dni='docker network inspect'
alias dnls='docker network ls'
alias dnrm='docker network rm'
alias dpo='docker container port'
alias dvi='docker volume inspect'
alias dvls='docker volume ls'
alias dvprune='docker volume prune'

dhelp() {
    cat <<'DHELP'
Docker Shortcut Cheat Sheet
===========================
Compose:
  dcp [svc]   up -d (+ logs)     dcd   down       dcr   restart

Containers:
  dps         running            dcls list
  dst <c>     start              dstt <c>  stop   drs <c>  restart
  drm <c>     remove             drm! <c> force   dcin <c> inspect
  dpo <c>     ports

Exec / Shell:
  dx <c> <cmd>      exec           dsh <c>         /bin/sh
  dxit <c> <cmd>    exec -it     dbash <c>       /bin/bash

Logs:
  dlg <c>    logs            dlgf <c>   follow logs

Images:
  dils        list           dirm <img>   rm
  dpu <img>   pull           dib <dir>    build
  dii <img>   inspect        dipu <img>   push
  dit s d     tag

Networks:
  dnls         list          dnc <n>     create
  dncn n c     connect       dndcn n c   disconnect
  dni <n>      inspect       dnrm <n>    rm

Volumes:
  dvls         list          dvi <v>     inspect
  dvprune      prune unused

DHELP
}

EOF
    log_success "Shell configuration added"
fi

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ ubuntu-kit installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Installed tools:"
echo "  • eza       - Modern ls replacement (ls, ll, la, lt)"
echo "  • bat       - Better cat with syntax highlighting"
echo "  • httpie    - User-friendly HTTP client (h)"
echo "  • fzf       - Fuzzy finder (Ctrl+R history, Ctrl+T files)"
echo "  • zoxide    - Smarter cd command (z)"
echo "  • ripgrep   - Fast grep alternative (rg)"
echo "  • fd        - Fast find alternative (fd)"
echo "  • jq        - JSON processor"
echo "  • ncdu      - Disk usage analyzer"
echo "  • btop      - System monitor"
echo "  • tldr      - Simplified man pages"
echo "  • glow      - Markdown renderer (glow README.md)"
echo "  • yazi      - Terminal file manager (y)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run: ${BLUE}source $BASHRC${NC}"
echo "  2. Or reconnect your SSH session"
echo ""
echo -e "${BLUE}Try it out:${NC}"
echo "  z <dir>          - Jump to a directory you've visited"
echo "  Ctrl+R           - Fuzzy search command history"
echo "  Ctrl+T           - Fuzzy search files"
echo "  cat file.txt     - View file with syntax highlighting"
echo "  h GET api.com    - Make HTTP requests"
echo ""
echo "Report issues: https://github.com/takashito/ubuntu-kit/issues"
