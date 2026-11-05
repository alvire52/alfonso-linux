# ALFONSO — distro personalizzata su Debian 13 "trixie"

ISO live e installabile (installer grafico Calamares) con desktop già incluso.
È avviabile sia in UEFI sia in BIOS, e funziona da USB o in macchina virtuale.

## Cosa contiene

| | |
|---|---|
| Base | Debian 13 trixie amd64, con main, contrib, non-free e non-free-firmware |
| Desktop | KDE Plasma 6 |
| Icone | WhiteSur (stile Apple / macOS) |
| Lingua | Italiano: locale, tastiera `it`, fuso Europe/Rome |
| Installer | Calamares con il nome della distro |
| Software | Google Chrome (browser predefinito), JDownloader 2 (Flatpak), qBittorrent, CPU-X, QDiskInfo, LibreOffice, VLC, Flatpak + Flathub |
| Esclusi | Firefox, Thunderbird, GIMP, Timeshift |
| Sistema | Firewall ufw attivo, firmware Wi-Fi e GPU, NetworkManager, Bluetooth, stampa |
| Branding | Nome nella schermata di login, in GRUB, in `os-release` e nell'installer |

## Personalizzare

- **`distro.conf`**: nome, versione, desktop, lingua e pacchetti extra.
- **`overlay/package-lists/`**: elenchi di pacchetti (un file `*.list.chroot` per gruppo).
- **`overlay/hooks/live/`**: script eseguiti dentro il sistema durante la build.
- **`overlay/includes.chroot/`**: file copiati così come sono nel sistema. Per esempio
  `etc/skel/` contiene la configurazione predefinita dei nuovi utenti, e
  `usr/share/backgrounds/` è il posto per gli sfondi.

## Compilare: opzione A, in locale con WSL (Windows)

In PowerShell **come amministratore**:

```powershell
wsl --install -d Debian      # poi riavvia e crea utente/password
```

Dentro Debian (WSL):

```bash
sudo apt update && sudo apt install -y live-build
cp -r /mnt/c/Users/Alfonso/miadistro ~/miadistro   # compila nel filesystem Linux, non su /mnt/c
cd ~/miadistro
sudo bash build.sh
cp output/*.iso /mnt/c/Users/Alfonso/Desktop/
```

Servono circa 15–20 GB liberi e 30–60 minuti.

## Compilare: opzione B, nel cloud con GitHub Actions (non serve installare niente)

1. Crea un repository su GitHub e carica questa cartella.
2. Vai su **Actions → Build ISO → Run workflow**.
3. Alla fine scarica la ISO dagli *Artifacts* della build.

## Provare la ISO

- **VirtualBox / VMware / Hyper-V**: crea una VM Linux 64-bit (4 GB RAM, 25 GB disco) e avviala dalla ISO.
- **USB**: scrivila con [Rufus](https://rufus.ie) (modalità DD) o con Ventoy.

Utente live: `live`, password `live`.
Per installare: icona **Installa** sul desktop.
Durante l'installazione è consigliata una connessione a internet, perché serve a configurare il bootloader.
