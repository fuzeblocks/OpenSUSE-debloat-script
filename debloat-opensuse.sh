#!/bin/bash
# ============================================================
#  OpenSUSE Debloat Script
#  Tested on: Tumbleweed
#  Run as root or with sudo
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
section() { echo -e "\n${RED}>>> $* ${NC}"; }

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root or with sudo."
  exit 1
fi

# ============================================================
# INTRO & CONFIRMATION
# ============================================================
clear
echo -e "${RED}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║           openSUSE Debloat Script                     ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo "  This script will clean up your openSUSE installation by"
echo "  removing packages and services you most likely don't need."
echo ""
echo "  The following steps will be performed:"
echo ""
echo -e "  ${GREEN}1.${NC} Remove pre-installed games & toys"
echo -e "  ${GREEN}2.${NC} Remove unwanted office/productivity extras (Calligra, Akonadi, etc.)"
echo -e "  ${GREEN}3.${NC} Remove multimedia bloat (Dragon, Elisa, Rhythmbox, etc.)"
echo -e "  ${GREEN}4.${NC} Remove openSUSE Welcome & Tour apps"
echo -e "  ${GREEN}5.${NC} Remove unused IM/chat tools (Empathy, Pidgin, Kopete)"
echo -e "  ${GREEN}5a.${NC} Optional: remove YaST modules (you choose the scope)"
echo -e "  ${GREEN}5b.${NC} Optional: remove app store front-ends (Discover / GNOME Software)"
echo -e "  ${GREEN}6.${NC} Optional: remove printer & scanner packages"
echo -e "  ${GREEN}7.${NC} Optional: remove standalone X11 tools (Wayland systems only)"
echo -e "  ${GREEN}8.${NC} Clean up orphaned packages & zypper cache"
echo -e "  ${GREEN}9.${NC} Disable unused services (Avahi, ModemManager)"
echo ""
echo -e "  ${YELLOW}Notes:${NC}"
echo "  • Some steps are interactive — you will be asked before anything"
echo "    sensitive (printers, YaST, app stores, X11) is removed."
echo "  • Packages not present on your system are silently skipped."
echo "  • A reboot will be offered at the end."
echo ""
echo -e "${RED}  WARNING:${NC} Review each prompt carefully. Removals cannot be"
echo "  automatically undone (though zypper install can restore packages)."
echo ""
read -rp "  Do you want to continue? (y/N): " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then
  echo ""
  info "Aborted. No changes were made."
  exit 0
fi

# ============================================================
# 1. GAMES & TOYS
# ============================================================
section "Removing games & toys"
GAMES=(
  gnome-chess
  gnome-mahjongg
  gnome-mines
  gnome-sudoku
  gnome-tetravex
  aisleriot          # Solitaire
  iagno              # Reversi
  lightsoff
  quadrapassel
  swell-foop
  four-in-a-row
  tali
  hitori
  atomix
  nibbles
  robots
  ksudoku
  kmahjongg
  kreversi
  kmines
  "kdegames*"
  "plasma-games*"
)
zypper remove --no-confirm "${GAMES[@]}" 2>/dev/null || warn "Some game packages not found – skipping."

# ============================================================
# 2. UNWANTED OFFICE / PRODUCTIVITY EXTRAS
# ============================================================
section "Removing unwanted office extras"
OFFICE=(
  calligra
  "calligra-*"
  kaddressbook
  knotes
  korganizer
  kontact
  kleopatra
  akonadi-server
  "akonadi-*"
  evolution
  gnome-contacts
  gnome-calendar
)
zypper remove --no-confirm "${OFFICE[@]}" 2>/dev/null || warn "Some office packages not found – skipping."

# ============================================================
# 3. MULTIMEDIA BLOAT
# ============================================================
section "Removing multimedia bloat"
MEDIA=(
  dragon              # KDE media player
  elisa               # KDE music player
  kwave               # KDE audio editor
  brasero             # GNOME disc burner
  cheese              # GNOME webcam
  rhythmbox
  totem
  gnome-music
  gnome-photos
  shotwell
)
zypper remove --no-confirm "${MEDIA[@]}" 2>/dev/null || warn "Some media packages not found – skipping."

# ============================================================
# 4. OPENSUSE WELCOME & TOUR APPS
# ============================================================
section "Removing openSUSE Welcome & Tour apps"
WELCOME=(
  opensuse-welcome
  plasma-welcome        # KDE/Plasma welcome screen (Tumbleweed)
  gnome-initial-setup   # GNOME first-run wizard
  openSUSE-Tour
  "opensuse-tour*"
  opensuse-welcome-launcher
  gnome-tour
)
zypper remove --no-confirm "${WELCOME[@]}" 2>/dev/null || warn "Some welcome/tour packages not found – skipping."
zypper al "${WELCOME[@]}" 2>/dev/null # lock the apps to prevent reinstallation

# ============================================================
# 5. UNUSED SYSTEM TOOLS / APPLETS
# ============================================================
section "Removing unused system tools"
TOOLS=(
  telepathy-*
  empathy               # GNOME IM client
  pidgin
  kopete
)
zypper remove --no-confirm "${TOOLS[@]}" 2>/dev/null || warn "Some tool packages not found – skipping."

# ============================================================
# 5a. YAST / YAST2 MODULES
# ============================================================
section "YaST / YaST2 modules"
echo "  YaST is openSUSE's system configuration tool."
echo "  You can remove optional/server modules while keeping the core (safe default),"
echo "  or remove everything if you prefer to manage the system manually via terminal."
echo ""
echo "  1) Remove only optional/server YaST modules (safe default)"
echo "  2) Remove ALL YaST/YaST2 packages (manage system manually)"
echo "  3) Keep everything"
read -rp "[?] Choice [1/2/3]: " YAST_CHOICE

case "$YAST_CHOICE" in
  1)
    info "Removing optional/server YaST modules..."
    YAST_OPTIONAL=(
      yast2-online-update-frontend
      "yast2-wagon*"
      yast2-tune              # Hardware tuning
      yast2-sound             # Sound configuration wizard
      yast2-tv                # TV card support
      yast2-scanner           # Scanner wizard
      yast2-fax               # Fax support
      yast2-fingerprint-reader
      yast2-power-management
      yast2-kdump             # Kernel crash dumps
      yast2-nfs-client
      yast2-nfs-server
      yast2-nis-client
      yast2-ldap
      yast2-samba-client
      yast2-samba-server
      yast2-tftp-server
      yast2-dhcp-server
      yast2-dns-server
      yast2-ftp-server
      yast2-http-server
      yast2-mail
      yast2-squid
    )
    zypper remove --no-confirm "${YAST_OPTIONAL[@]}" 2>/dev/null || warn "Some YaST modules not found – skipping."
    ;;
  2)
    warn "Removing ALL YaST/YaST2 packages. Use zypper/terminal for system management."
    zypper remove --no-confirm "yast2*" "libyui*" 2>/dev/null || warn "Some YaST packages not found – skipping."
    ;;
  *)
    info "Keeping YaST as-is."
    ;;
esac

# ============================================================
# 5b. APP STORES & PACKAGEKIT
# ============================================================
section "App store / PackageKit removal"
echo "  1) Remove Plasma Discover + PackageKit (recommended if using zypper)"
echo "  2) Remove GNOME Software + PackageKit (recommended if using zypper)"
echo "  3) Remove both stores + PackageKit"
echo "  4) Skip"
read -rp "[?] Choice [1/2/3/4]: " STORE_CHOICE

STORE_PKGS=()
case "$STORE_CHOICE" in
  1)
    STORE_PKGS=(plasma-discover "packagekit" "packagekit-*")
    info "Removing Plasma Discover + PackageKit..."
    ;;
  2)
    STORE_PKGS=(gnome-software "packagekit" "packagekit-*")
    info "Removing GNOME Software + PackageKit..."
    ;;
  3)
    STORE_PKGS=(plasma-discover gnome-software "packagekit" "packagekit-*")
    info "Removing both app stores + PackageKit..."
    ;;
  *)
    info "Skipping app store / PackageKit removal."
    ;;
esac

if [[ ${#STORE_PKGS[@]} -gt 0 ]]; then
  zypper remove --no-confirm "${STORE_PKGS[@]}" 2>/dev/null || warn "Some store/PackageKit packages not found – skipping."
fi

# ============================================================
# 6. PRINTERS & SCANNERS
# ============================================================
read -rp $'\n[?] Remove printer/scanner packages? (y/N): ' PRINT_ANSWER
if [[ "${PRINT_ANSWER,,}" == "y" ]]; then
  section "Removing printer & scanner packages"
  PRINT=(
    hplip
    "hplip-*"
    iscan
    simple-scan
    xsane
  )
  zypper remove --no-confirm "${PRINT[@]}" 2>/dev/null || warn "Some print packages not found – skipping."
else
  info "Skipping printer/scanner removal."
fi

# ============================================================
# 7. WAYLAND CLEANUP (optional)
# ============================================================
section "Wayland / X11 cleanup"
echo "  If you are running a pure Wayland session you can remove"
echo "  standalone X11 tools and utilities. XWayland itself is"
echo "  kept — it is required as a compatibility layer for apps"
echo "  that are not yet natively Wayland."
echo ""
read -rp "[?] Are you running Wayland? (y/N): " WAYLAND_ANSWER
if [[ "${WAYLAND_ANSWER,,}" == "y" ]]; then
  X11_PKGS=(
    xterm                  # X11 terminal emulator
    xscreensaver           # X11 screensaver daemon
    xorg-x11-utils
    xorg-x11-apps
    xorg-x11-xinit
    xorg-x11-server-utils
  )
  section "Removing X11 tools (keeping XWayland)"
  zypper remove --no-confirm "${X11_PKGS[@]}" 2>/dev/null || warn "Some X11 packages not found – skipping."
else
  info "Skipping X11 cleanup."
fi

# ============================================================
# 8. CLEAN UP ZYPPER CACHE
# ============================================================
section "Cleaning zypper cache"

info "Cleaning zypper package cache..."
zypper clean --all

# ============================================================
# 9. DISABLE UNUSED SERVICES
# ============================================================
section "Disabling unused services"
SERVICES=(
  avahi-daemon.service   # mDNS/zeroconf – rarely needed on a personal desktop
  ModemManager.service   # Only needed for mobile broadband / SIM cards
)
for svc in "${SERVICES[@]}"; do
  if systemctl is-enabled "$svc" &>/dev/null; then
    systemctl disable --now "$svc" && info "Disabled: $svc"
  else
    warn "Not enabled / not found: $svc"
  fi
done

# ============================================================
# DONE
# ============================================================
section "Debloat complete!"
info "A reboot is recommended to apply all changes."
read -rp "[?] Reboot now? (y/N): " REBOOT_NOW
[[ "${REBOOT_NOW,,}" == "y" ]] && reboot || info "Reboot skipped. Run 'sudo reboot' when ready."
