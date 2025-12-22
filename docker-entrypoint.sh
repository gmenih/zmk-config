#!/bin/bash
set -e

BOARD="${1:-sofle_choc_pro_left}"
SHIELD="${2:-nice_view_disp}"
CMAKE_ARGS="${3:--DCONFIG_ZMK_STUDIO=y}"
SNIPPET="${4:-studio-rpc-usb-uart}"

show_usage() {
  echo "ZMK Firmware Builder"
  echo ""
  echo "Usage: build.sh [BOARD] [SHIELD] [CMAKE_ARGS] [SNIPPET]"
  echo ""
  echo "Arguments:"
  echo "  BOARD       Board name (default: sofle_choc_pro_left)"
  echo "  SHIELD      Shield name (default: nice_view_disp)"
  echo "  CMAKE_ARGS  Additional CMake arguments (default: -DCONFIG_ZMK_STUDIO=y)"
  echo "  SNIPPET     Zephyr snippet (default: studio-rpc-usb-uart)"
  echo ""
  echo "Examples:"
  echo "  build.sh"
  echo "  build.sh sofle_choc_pro_left nice_view_disp"
  echo "  build.sh sofle_choc_pro_right nice_view_disp"
  echo "  build.sh corne_choc_pro_left"
  echo ""
  echo "Available boards in this config:"
  ls -1 /workspace/boards/arm/ 2>/dev/null | sed 's/^/  - /' || echo "  (mount your zmk-config repo first)"
  echo ""
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  show_usage
  exit 0
fi

echo "=========================================="
echo "Building ZMK Firmware"
echo "=========================================="
echo "Board:      ${BOARD}"
echo "Shield:     ${SHIELD}"
echo "CMake Args: ${CMAKE_ARGS}"
echo "Snippet:    ${SNIPPET}"
echo "=========================================="

cd /workspace

# Verify west.yml exists
if [ ! -f "/workspace/config/west.yml" ]; then
  echo "ERROR: Cannot find /workspace/config/west.yml"
  echo "Make sure your zmk-config repo is mounted at /workspace"
  exit 1
fi

cd /workspace

# Initialize workspace if needed
if [ ! -d ".west" ] || [ ! -d "zmk" ] || [ ! -f "zephyr/CMakeLists.txt" ]; then
  echo ""
  echo "Initializing West workspace (first run)..."
  # Backup module.yml if it exists (needed for GitHub, not local)
  [ -f "zephyr/module.yml" ] && cp zephyr/module.yml /tmp/module.yml.bak
  rm -rf .west zmk zephyr modules
  west init -l config
  west update
  # Restore module.yml for consistency
  [ -f "/tmp/module.yml.bak" ] && cp /tmp/module.yml.bak zephyr/module.yml
  echo "Workspace initialized."
fi

# Always ensure Zephyr CMake package is registered
west zephyr-export

BUILD_DIR="build/${BOARD}"
OUTPUT_DIR="/workspace/firmware"

mkdir -p "${OUTPUT_DIR}"

BUILD_CMD="west build -s zmk/app -p -b ${BOARD} -d ${BUILD_DIR} -- -DBOARD_ROOT=/workspace -DZMK_CONFIG=/workspace/config"

if [ -n "${SHIELD}" ]; then
  BUILD_CMD="${BUILD_CMD} -DSHIELD=${SHIELD}"
fi

if [ -n "${CMAKE_ARGS}" ]; then
  BUILD_CMD="${BUILD_CMD} ${CMAKE_ARGS}"
fi

if [ -n "${SNIPPET}" ]; then
  BUILD_CMD="${BUILD_CMD} -DSNIPPET=${SNIPPET}"
fi

echo ""
echo "Running: ${BUILD_CMD}"
echo ""

eval ${BUILD_CMD}

if [ -f "${BUILD_DIR}/zephyr/zmk.uf2" ]; then
  cp "${BUILD_DIR}/zephyr/zmk.uf2" "${OUTPUT_DIR}/${BOARD}.uf2"
  echo ""
  echo "=========================================="
  echo "Build successful!"
  echo "Firmware: ${OUTPUT_DIR}/${BOARD}.uf2"
  echo "=========================================="
else
  echo ""
  echo "=========================================="
  echo "Build completed but no .uf2 file found"
  echo "Check ${BUILD_DIR}/zephyr/ for output files"
  echo "=========================================="
fi
