[![GitHub](https://img.shields.io/badge/GitHub-sosaramosalexis/pixel-root-automation-181717?logo=github)](https://github.com/sosaramosalexis/pixel-root-automation)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-blue?logo=gnu-bash)]()
[![Platform](https://img.shields.io/badge/platform-Linux-blue)]()

# Pixel 9 Pro Root Automation

Automated root script for **Pixel 9 Pro (caiman)** on **Android 16 (CP1A.260505.005)** using **Magisk v30.7** + **PlayIntegrityFork v16**.

## Prerequisites

- Linux PC with `adb` and `fastboot` in PATH or `/tmp/platform-tools/`
- Pixel 9 Pro with **unlocked bootloader** (wipes data!)
- USB cable
- Python 3 with `pexpect` installed (`pip install pexpect`)

## One-liner (remote run)

```bash
curl -sL https://raw.githubusercontent.com/sosaramosalexis/pixel-root-automation/main/root.sh | sudo bash
```

Starts the interactive menu. Run individual steps via arguments:

```bash
# Fix USB permissions only
curl -sL https://raw.githubusercontent.com/sosaramosalexis/pixel-root-automation/main/root.sh | sudo bash -s fixusb

# Full auto root (non-interactive steps)
curl -sL https://raw.githubusercontent.com/sosaramosalexis/pixel-root-automation/main/root.sh | sudo bash -s preflight download extract magisk flash verify pif cleardata
```

## Local usage (clone first)

```bash
chmod +x root.sh
sudo ./root.sh
```

The script will prompt you when manual action is needed.

## What it does

1. Fixes USB permissions (automates `chmod 666 /dev/bus/usb/...`)
2. Downloads stock factory image for caiman CP1A.260505.005
3. Extracts `init_boot.img`
4. Downloads Magisk v30.7 APK
5. Pushes files to device and patches `init_boot.img` via Magisk app
6. Flashes patched `init_boot.img` to both slots
7. Reboots and verifies root
8. Downloads & installs PlayIntegrityFork v16 module
9. Runs fingerprint autopif
10. Clears Google Play Services data
11. Reboots

## Files

- `root.sh` — main automation script
- `modules/` — downloaded ZIP/APK files cached here

## Notes

- The fingerprint from autopif is a **Canary** build with ~30 day expiry. Re-run step 9-10 monthly or when integrity drops.
- After clearing Google data, you must re-sign into your Google accounts.
- Full Play Integrity (DEVICE) may take up to 24h after initial setup due to Google caching.
