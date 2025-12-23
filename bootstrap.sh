#!/bin/sh
set -e

ROS_KEY_ID="F42ED6FBAB17C654"
ROS_KEY_PATH="/usr/share/keyrings/ros-archive-keyring.gpg"
ROS_LIST_FILE="/etc/apt/sources.list.d/ros-latest.list"
ROS_KEY_URL="https://raw.githubusercontent.com/ros/rosdistro/master/ros.key"

DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/580.105.08/NVIDIA-Linux-x86_64-580.105.08.run"
DRIVER_FILE="NVIDIA-Linux-x86_64-580.105.08.run"

WORKDIR="$(mktemp -d /tmp/bootstrap.XXXXXX)"
APT_LOG="$WORKDIR/apt_update.txt"
NVIDIA_RUN="$WORKDIR/$DRIVER_FILE"

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

echo "[1/3] apt update check"
$SUDO apt-get update --allow-releaseinfo-change >"$APT_LOG" 2>&1 || true

if grep -q "EXPKEYSIG $ROS_KEY_ID" "$APT_LOG"; then
  echo "fix ros key"
  $SUDO apt-key del "$ROS_KEY_ID" || true
  curl -fsSL "$ROS_KEY_URL" -o "$WORKDIR/ros.key"
  $SUDO install -m 0644 "$WORKDIR/ros.key" "$ROS_KEY_PATH"
  CODENAME="$(lsb_release -sc)"
  echo "deb [signed-by=$ROS_KEY_PATH] http://packages.ros.org/ros/ubuntu $CODENAME main" | $SUDO tee "$ROS_LIST_FILE"
fi

echo "[2/3] download nvidia driver"
curl -fL "$DRIVER_URL" -o "$NVIDIA_RUN"
chmod +x "$NVIDIA_RUN"

echo "install nvidia driver"
$SUDO sh "$NVIDIA_RUN" --silent --no-nouveau-check --no-cc-version-check

echo "[3/3] final apt update"
$SUDO apt-get update --allow-releaseinfo-change || true

echo "done"
