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
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Banner
echo -e "${BLUE}Installing modern CLI utilities...${NC}\n"

# Check if running on Ubuntu
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        warn "Detected $ID (not Ubuntu). Some packages may not be available."
    fi
fi

# Update package list
info "Updating package list..."
apt-get update -qq

# Install fundamental packages
info "Installing fundamental tools..."
apt-get install -y -qq \
    bat \
    httpie \
    ripgrep \
    fd-find \
    jq \
    ncdu \
    duf \
    btop \
    git \
    curl \
    wget \
    unzip \
    tree \
    tldr \
    bash-completion

success "Package installation complete"

# Install latest fzf (apt version is too old for yazi integration)
info "Installing fzf (latest)..."
if ! command -v fzf &>/dev/null || [[ "$(fzf --version | cut -d' ' -f1)" < "0.50" ]]; then
    FZF_VERSION=$(curl -sL https://api.github.com/repos/junegunn/fzf/releases/latest | jq -r .tag_name)
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION#v}-linux_amd64.tar.gz" -o /tmp/fzf.tar.gz
    tar -xzf /tmp/fzf.tar.gz -C /usr/local/bin
    chmod +x /usr/local/bin/fzf
    rm -f /tmp/fzf.tar.gz
    success "fzf ${FZF_VERSION} installed"
else
    info "fzf already installed ($(fzf --version | cut -d' ' -f1))"
fi

# Install eza (modern ls replacement)
info "Installing eza..."
if ! command -v eza &>/dev/null; then
    apt-get install -y -qq gpg
    mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    apt-get update -qq
    apt-get install -y -qq eza
    success "eza installed"
else
    info "eza already installed"
fi

# Install zoxide (smarter cd command)
info "Installing zoxide..."
if ! command -v zoxide &>/dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    success "zoxide installed"
else
    info "zoxide already installed"
fi

# Install glow (markdown renderer)
info "Installing glow..."
if ! command -v glow &>/dev/null; then
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
    apt-get update -qq
    apt-get install -y -qq glow
    success "glow installed"
else
    info "glow already installed"
fi

# Install yazi (terminal file manager)
info "Installing yazi..."
if ! command -v yazi &>/dev/null; then
    YAZI_VERSION=$(curl -sL https://api.github.com/repos/sxyazi/yazi/releases/latest | jq -r '.tag_name')
    curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip" -o /tmp/yazi.zip
    unzip -q /tmp/yazi.zip -d /tmp/yazi
    mv /tmp/yazi/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
    mv /tmp/yazi/yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/
    chmod +x /usr/local/bin/yazi /usr/local/bin/ya
    rm -rf /tmp/yazi /tmp/yazi.zip
    success "yazi installed"
else
    info "yazi already installed"
fi

# Install lazydocker
info "Installing lazydocker..."
if ! command -v lazydocker &>/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    success "lazydocker installed"
else
    info "lazydocker already installed"
fi

# Install claude code
info "Installing claude code..."
curl -fsSL https://claude.ai/install.sh | bash

# Create bat alias (Ubuntu names it batcat)
info "Creating symbolic links..."
if [ ! -f /usr/local/bin/bat ]; then
    ln -sf /usr/bin/batcat /usr/local/bin/bat
    success "bat -> batcat"
fi

# Create fd alias (Ubuntu names it fdfind)
if [ ! -f /usr/local/bin/fd ]; then
    ln -sf /usr/bin/fdfind /usr/local/bin/fd
    success "fd -> fdfind"
fi

# Determine which user's bashrc to modify
TARGET_USER="${SUDO_USER:-$USER}"
if [[ "$TARGET_USER" == "root" ]] || [[ -z "$TARGET_USER" ]]; then
    BASHRC="/root/.bashrc"
else
    BASHRC="/home/$TARGET_USER/.bashrc"
fi

info "Configuring shell for user: $TARGET_USER"

# Check if already configured
if grep -q "ubuntu-kit" "$BASHRC" 2>/dev/null; then
    warn "ubuntu-kit configuration already exists in $BASHRC"
    warn "Remove existing config or restore from backup to reinstall"
else
    # Add shell integrations
    info "Adding shell integrations to $BASHRC..."
    cat >> "$BASHRC" << 'EOF'

# ============================================
# ubuntu-kit - Modern CLI Utilities
# ============================================

# Disable terminal bell on tab-completion
bind 'set bell-style none' 2>/dev/null

# Add ~/.local/bin to PATH (for zoxide, etc.)
export PATH="$HOME/.local/bin:$PATH"

# zoxide - smarter cd (provides 'z' command for jumping)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# fzf - fuzzy finder configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
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
alias so='source ~/.bashrc'
alias cat='bat'
alias catp='bat --paging=never'
alias ls='eza --color=auto'
alias ll='eza -alh'
alias la='eza -al'
alias lt='eza -alT -L 2'
alias grep='rg'
alias find='fd'
alias h='http'
alias bashrc='vi ~/.bashrc'
alias myip='curl inet-ip.info'

# Wrapper for cd to use zoxide and auto-list files (interactive mode only)
cd() {
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
alias ..="cd .."
alias ...="cd ../.."

# Takes stdin, sends to local clipboard
copy() {
  printf "\033]52;c;%s\007" "$(base64 | tr -d '\n')"
}

# Aliases for docker 
alias ld='lazydocker'
alias dcls='docker compose ls'
alias dcps='docker compose ps'
alias dcd='docker compose down'
alias dcbl='docker compose build'
alias dcst='docker compose start'
alias dcsp='docker compose stop'
alias dcrs='docker compose restart'
alias dcrm='docker compose rm -fv'
alias dcrma='docker compose down --volumes --remove-orphans'
dcu() {
    if [ -z "$1" ]; then
        docker compose up -d
        return 1
    fi
    docker compose up -d "$1" && docker logs -f "$1"
}

alias dps='docker ps'
alias dls='docker container ls -a'
alias dst='docker container start'
alias dsp='docker container stop'
alias dspa='docker stop $(docker ps -q)'
alias drs='docker container restart'
alias drm='docker container rm'
alias 'drm!'='docker container rm -f'
alias din='docker container inspect'
alias dbl='docker build'
alias drun='docker run --rm'

alias dlg='docker logs -f'
alias dll='docker logs'

alias dcp='docker cp'

alias dex='docker exec'
alias dexi='docker exec -it'
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

alias dils='docker image ls'
alias dirm='docker image rm'
alias dipl='docker image pull'
alias dib='docker image build'
alias dii='docker image inspect'
alias dipush='docker image push'
alias dit='docker image tag'

alias dnc='docker network create'
alias dncn='docker network connect'
alias dndcn='docker network disconnect'
alias dni='docker network inspect'
alias dnls='docker network ls'
alias dnrm='docker network rm'
alias dpo='docker container port'
alias dvi='docker volume inspect'
alias dvrm='docker volume remove'
alias dvls='docker volume ls'
alias dvpr='docker volume prune'

dhelp() {
    cat <<'DHELP'
Docker Shortcut Cheat Sheet
===========================
Compose:
  dcls        list projects      dcps        ps
  dcu [svc]   up -d (+ logs)     dcd         down
  dcst        start              dcsp        stop
  dcrs        restart            dcbl        build
  dcrm        rm -fv             dcrma       down --volumes --remove-orphans

Containers:
  dps         running            dls         list all
  dst <c>     start              dsp <c>     stop
  dspa        stop all           drs <c>     restart
  drm <c>     remove             drm! <c>    force rm
  din <c>     inspect            dpo <c>     ports
  dbl         build              drun        run --rm
  dcp <src> <dst>  copy files

Exec / Shell:
  dex <c> <cmd>     exec         dexi <c> <cmd>  exec -it
  dsh <c>           /bin/sh      dbash <c>       /bin/bash

Logs:
  dlg <c>     logs -f            dll <c>     logs

Images:
  dils        list               dirm <img>  rm
  dipl <img>  pull               dib <dir>   build
  dii <img>   inspect            dipush      push
  dit <s> <t> tag

Networks:
  dnls        list               dnc <n>     create
  dncn <n> <c>  connect          dndcn <n> <c>  disconnect
  dni <n>     inspect            dnrm <n>    rm

Volumes:
  dvls        list               dvi <v>     inspect
  dvrm <v>    remove             dvpr        prune

DHELP
}

EOF
    success "Shell configuration added"
fi

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ ubuntu-kit installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Installed tools:"
echo "  • eza         - Modern ls replacement (ls, ll, la, lt)"
echo "  • bat         - Better cat with syntax highlighting"
echo "  • httpie      - User-friendly HTTP client (h)"
echo "  • fzf         - Fuzzy finder (Ctrl+R history, Ctrl+T files)"
echo "  • zoxide      - Smarter cd command (z)"
echo "  • ripgrep     - Fast grep alternative (rg)"
echo "  • fd          - Fast find alternative (fd)"
echo "  • jq          - JSON processor"
echo "  • ncdu        - Disk usage analyzer"
echo "  • duf         - Modern disk usage/free utility"
echo "  • btop        - System monitor"
echo "  • tldr        - Simplified man pages"
echo "  • glow        - Markdown renderer (glow README.md)"
echo "  • yazi        - Terminal file manager (y)"
echo "  • lazydocker  - Terminal UI for Docker (lazydocker)"
echo ""
echo ""
read -rp "Press Enter to continue..."
bash -c "source $BASHRC"
