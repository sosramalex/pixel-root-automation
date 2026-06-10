[![GitHub](https://img.shields.io/static/v1?label=GitHub&message=sosaramosalexis%2Fpixel-root-automation&color=181717&logo=github)](https://github.com/sosaramosalexis/pixel-root-automation)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android-green)]()

# Pixel 9 Pro Root Automation

Root + root hiding for **Pixel 9 Pro (caiman)** on **Android 16** using **Magisk**, **Shamiko**, **PlayIntegrityFork**, and **Hide My Applist**.

## Prerequisites

- Linux PC, USB cable, Pixel 9 Pro with **unlocked bootloader**
- `python3-pexpect` (`apt install python3-pexpect`)

## Usage

```bash
curl -sL https://raw.githubusercontent.com/sosaramosalexis/pixel-root-automation/main/root.sh | sudo bash
```

Or clone and run:
```bash
git clone https://github.com/sosaramosalexis/pixel-root-automation.git
cd pixel-root-automation && sudo ./root.sh
```

## Menu

| # | Action |
|---|--------|
| 1 | Full root |
| 2 | Fix USB permissions |
| 3 | Download → extract → patch |
| 4 | Flash patched init_boot |
| 5 | Install PlayIntegrityFork |
| 6 | Integrity check info |
| 7 | Install Shamiko |
| 8 | Install Hide My Applist |
| 9 | Configure DenyList + hiding |
| 10 | Verify hiding setup |
| 11 | Full root + hiding |

CLI: `sudo ./root.sh preflight download extract magisk flash verify pif shamiko hma hiding cleardata`

## Notes

- Factory image download is ~3.8 GB; flashing **wipes all data** — back up first
- Play Integrity DEVICE verdict may take up to 24h
- Fingerprint expires ~30 days — re-run `sudo ./root.sh pif cleardata`
- Disable USB debugging & Developer options before using banking apps
- Pixel 6+ uses `init_boot` partition — script targets that layout
- **Not responsible for bricked devices**
