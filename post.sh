#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=================================================="
echo "      Starting Arch Post-Install Script          "
echo "=================================================="

# 1. Define Configuration Paths
CONF_FILES=("/etc/systemd/system.conf" "/etc/systemd/user.conf")
MAKEPKG_CONF="/etc/makepkg.conf"
JOURNALD_CONF="/etc/systemd/journald.conf"
LIMINE_CONF="/boot/limine/limine.conf"
PACMAN_CONF="/etc/pacman.conf"

echo ""
echo "Applying your specific configuration tweaks..."
echo "--------------------------------------------------"

# 2. Pacman Optimizations
if [ -f "$PACMAN_CONF" ]; then
    sudo sed -i 's/^#Color/Color/' "$PACMAN_CONF"
    if ! grep -q "ILoveCandy" "$PACMAN_CONF"; then
        sudo sed -i '/^Color/a ILoveCandy' "$PACMAN_CONF"
    fi
    sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' "$PACMAN_CONF"
    sudo sed -i 's/^#\?ParallelDownloads = .*/ParallelDownloads = 10/' "$PACMAN_CONF"
    sudo sed -i '/\[multilib\]/,/Include = \/etc\/pacman.d\/mirrorlist/s/^#//' "$PACMAN_CONF"
    echo " -> Pacman layout optimized (Color, Candy, Verbose, 10 Downloads)."
fi

# 3. Systemd timeouts (Set to 5s)
for FILE in "${CONF_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        sudo sed -i 's/^#\?DefaultTimeoutStartSec=.*/DefaultTimeoutStartSec=5s/' "$FILE"
        sudo sed -i 's/^#\?DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=5s/' "$FILE"
        echo " -> Systemd timeouts set to 5s in: $FILE"
    fi
done

# 4. Makepkg Optimizations (Disable debug, enable all CPU cores)
if [ -f "$MAKEPKG_CONF" ]; then
    sudo sed -i '/^OPTIONS=/s/\bdebug\b/!debug/' "$MAKEPKG_CONF"
    sudo sed -i "s/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$(nproc)\"/" "$MAKEPKG_CONF"
    echo " -> Makepkg optimized (Disabled debug, maximized CPU cores)."
fi

# 5. Journald log limit (Set to 200M)
if [ -f "$JOURNALD_CONF" ]; then
    sudo sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=200M/' "$JOURNALD_CONF"
    echo " -> Journald log size capped at 200M."
fi

# 6. Limine Bootloader Timeout (Set to 2s)
if [ -f "$LIMINE_CONF" ]; then
    if grep -iq "^#\?timeout" "$LIMINE_CONF"; then
        sudo sed -i 's/^#\?\(timeout\s*=\s*\).*/timeout=2/I' "$LIMINE_CONF"
    else
        echo "timeout=2" | sudo tee -a "$LIMINE_CONF" > /dev/null
    fi
    echo " -> Limine bootloader timeout set to 2s."
else
    echo " -> Note: Limine config not found at $LIMINE_CONF. Skipping."
fi

# 7. Disable KDE Baloo File Indexer
echo " -> Masking KDE Baloo File Indexer user service..."
systemctl --user mask kde-baloo.service 2>/dev/null || true
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    balooctl6 disable 2>/dev/null || true
fi

# 8. Set up Fish Shell
if ! command -v fish &> /dev/null; then
    echo " -> Installing fish shell..."
    sudo pacman -S --needed --noconfirm fish
fi
if [ "$SHELL" != "/usr/bin/fish" ]; then
    echo " -> Changing default shell to fish (requires your password)..."
    chsh -s /usr/bin/fish
fi

# 9. Set up Bluetooth
echo " -> Installing Bluetooth packages..."
sudo pacman -S --needed --noconfirm bluez bluez-utils
echo " -> Enabling and starting Bluetooth service..."
sudo systemctl enable --now bluetooth

# 10. NordVPN Configuration
# Note: This assumes nordvpn-bin has been previously installed (usually via AUR)
if getent group nordvpn > /dev/null; then
    echo " -> Configuring NordVPN permissions and system daemon..."
    sudo usermod -aG nordvpn "$USER"
    sudo systemctl enable --now nordvpnd.service
else
    echo " -> Note: nordvpn group not found. Install NordVPN from AUR first to link this service."
fi

# 11. Configure arch-update
echo " -> Processing arch-update layouts..."
mkdir -p "$HOME/.local/share/applications"
if [ -f "/usr/share/applications/arch-update.desktop" ]; then
    cp /usr/share/applications/arch-update.desktop "$HOME/.local/share/applications/"
    sed -i 's/^Exec=arch-update.*/Exec=arch-update -d/' "$HOME/.local/share/applications/arch-update.desktop"
fi
if command -v arch-update &> /dev/null; then
    if [ ! -f "$HOME/.config/arch-update/arch-update.conf" ] && [ ! -f "$HOME/.config/arch-update.conf" ]; then
        arch-update --gen-config
    fi
    for CONFIG_PATH in "$HOME/.config/arch-update.conf" "$HOME/.config/arch-update/arch-update.conf"; do
        if [ -f "$CONFIG_PATH" ]; then
            sed -i 's/^#\?CheckDevel\s*=.*/CheckDevel=true/' "$CONFIG_PATH"
        fi
    done
fi

# 12. Update Mirrorlist with Reflector
if ! command -v reflector &> /dev/null; then
    echo " -> Installing reflector..."
    sudo pacman -S --needed --noconfirm reflector
fi
echo " -> Fetching 20 fastest HTTPS mirrors via Reflector..."
sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# 13. Final System Sync (Uses your newly generated fast mirrors!)
echo "--------------------------------------------------"
echo "Refreshing package databases and updating system..."
sudo pacman -Syu --noconfirm

# 14. Regrow Initramfs Images
echo " -> Rebuilding linux initramfs presets..."
sudo mkinitcpio -P

echo "=================================================="
echo " All tweaks successfully applied!"
echo " Note: Log out and log back in for your shell and NordVPN group changes to take effect."
echo "=================================================="
