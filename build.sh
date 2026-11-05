#!/usr/bin/env bash
# Costruisce la ISO live/installabile basata su Debian 13 "trixie".
# Uso:  sudo bash build.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=distro.conf
source "$ROOT/distro.conf"

[ "$(id -u)" -eq 0 ] || { echo "Errore: esegui come root (sudo bash build.sh)"; exit 1; }

# --- Dipendenze di build ------------------------------------------------------
if ! command -v lb >/dev/null 2>&1; then
  apt-get update
  apt-get install -y live-build debootstrap squashfs-tools xorriso \
    mtools dosfstools grub-efi-amd64-bin grub-pc-bin syslinux isolinux
fi

# --- Pacchetti del desktop ----------------------------------------------------
case "$DESKTOP" in
  gnome)    DE_PKGS="task-gnome-desktop gnome-software-plugin-flatpak" ;;
  kde)      DE_PKGS="task-kde-desktop plasma-discover-backend-flatpak sddm-theme-breeze" ;;
  xfce)     DE_PKGS="task-xfce-desktop" ;;
  cinnamon) DE_PKGS="task-cinnamon-desktop" ;;
  mate)     DE_PKGS="task-mate-desktop" ;;
  lxqt)     DE_PKGS="task-lxqt-desktop" ;;
  *) echo "Errore: DESKTOP='$DESKTOP' non valido"; exit 1 ;;
esac

# --- Preparazione cartella di build -------------------------------------------
BUILD="$ROOT/build"
mkdir -p "$BUILD"
cd "$BUILD"
lb clean >/dev/null 2>&1 || true   # mantiene la cache dei pacchetti
rm -rf config

VOLUME="$(echo "${DISTRO_ID}_${DISTRO_VERSION}" | tr '[:lower:]' '[:upper:]' | cut -c1-32)"

lb config \
  --mode debian \
  --distribution trixie \
  --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --security true \
  --updates true \
  --apt-recommends true \
  --firmware-chroot true \
  --binary-images iso-hybrid \
  --bootloaders "grub-efi,syslinux" \
  --debian-installer none \
  --image-name "${DISTRO_ID}-${DISTRO_VERSION}" \
  --iso-application "$DISTRO_NAME" \
  --iso-volume "$VOLUME" \
  --iso-publisher "$PUBLISHER" \
  --bootappend-live "boot=live components quiet splash locales=$LOCALE keyboard-layouts=$KEYMAP timezone=$TIMEZONE username=$LIVE_USER hostname=$DISTRO_ID"

# --- Overlay personalizzato ---------------------------------------------------
cp -a "$ROOT/overlay/." config/

cat > config/package-lists/desktop.list.chroot <<EOF
$DE_PKGS
$LANG_PACKAGES
$EXTRA_PACKAGES
EOF

# Sostituisce i segnaposto @VAR@ nei file dell'overlay
grep -rlZ '@[A-Z_]*@' config/ 2>/dev/null | while IFS= read -r -d '' f; do
  sed -i \
    -e "s|@DISTRO_NAME@|$DISTRO_NAME|g" \
    -e "s|@DISTRO_ID@|$DISTRO_ID|g" \
    -e "s|@DISTRO_VERSION@|$DISTRO_VERSION|g" \
    -e "s|@DESKTOP@|$DESKTOP|g" \
    -e "s|@KEYMAP@|$KEYMAP|g" \
    -e "s|@ICON_THEME@|$ICON_THEME|g" \
    -e "s|@REMOVE_PACKAGES@|$REMOVE_PACKAGES|g" \
    -e "s|@FLATPAKS@|$FLATPAKS|g" \
    -e "s|@INSTALL_CHROME@|$INSTALL_CHROME|g" "$f"
done
chmod +x config/hooks/live/*.hook.chroot
# --- Build --------------------------------------------------------------------
lb build 2>&1 | tee "$ROOT/build.log"

mkdir -p "$ROOT/output"
mv -f ./*.iso "$ROOT/output/"
(cd "$ROOT/output" && sha256sum ./*.iso > SHA256SUMS)
echo
echo "Fatto! ISO in: $ROOT/output/"
ls -lh "$ROOT/output/"
