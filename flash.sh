#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIRMWARE_DIR="${SCRIPT_DIR}/firmware"
BOARD="${1:-sofle_choc_pro_left}"
BOOTLOADER_NAME="${2:-Keebart}"

UF2_FILE="${FIRMWARE_DIR}/${BOARD}.uf2"

if [ ! -f "${UF2_FILE}" ]; then
  echo "Firmware not found: ${UF2_FILE}"
  echo "Run ./build.sh first"
  exit 1
fi

echo "Waiting for ${BOOTLOADER_NAME} bootloader..."
echo "Double-tap reset on your keyboard now."
echo ""
echo "Firmware: ${UF2_FILE}"
echo "Press Ctrl+C to cancel."
echo ""

# Watch for bootloader volume to appear
while true; do
  if [ -d "/Volumes/${BOOTLOADER_NAME}" ]; then
    echo "Detected ${BOOTLOADER_NAME}!"
    sleep 1  # Wait for volume to be fully ready
    echo "Flashing..."

    # Try copying with retries
    for i in 1 2 3; do
      if cp "${UF2_FILE}" "/Volumes/${BOOTLOADER_NAME}/" 2>/dev/null; then
        echo "Done! Keyboard will reboot automatically."
        exit 0
      fi
      sleep 1
    done

    # If regular cp fails, try with cat
    if cat "${UF2_FILE}" > "/Volumes/${BOOTLOADER_NAME}/firmware.uf2" 2>/dev/null; then
      echo "Done! Keyboard will reboot automatically."
      exit 0
    fi

    echo "Failed to copy. Try manually:"
    echo "  cp ${UF2_FILE} /Volumes/${BOOTLOADER_NAME}/"
    exit 1
  fi
  sleep 0.5
done
