<p align="center">
  <img src="https://placehold.co/120x179" width="90" alt="pixel-root-automation logo">
</p>

[![GitHub](https://img.shields.io/static/v1?label=GitHub&message=sosaramosalexis%2Fpixel-root-automation&color=181717&logo=github)](https://github.com/sosaramosalexis/pixel-root-automation)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-blue?logo=gnu-bash)]()
[![Platform](https://img.shields.io/badge/platform-Android-green)]()

# Pixel 9 Pro Root Automation

Automated root + root hiding for **Pixel 9 Pro (caiman)** on **Android 16** using **Magisk**, **Shamiko**, **PlayIntegrityFork**, and **Hide My Applist**.

---

## Quick Start

### One-liner (remote)
```bash
curl -sL https://raw.githubusercontent.com/sosaramosalexis/pixel-root-automation/main/root.sh | sudo bash
```

### Clone locally
```bash
git clone https://github.com/sosaramosalexis/pixel-root-automation.git
cd pixel-root-automation
sudo ./root.sh
```

---

## Prerequisites

- Linux PC (with USB port)
- Pixel 9 Pro with **unlocked bootloader**
- USB data cable
- `python3` with `pexpect` (`pip install pexpect` or `apt install python3-pexpect`)

> ADB, Fastboot, and all required modules are auto-downloaded by the script.

---

## What This Does

### 1. Root the Device
| Step | Description |
|------|-------------|
| Fix USB permissions | Grants ADB access to the device |
| Download factory image | Pulls the correct stock boot image for your build |
| Extract & patch | Extracts `init_boot.img` and patches it with Magisk |
| Flash | Flashes the patched image to both boot slots |
| Verify | Confirms root access and Magisk daemon is running |

### 2. Pass Play Integrity
| Step | Description |
|------|-------------|
| Install PIF module | PlayIntegrityFork for Device/Basic integrity |
| Run autopif | Fetches a working fingerprint |
| Clear Google data | Resets Play Services cache for fresh integrity check |

### 3. Hide Root from Banking Apps
| Step | Description |
|------|-------------|
| Install Shamiko | Hides Zygisk and Magisk traces from target apps |
| Install HMA | Hide My Applist — hides root apps from detection |
| Configure DenyList | Adds detected banking apps to Magisk DenyList |
| Hide Magisk app | Guides you through repacking Magisk with a random package name |
| HMA template setup | Guides you through creating a blacklist for banking apps |

---

## Menu Options

| # | Action | CLI arg |
|---|--------|---------|
| 1 | Full root (steps 0-9) | — |
| 2 | Fix USB permissions | `fixusb` |
| 3 | Download → extract → patch | `preflight download extract magisk` |
| 4 | Flash patched init_boot | `flash` |
| 5 | Install PIF module | `pif` |
| 6 | Check integrity info | — |
| 7 | Install Shamiko | `shamiko` |
| 8 | Install Hide My Applist | `hma` |
| 9 | Configure DenyList + hiding | `hiding` |
| 10 | Verify hiding setup | `verifyhide` |
| 11 | Full root + hiding (everything) | — |

CLI example — non-interactive full run:
```bash
sudo ./root.sh preflight download extract magisk flash verify pif shamiko hma hiding cleardata
```

---

## Bundled Files

| File | Size | Purpose |
|------|------|---------|
| `root.sh` | — | Main automation script |
| `modules/Shamiko.zip` | 6.3 MB | Hides Zygisk/Magisk from DenyList targets |
| `modules/PlayIntegrityFix.zip` | 277 KB | Spoofs device fingerprint for Play Integrity |
| `apks/HMA.apk` | 3.5 MB | Root app hiding for aggressive banking apps |

---

## After Setup — Best Practices

1. **Disable USB debugging** and **Developer options** before opening banking apps
2. Test with a root checker app first
3. Install **Integrity Check** by nikolasspyr from Play Store to verify Play Integrity
4. The fingerprint expires ~30 days — re-run when integrity drops:
   ```bash
   sudo ./root.sh pif cleardata
   ```
5. When installing new banking apps, add them to DenyList:
   ```bash
   adb shell su -c "magisk --denylist add com.example.bank"
   ```

---

## Troubleshooting

**Device not detected**
```bash
# Fix USB permissions manually
sudo ./root.sh fixusb
```

**Device in fastboot but not showing**
```bash
fastboot devices
# If empty: check USB cable, try different port
```

**Root verification fails after flashing**
- Open the Magisk app — it may prompt a reboot to finish setup
- If Magisk app says "not installed", re-patch and flash

**Banking app still detects root**
- Ensure DenyList is **not enforced** (Shamiko handles this)
- Check that Magisk app is hidden (Settings → Hide Magisk App)
- Configure HMA with a blacklist covering: Magisk, Termux, root checkers, file managers
- Disable USB debugging and Developer options

---

## Notes

- Factory image download is ~3.8 GB — ensure sufficient disk space
- Flashing a factory image wipes all device data — back up first
- Full Play Integrity (DEVICE verdict) may take up to 24h after setup due to Google caching
- Pixel 6+ series uses the `init_boot` partition — this script targets that layout
- **Not responsible for bricked devices** — proceed at your own risk
