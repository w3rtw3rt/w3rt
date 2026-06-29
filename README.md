curl -sL tacto44.github.io/tacto44/pacman.sh | sudo bash

curl -sL tacto44.github.io/tacto44/aur.sh | bash



sudo sed -i '/^OPTIONS=/s/\bdebug\b/!debug/' /etc/makepkg.conf

sudo nano /etc/systemd/system.conf

Find these two lines (they are usually commented out with a `#`):
   ```ini
   #DefaultTimeoutStartSec=90s
   #DefaultTimeoutStopSec=90s

   Change them to 5s

   Tghen do the same thing for

   sudo nano /etc/systemd/user.conf
sudo systemctl daemon-reload
systemctl --user daemon-reload


   sudo nano /etc/systemd/journald.conf

   Find and uncomment the `SystemMaxUse` line, then set its limit:
   ```ini
SystemMaxUse=200M

Change to 200mb


sudo nano /boot/limine/limine.conf

Change or add the `timeout` line to **0** or **1**:
   ```ini
   timeout 1



   sudo nano /etc/pacman.conf

   VerbosePkgLists
   ILoveCandy
   ParallelDownloads = 10


   balooctl6 disable
   balooctl6 purge


   sudo pacman -S --needed --noconfirm git base-devel flatpak linux-zen-headers nvidia-open-dkms nvidia-utils qbittorrent steam vlc vlc-plugin-x265 gwenview ark libheif yt-dlp ffmpeg fuse2 inter-font reflector

chsh -s /usr/bin/fish

sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

paru --gendb

sudo systemctl enable --now bluetooth
paru -S nordvpn-bin nordvpn-gui-bin kei kwin-effect-rounded-corners-git arch-update-git

# 1. Create your local applications directory if it doesn't exist
mkdir -p ~/.local/share/applications/

# 2. Copy the official arch-update desktop shortcut into it
cp /usr/share/applications/arch-update.desktop ~/.local/share/applications/

# 3. Open your local copy in a text editor (like nano or micro)
nano ~/.local/share/applications/arch-update.desktop

change to Exec=arch-update -d


# Generate the config file if you don't have one yet
arch-update --gen-config

# Open the config file for editing
arch-update --edit-config

CheckDevel=true



sudo usermod -aG nordvpn $USER
sudo systemctl enable --now nordvpnd.service
sudo mkinitcpio -P

tar -xzvf kde_settings_backup.tar.gz -C /

