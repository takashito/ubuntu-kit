#!/bin/bash
#
# ubuntu-kit uninstaller
# Remove ubuntu-kit and all installed packages
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

echo -e "${YELLOW}"
cat << 'EOF'
Uninstalling ubuntu-kit...
EOF
echo -e "${NC}"

# Confirm
read -p "This will remove all ubuntu-kit packages and configuration. Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Uninstall cancelled"
    exit 0
fi

# Determine user
TARGET_USER="${SUDO_USER:-$USER}"
if [[ "$TARGET_USER" == "root" ]] || [[ -z "$TARGET_USER" ]]; then
    BASHRC="/root/.bashrc"
else
    BASHRC="/home/$TARGET_USER/.bashrc"
fi

# Remove bashrc configuration
if [[ -f "$BASHRC" ]]; then
    if grep -q "ubuntu-kit" "$BASHRC"; then
        log_info "Removing ubuntu-kit configuration from $BASHRC..."

        # Create backup
        cp "$BASHRC" "${BASHRC}.pre-uninstall.$(date +%Y%m%d_%H%M%S)"

        # Remove ubuntu-kit section (from marker to EOF marker or next section)
        sed -i '/# ============================================/,/# ============================================/d' "$BASHRC"
        # Clean up any remaining ubuntu-kit lines
        sed -i '/ubuntu-kit/d' "$BASHRC"

        log_success "Configuration removed (backup created)"
    else
        log_info "No ubuntu-kit configuration found in $BASHRC"
    fi
fi

# Remove symbolic links
log_info "Removing symbolic links..."
rm -f /usr/local/bin/bat
rm -f /usr/local/bin/fd
log_success "Symbolic links removed"

# Remove zoxide
if [[ -f ~/.local/bin/zoxide ]]; then
    log_info "Removing zoxide..."
    rm -f ~/.local/bin/zoxide
    log_success "zoxide removed"
fi

# Remove yazi
if [[ -f /usr/local/bin/yazi ]]; then
    log_info "Removing yazi..."
    rm -f /usr/local/bin/yazi
    rm -f /usr/local/bin/ya
    log_success "yazi removed"
fi

# Remove fzf (manually installed)
if [[ -f /usr/local/bin/fzf ]]; then
    log_info "Removing fzf..."
    rm -f /usr/local/bin/fzf
    log_success "fzf removed"
fi

# Remove apt repositories
log_info "Removing apt repositories..."
rm -f /etc/apt/sources.list.d/gierens.list
rm -f /etc/apt/sources.list.d/charm.list
rm -f /etc/apt/keyrings/gierens.gpg
rm -f /etc/apt/keyrings/charm.gpg
log_success "Apt repositories removed"

# Ask about removing packages
echo ""
read -p "Remove installed packages (bat, fzf, ripgrep, eza, glow, etc.)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Removing packages..."
    apt-get remove -y \
        bat \
        httpie \
        fzf \
        ripgrep \
        fd-find \
        jq \
        ncdu \
        btop \
        tldr \
        bash-completion \
        eza \
        glow \
        tree 2>/dev/null || log_warn "Some packages may have failed to remove"

    apt-get autoremove -y
    log_success "Packages removed"
else
    log_info "Keeping installed packages"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ ubuntu-kit uninstalled${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Your .bashrc backups are preserved in case you need to restore."
echo "Run 'source $BASHRC' or reconnect to apply changes."
