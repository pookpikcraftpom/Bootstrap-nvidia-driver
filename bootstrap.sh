#!/bin/bash
set -e

echo "============================================"
echo " BOOTSTRAP NVIDIA DRIVER + ROS KEY FIX (V2)"
echo "============================================"

# กำหนดตัวแปรสำคัญ
DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/580.105.08/NVIDIA-Linux-x86_64-580.105.08.run"
DRIVER_FILE="NVIDIA-Linux-x86_64-580.105.08.run"
INSTALLER_DIR="./offline-nvidia-driver"
NVIDIA_RUN="$INSTALLER_DIR/$DRIVER_FILE"

### ------------------------------------------------
### 1) Check & Fix ROS key if expired
### ------------------------------------------------
echo "[1/4] Checking ROS key..."

ROS_KEY_ID="F42ED6FBAB17C654"
ROS_KEY_PATH="/usr/share/keyrings/ros-archive-keyring.gpg"
ROS_LIST_FILE="/etc/apt/sources.list.d/ros-latest.list"
EXPIRED=false

apt update --allow-releaseinfo-change > /tmp/ros_update_check.txt 2>&1 || true

if grep -q "EXPKEYSIG $ROS_KEY_ID" /tmp/ros_update_check.txt; then
    echo "❌ ROS key expired!"
    EXPIRED=true
else
    echo "✔ ROS key valid (not expired)"
fi

if [ "$EXPIRED" = true ]; then
    echo "→ Fixing ROS key ..."
    apt-key del "$ROS_KEY_ID" 2>/dev/null || true

    curl -sSL "https://raw.githubusercontent.com/ros/rosdistro/master/ros.key" \
        -o "$ROS_KEY_PATH"

    bash -c "echo \
    'deb [signed-by=$ROS_KEY_PATH] http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main' \
    > $ROS_LIST_FILE"

    echo "✔ ROS key updated"
fi


### ------------------------------------------------
### 2) Install Prerequisites (Essential Build Tools)
### ------------------------------------------------
echo "[2/4] Installing essential build tools..."

# ติดตั้งเครื่องมือพื้นฐาน, dkms, และ Headers ให้ตรงกับ Kernel ปัจจุบัน
apt install -y build-essential dkms linux-headers-$(uname -r) || { 
    echo "ERROR: Failed to install essential tools (build-essential, dkms, headers). Installation aborted."; 
    exit 1; 
}
echo "✔ Essential tools installed."


### ------------------------------------------------
### 3) Cleanup Conflicting Drivers
### ------------------------------------------------
echo "[3/4] Cleaning up conflicting drivers (Nouveau and old NVIDIA packages)..."
# ลบไดรเวอร์ NVIDIA ที่ติดตั้งผ่าน apt และ Nouveau เพื่อแก้ปัญหา "alternate driver"
apt purge -y nvidia-* nouveau* || true
apt autoremove -y || true
echo "✔ Conflicting drivers removed."


### ------------------------------------------------
### 4) Download & Install NVIDIA Driver
### ------------------------------------------------
echo "[4/4] Checking/Downloading & Installing NVIDIA driver"

mkdir -p "$INSTALLER_DIR"

if [ ! -f "$NVIDIA_RUN" ]; then
    echo "→ Driver not found locally. Downloading with wget..."
    wget -O "$NVIDIA_RUN" "$DRIVER_URL" || { 
        echo "ERROR: Failed to download NVIDIA driver. Check URL."; 
        exit 1; 
    }
    echo "✔ Download complete."
else
    echo "→ Found local driver. Skipping download."
fi

echo "→ Installer path set to: $NVIDIA_RUN"

chmod +x "$NVIDIA_RUN"

echo "→ Running installer (silent mode, forcing install over X server)..."
# ใช้ --no-x-check เพื่อบังคับติดตั้งแม้มี X Server ทำงานอยู่
sh "$NVIDIA_RUN" \
    --silent \
    --no-nouveau-check \
    --no-cc-version-check \
    --no-x-check \
    || { 
        echo "ERROR: NVIDIA installer failed. Please see /var/log/nvidia-installer.log for details."; 
        exit 1; 
    }

echo "✔ NVIDIA driver installed successfully."


### ------------------------------------------------
### 5) Final apt update & Complete
### ------------------------------------------------
echo "→ Finishing apt update..."
apt update --allow-releaseinfo-change || true

echo "============================================"
echo " BOOTSTRAP COMPLETED SUCCESSFULLY"
echo "============================================"
# ❗ (ควรสั่ง reboot จากภายนอกสคริปต์นี้เพื่อให้ไดรเวอร์ใหม่ทำงาน)
