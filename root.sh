#!/usr/bin/env bash
set -euo pipefail

# ─── Pixel 9 Pro (caiman) — Android 16 — Automated Root ──────────────────────
# Usage:
#   Remote:  curl -sL https://raw.githubusercontent.com/sosramalex/pixel-root-automation/main/root.sh | sudo bash
#   Local:   sudo ./root.sh
# Prerequisites: python3 with pexpect (pip install pexpect), unlocked bootloader
# ──────────────────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[x]${NC} $*"; }
header() { echo -e "\n${CYAN}══════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}══════════════════════════════════════════════${NC}"; }

# ─── Configuration ────────────────────────────────────────────────────────────
DEVICE="caiman"
FACTORY_VERSION="cp1a.260505.005"
FACTORY_ZIP="caiman-${FACTORY_VERSION}-factory-28248db3.zip"
FACTORY_URL="https://dl.google.com/dl/android/aosp/${FACTORY_ZIP}"
MAGISK_APK="Magisk-v30.7.apk"
MAGISK_URL="https://github.com/topjohnwu/Magisk/releases/download/v30.7/Magisk-v30.7.apk"
PIF_ZIP="PlayIntegrityFork-v16.zip"
PIF_URL="https://github.com/osm0sis/PlayIntegrityFork/releases/download/v16/${PIF_ZIP}"
PLATFORM_TOOLS="/tmp/platform-tools"
ADB="${PLATFORM_TOOLS}/adb"
FASTBOOT="${PLATFORM_TOOLS}/fastboot"
SUDO_PASS="${SUDO_PASS:-Op3nC0d3}"
WORKDIR="/tmp/pixel-root"
MODDIR="${MODDIR:-/tmp/pixel-root/modules}"

mkdir -p "$WORKDIR" "$MODDIR"

# ─── Helper: fix USB permissions ─────────────────────────────────────────────
fix_usb() {
  log "Fixing USB device permissions..."
  python3 - <<PYEOF 2>/dev/null || true
import pexpect, os, time
try:
    c = pexpect.spawn('su - opencode')
    c.expect('[Pp]assword:', timeout=10)
    c.sendline('${SUDO_PASS}')
    c.expect(r'\$', timeout=10)
    c.sendline('echo ${SUDO_PASS} | sudo -S chmod 666 /dev/bus/usb/003/*')
    c.expect(r'\$', timeout=10)
    c.sendline('exit')
    c.close()
except: pass
PYEOF
  ${ADB} kill-server 2>/dev/null || true
  sleep 0.5
  ${ADB} start-server 2>/dev/null || true
  sleep 0.5
}

wait_device() {
  log "Waiting for device..."
  ${ADB} wait-for-device
  sleep 2
}

wait_fastboot() {
  log "Waiting for fastboot device..."
  for i in $(seq 1 30); do
    if ${FASTBOOT} devices 2>/dev/null | grep -q fastboot; then
      return 0
    fi
    sleep 1
  done
  err "Device not in fastboot mode"
  exit 1
}

# ─── Step 0: Pre-flight checks ───────────────────────────────────────────────
preflight() {
  header "Pre-flight Checks"

  if [ "$(id -u)" -ne 0 ]; then
    err "Run with sudo: sudo ./root.sh"
    exit 1
  fi

  # Check / install system dependencies
  local deps="curl unzip python3 pip3"
  for dep in $deps; do
    if ! command -v "$dep" &>/dev/null; then
      log "Installing missing dependency: $dep"
      apt-get install -y -qq "$dep" 2>/dev/null || true
    fi
  done

  # Ensure pexpect is installed for USB permission fix
  if ! python3 -c "import pexpect" 2>/dev/null; then
    log "Installing python3-pexpect..."
    apt-get install -y -qq python3-pexpect 2>/dev/null || pip3 install pexpect 2>/dev/null || true
  fi

  # Download platform-tools if missing
  if [ ! -f "${ADB}" ]; then
    log "Downloading platform-tools..."
    mkdir -p /tmp
    curl -sL -o /tmp/platform-tools.zip "https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
    unzip -q -o /tmp/platform-tools.zip -d /tmp/
    chmod +x ${ADB} ${FASTBOOT}
  fi

  fix_usb

  if ! ${ADB} devices | grep -q "device$"; then
    err "No device detected. Check USB connection."
    exit 1
  fi

  log "Device detected: $(${ADB} shell getprop ro.product.model 2>/dev/null)"
  log "Build: $(${ADB} shell getprop ro.build.fingerprint 2>/dev/null)"

  # Check bootloader status
  local bl_status
  bl_status=$(${ADB} shell "su -c 'getprop ro.boot.untrusted_mode 2>/dev/null || getprop ro.boot.verifiedbootstate 2>/dev/null || echo unknown'" 2>/dev/null)
  log "Bootloader status: ${bl_status}"

  # Check if already rooted
  if ${ADB} shell "su -c id" 2>/dev/null | grep -q "uid=0"; then
    warn "Device appears already rooted. Re-patching will re-install."
  fi
}

# ─── Step 1: Download factory image ──────────────────────────────────────────
download_factory() {
  header "Downloading Factory Image"

  if [ -f "${WORKDIR}/${FACTORY_ZIP}" ]; then
    log "Factory image already cached (${FACTORY_ZIP})"
  else
    log "Downloading ${FACTORY_ZIP} (~3.8 GB)..."
    curl -sL -o "${WORKDIR}/${FACTORY_ZIP}" "${FACTORY_URL}"
    log "Download complete"
  fi
}

# ─── Step 2: Extract init_boot.img ──────────────────────────────────────────
extract_init_boot() {
  header "Extracting init_boot.img"

  if [ -f "${WORKDIR}/init_boot.img" ]; then
    log "init_boot.img already extracted"
    return
  fi

  log "Unzipping factory image..."
  unzip -q -o "${WORKDIR}/${FACTORY_ZIP}" -d "${WORKDIR}/factory/" 2>/dev/null

  IMAGE_ZIP=$(ls "${WORKDIR}"/factory/*-image-*.zip 2>/dev/null | head -1)
  if [ -z "$IMAGE_ZIP" ]; then
    err "Could not find image zip in factory archive"
    exit 1
  fi

  log "Extracting init_boot.img from image zip..."
  unzip -q -o "$IMAGE_ZIP" "init_boot.img" -d "${WORKDIR}/"
  log "Extracted: ${WORKDIR}/init_boot.img"
}

# ─── Step 3: Download Magisk ─────────────────────────────────────────────────
download_magisk() {
  header "Downloading Magisk"

  if [ -f "${MODDIR}/${MAGISK_APK}" ]; then
    log "Magisk APK already cached"
  else
    log "Downloading Magisk v30.7..."
    curl -sL -o "${MODDIR}/${MAGISK_APK}" "${MAGISK_URL}"
    log "Downloaded: ${MODDIR}/${MAGISK_APK}"
  fi
}

# ─── Step 4: Push and patch init_boot via Magisk ─────────────────────────────
patch_init_boot() {
  header "Patching init_boot.img with Magisk"

  local patched="${WORKDIR}/patched_init_boot.img"
  if [ -f "$patched" ]; then
    log "Patched image already exists: ${patched}"
    return
  fi

  log "Pushing files to device..."

  # Ensure Magisk app is installed
  ${ADB} install "${MODDIR}/${MAGISK_APK}" 2>/dev/null || warn "Magisk might already be installed"

  # Push init_boot to device
  ${ADB} push "${WORKDIR}/init_boot.img" /sdcard/Download/

  # Push Magisk APK
  ${ADB} push "${MODDIR}/${MAGISK_APK}" /sdcard/Download/

  log "Open Magisk app on the device and:"
  log "1. Tap 'Install' → 'Select and Patch a File'"
  log "2. Select /sdcard/Download/init_boot.img"
  log "3. Wait for patching to complete"
  echo -e "\n${YELLOW}After patching finishes, the patched file will be at:"
  echo "/Download/magisk_patched-*.img${NC}"
  echo -e "\n${YELLOW}We'll pull it automatically once detected.${NC}"

  # Wait for patched file to appear
  log "Waiting for patched image (polling /sdcard/Download/magisk_patched-*.img)..."
  for i in $(seq 1 120); do
    local patched_device
    patched_device=$(${ADB} shell "ls /sdcard/Download/magisk_patched-*.img 2>/dev/null" 2>/dev/null || true)
    if [ -n "$patched_device" ]; then
      log "Found: ${patched_device}"
      ${ADB} pull "${patched_device}" "$patched"
      log "Pulled patched image to: ${patched}"
      return
    fi
    sleep 2
  done

  err "Timed out waiting for patched image. Run Magisk app manually and patch init_boot.img."
  exit 1
}

# ─── Step 5: Flash patched init_boot ─────────────────────────────────────────
flash_patched() {
  header "Flashing Patched init_boot.img"

  local patched="${WORKDIR}/patched_init_boot.img"
  if [ ! -f "$patched" ]; then
    err "Missing patched image: ${patched}"
    exit 1
  fi

  log "Rebooting to bootloader..."
  ${ADB} reboot bootloader
  wait_fastboot

  log "Flashing to slot _a..."
  ${FASTBOOT} flash init_boot_a "$patched"

  log "Flashing to slot _b..."
  ${FASTBOOT} flash init_boot_b "$patched"

  log "Rebooting..."
  ${FASTBOOT} reboot
  wait_device
  fix_usb
  wait_device
}

# ─── Step 6: Verify root ────────────────────────────────────────────────────
verify_root() {
  header "Verifying Root"

  sleep 5
  fix_usb
  wait_device

  local root_check
  root_check=$(${ADB} shell "su -c 'id'" 2>/dev/null || true)
  if echo "$root_check" | grep -q "uid=0"; then
    log "Root confirmed: ${root_check}"
  else
    err "Root check failed. Output: ${root_check}"
    err "Ensure Magisk app is installed, open it, and check the status."
    exit 1
  fi
}

# ─── Step 7: Install PlayIntegrityFork ──────────────────────────────────────
install_pif() {
  header "Installing PlayIntegrityFork v16"

  if [ ! -f "${MODDIR}/${PIF_ZIP}" ]; then
    log "Downloading PlayIntegrityFork v16..."
    curl -sL -o "${MODDIR}/${PIF_ZIP}" "${PIF_URL}"
  fi

  log "Pushing and installing module..."
  ${ADB} push "${MODDIR}/${PIF_ZIP}" /sdcard/Download/
  ${ADB} shell "su -c 'magisk --install-module /sdcard/Download/${PIF_ZIP}'"

  log "Module installed. Rebooting..."
  ${ADB} shell "su -c 'reboot'"
  sleep 10
  fix_usb
  wait_device
}

# ─── Step 8: Run PIF fingerprint action ─────────────────────────────────────
run_pif_action() {
  header "Running PIF Fingerprint Action"

  log "Fetching fingerprint (autopif4.sh -m)..."
  ${ADB} shell "su -c 'sh /data/adb/modules/playintegrityfix/autopif4.sh -m'"

  log "Fingerprint configured:"
  ${ADB} shell "su -c 'grep FINGERPRINT /data/adb/modules/playintegrityfix/custom.pif.prop'"
}

# ─── Step 9: Clear Google data ──────────────────────────────────────────────
clear_google_data() {
  header "Clearing Google Play Services Data"

  warn "This will sign you out of all Google accounts!"
  echo -e "${YELLOW}Continue? [y/N]${NC}"
  read -r confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    log "Skipping data clear."
    return
  fi

  log "Clearing data..."
  ${ADB} shell "su -c 'pm clear com.google.android.gms'"
  sleep 3
  ${ADB} shell "su -c 'pm clear com.google.android.gms'"
  ${ADB} shell "su -c 'pm clear com.android.vending'"

  log "Rebooting..."
  ${ADB} shell "su -c 'reboot'"
  sleep 10
  fix_usb
  wait_device

  warn "Re-sign into your Google accounts now."
}

# ─── Step 10: Check integrity (manual) ──────────────────────────────────────
check_integrity() {
  header "Play Integrity Check"

  log "Install 'Integrity Check' by nikolasspyr from Play Store, or run:"
  echo "  ${ADB} shell monkey -p gr.nikolasspyr.integritycheck 1"
  echo ""
  log "Expected result after setup:"
  echo "  - MEETS_BASIC_INTEGRITY  = YES  (immediate)"
  echo "  - MEETS_DEVICE_INTEGRITY = YES  (up to 24h after setup, or after clearing data)"
  echo "  - MEETS_STRONG_INTEGRITY = NO   (requires locked bootloader + valid keybox)"
  echo ""
  log "If DEVICE still fails after 24h, try:"
  echo "  1. Re-run: ${ADB} shell su -c 'sh /data/adb/modules/playintegrityfix/autopif4.sh -a'"
  echo "  2. Clear Play Services data again"
  echo "  3. Reboot"
}

# ─── Menu ────────────────────────────────────────────────────────────────────
menu() {
  echo ""
  echo "Pixel 9 Pro (caiman) — Android 16 — Root Automation"
  echo "────────────────────────────────────────────────────"
  echo "1) Full root (steps 0-9)"
  echo "2) Just fix USB permissions"
  echo "3) Download + extract + patch (steps 1-4)"
  echo "4) Flash patched init_boot (step 5)"
  echo "5) Install PIF module (steps 7-9)"
  echo "6) Check integrity info"
  echo "q) Quit"
  echo ""
  read -rp "Select [1-6/q]: " choice
  echo ""

  case "$choice" in
    1)
      preflight
      download_factory
      extract_init_boot
      download_magisk
      patch_init_boot
      flash_patched
      verify_root
      install_pif
      run_pif_action
      clear_google_data
      check_integrity
      header "All done! Device is rooted with PIF configured."
      echo "Install Integrity Check app to verify. DEVICE may need up to 24h."
      ;;
    2) fix_usb; ${ADB} devices ;;
    3)
      preflight
      download_factory
      extract_init_boot
      download_magisk
      patch_init_boot
      ;;
    4) flash_patched; verify_root ;;
    5)
      preflight
      install_pif
      run_pif_action
      clear_google_data
      check_integrity
      ;;
    6) check_integrity ;;
    q|Q) exit 0 ;;
    *) warn "Invalid choice" ;;
  esac
}

# ─── Main ────────────────────────────────────────────────────────────────────

# Detect if running via curl pipe
if [ -z "${BASH_SOURCE:-}" ] || [ "$0" = "bash" ] || [ "$0" = "sh" ]; then
  CURL_MODE=1
  echo -e "${CYAN}Running remotely via curl | bash${NC}"
  echo -e "${CYAN}Repo: https://github.com/sosramalex/pixel-root-automation${NC}\n"
else
  CURL_MODE=0
fi

if [ $# -ge 1 ]; then
  # CLI mode: pass step names as args
  for step in "$@"; do
    case "$step" in
      -h|--help|help) echo "Steps: preflight, download, extract, magisk, flash, verify, pif, cleardata, fixusb"; exit 0;;
      preflight) preflight ;;
      download) download_factory ;;
      extract) extract_init_boot ;;
      magisk) download_magisk; patch_init_boot ;;
      flash) flash_patched ;;
      verify) verify_root ;;
      pif) install_pif; run_pif_action ;;
      cleardata) clear_google_data ;;
      fixusb) fix_usb ;;
      *) warn "Unknown step: $step" ;;
    esac
  done
else
  menu
fi
