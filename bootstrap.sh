#!/usr/bin/env bash
set -euo pipefail

log() { printf '%s\n' "$*"; }

# -------- Config --------
ROS_KEY_ID="F42ED6FBAB17C654"
ROS_KEY_PATH="/usr/share/keyrings/ros-archive-keyring.gpg"
ROS_LIST_FILE="/etc/apt/sources.list.d/ros-latest.list"
ROS_KEY_URL="https://raw.githubusercontent.com/ros/rosdistro/master/ros.key"

DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/580.105.08/NVIDIA-Linux-x86_64-580.105.08.run"
DRIVER_FILE="NVIDIA-Linux-x86_64-580.105.08.run"

# ทำงานใน /tmp
WORKDIR="$(mktemp -d /tmp/bootstrap-nvidia-ros.XXXXXX)"
APT_LOG="$WORKDIR/apt_update_check.txt"
NVIDIA_RUN="$WORKDIR/$DRIVER_FILE"

cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

# sudo helper (ไม่บังคับให้รันด้วย sudo ตั้งแต่แรก)
SUDO="sudo"
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  SUDO=""
fi

log "=========================================="
log "BOOTSTRAP NVIDIA DRIVER + ROS KEY FIX"
log "WORKDIR: $WORKDIR"
log "=========================================="

# ------------------------------------------------
# 1) Check & Fix ROS key if expired
# ------------------------------------------------
log "[1/3] Checking ROS key (apt update)..."

set +e
$SUDO apt-get update --allow-releaseinfo-change >"$APT_LOG" 2>&1
APT_RC=$?
set -e

EXPIRED=false
if grep -q "EXPKEYSIG $ROS_KEY_ID" "$APT_LOG"; then
  EXPIRED=true
fi

if [[ "$EXPIRED" == "true" ]]; then
  log "ROS key expired. Fixing..."

  # ลบ key เก่า (บางเครื่องไม่มี apt-key แล้ว ก็ไม่เป็นไร)
  $SUDO apt-key del "$ROS_KEY_ID" >/dev/null 2>&1 || true

  # ดาวน์โหลด key ลง /tmp ก่อน แล้วค่อยติดตั้งเข้าที่ system
  curl -fsSL "$ROS_KEY_URL" -o "$WORKDIR/ros.key"
  $SUDO install -m 0644 "$WORKDIR/ros.key" "$ROS_KEY_PATH"

  # เขียน source list (ใช้ signed-by แบบใหม่)
  CODENAME="$(lsb_release -sc)"
  $SUDO tee "$ROS_LIST_FILE" >/dev/null <<EOF
deb [signed-by=$ROS_KEY_PATH] http://packages.ros.org/ros/ubuntu $CODENAME main
EOF

  log "ROS key updated."
else
  log "ROS key looks OK."
fi

# ------------------------------------------------
# 2) Download & Install NVIDIA Driver
# ------------------------------------------------
log "[2/3] Downloading NVIDIA driver to /tmp (if needed)..."

if [[ ! -f "$NVIDIA_RUN" ]]; then
  curl -fL "$DRIVER_URL" -o "$NVIDIA_RUN"
fi
chmod +x "$NVIDIA_RUN"

log "Running NVIDIA installer (silent)..."
# ตัวติดตั้งต้องมีสิทธิ์ root
$SUDO sh "$NVIDIA_RUN" --silent --no-nouveau-check --no-cc-version-check

log "NVIDIA driver install step completed."

# ------------------------------------------------
# 3) Final apt update
# ------------------------------------------------
log "[3/3] Final apt update..."
set +e
$SUDO apt-get update --allow-releaseinfo-change
set -e

log "=========================================="
log "BOOTSTRAP COMPLETED"
log "=========================================="

# ถ้า apt update ตอนแรก fail ให้แจ้งไว้ท้าย (แต่ไม่ทำให้สคริปต์ล้ม)
if [[ $APT_RC -ne 0 ]]; then
  log "Note: initial apt update returned code $APT_RC. See log: $APT_LOG"
fi
