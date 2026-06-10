<p align="center">
  <img src="https://placehold.co/120x179" width="90" alt="pixel-root-automation logo">
</p>

[![GitHub](https://img.shields.io/static/v1?label=GitHub&message=sosaramosalexis%2Fpixel-root-automation&color=181717&logo=github)](https://github.com/sosaramosalexis/pixel-root-automation)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-blue?logo=gnu-bash)]()
[![Platform](https://img.shields.io/badge/platform-Android-green)]()

# Pixel 9 Pro Root Automation

Automated root + root hiding for **Pixel 9 Pro (caiman)** on **Android 16** using **Magisk v30.7**, **Shamiko**, **PlayIntegrityFork**, and **Hide My Applist**.

## Prerequisites

- Linux PC with `adb` and `fastboot` in PATH (auto-downloaded if missing)
- Pixel 9 Pro with **unlocked bootloader** (wipes data!)
- USB cable
- Python 3 with `pexpect` (`pip install pexpect`) — for USB permission fix

## One-liner (remote run)

```bash
curl -sL https://raw.githubusercontent.com/sosaramosalexis/pixel-root-automation/main/root.sh | sudo bash
```

Starts the interactive menu. Run individual steps via arguments:

```bash
# Full root + hiding (non-interactive)
curl -sL https://raw.githubusercontent.com/sosaramosalexis/pixel-root-automation/main/root.sh | sudo bash -s preflight download extract magisk flash verify pif shamiko hma hiding cleardata

# Just install hiding modules (if already rooted)
curl -sL https://raw.githubusercontent.com/sosaramosalexis/pixel-root-automation/main/root.sh | sudo bash -s shamiko hma hiding
```

## Local usage (clone first)

```bash
git clone https://github.com/sosaramosalexis/pixel-root-automation.git
cd pixel-root-automation
chmod +x root.sh
sudo ./root.sh
```

## What it does

### Rooting
1. Fixes USB permissions (automates `chmod 666 /dev/bus/usb/...`)
2. Downloads stock factory image for caiman
3. Extracts `init_boot.img`
4. Downloads Magisk APK
5. Pushes files to device and patches `init_boot.img` via Magisk app
6. Flashes patched `init_boot.img` to both slots
7. Reboots and verifies root

### Play Integrity
8. Installs PlayIntegrityFork module
9. Runs fingerprint autopif
10. Clears Google Play Services data

### Root Hiding (for banking apps)
11. Installs **Shamiko** — hides Zygisk/Magisk from target apps
12. Installs **Hide My Applist (HMA)** — hides root apps from detection
13. Configures Magisk **DenyList** with detected banking apps
14. Guides through Magisk app repacking + HMA template setup
15. Verifies all hiding layers

## Interactive Menu

| Option | What it does |
|--------|-------------|
| 1 | Full root (steps 0-9) |
| 2 | Fix USB permissions |
| 3 | Download factory image + extract + patch init_boot |
| 4 | Flash patched init_boot |
| 5 | Install PIF module |
| 6 | Check integrity info |
| 7 | Install Shamiko module |
| 8 | Install Hide My Applist |
| 9 | Configure hiding (DenyList + HMA) |
| 10 | Verify hiding setup |
| 11 | Full root + hiding (everything) |

## Files

- `root.sh` — main automation script
- `modules/Shamiko.zip` — Shamiko v1.2.5 (bundled)
- `modules/PlayIntegrityFix.zip` — PlayIntegrityFork (bundled)
- `apks/HMA.apk` — Hide My Applist (bundled)

## Notes

- The fingerprint from autopif is a **Canary** build with ~30 day expiry. Re-run steps 9-10 monthly or when integrity drops.
- After clearing Google data, you must re-sign into your Google accounts.
- Full Play Integrity (DEVICE) may take up to 24h after initial setup due to Google caching.
- For best root hiding: disable **USB debugging** and **Developer options** before using banking apps.
