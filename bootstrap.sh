#!/bin/bash
set -e

echo "=========================================="
echo " BOOTSTRAP NVIDIA DRIVER + ROS KEY FIX"
echo "=========================================="

### ------------------------------------------------
### 0) Pre-check: ต้องรันเป็น root
### ------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

### ------------------------------------------------
### 1) Check & Fix ROS key
### ------------------------------------------------
echo "[1/4] Checking ROS key..."

ROS_KEY_ID="F42ED6FBAB17C654"
ROS_KEY_PATH="/usr/share/keyrings/ros-archive-keyring.gpg"
ROS_LIST_FILE="/etc/apt/sources.list.d/ros-latest.list"

apt update --allow-releaseinfo-change > /tmp/ros_update_check.txt 2>&1 || true

if grep -q "EXPKEYSIG $ROS_KEY_ID" /tmp/ros_update_check.txt; then
    echo "→ ROS key expired, fixing..."
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o "$ROS_KEY_PATH"
    echo "deb [signed-by=$ROS_KEY_PATH] http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" \
        > "$ROS_LIST_FILE"
    echo "✔ ROS key fixed"
else
    echo "✔ ROS key valid"
fi


### ------------------------------------------------
### 2) NVIDIA driver install (safe mode)
### ------------------------------------------------
echo "[2/4] Preparing NVIDIA installation..."

# 2.1 install kernel headers
apt install -y linux-headers-$(uname -r)

# 2.2 blacklist nouveau
cat <<EOF > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

update-initramfs -u

# 2.3 Stop GUI
echo "→ Stopping display manager..."
systemctl stop gdm 2>/dev/null || true
systemctl stop lightdm 2>/dev/null || true
systemctl stop sddm 2>/dev/null || true

sleep 2

# 2.4 Download driver if missing
DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/580.105.08/NVIDIA-Linux-x86_64-580.105.08.run"
INSTALLER_DIR="./offline-nvidia-driver"
DRIVER="$INSTALLER_DIR/NVIDIA-Linux-x86_64-580.105.08.run"

mkdir -p $INSTALLER_DIR

if [ ! -f "$DRIVER" ]; then
    echo "→ Downloading NVIDIA driver..."
    wget -O "$DRIVER" "$DRIVER_URL"
fi

chmod +x "$DRIVER"

# 2.5 RUN INSTALLER
echo "→ Installing NVIDIA driver... (this may take a few minutes)"

sh "$DRIVER" \
    --silent \
    --no-nouveau-check \
    --no-cc-version-check \
    --disable-nouveau \
    --no-x-check

echo "✔ NVIDIA driver installed"


### ------------------------------------------------
### 3) Restart GUI
### ------------------------------------------------
echo "[3/4] Restarting GUI..."
systemctl start gdm 2>/dev/null || true
systemctl start lightdm 2>/dev/null || true
systemctl start sddm 2>/dev/null || true


### ------------------------------------------------
### 4) Final update
### ------------------------------------------------
echo "[4/4] Final apt update..."
apt update --allow-releaseinfo-change || true

echo "=========================================="
echo " INSTALL COMPLETED SUCCESSFULLY"
echo "=========================================="
