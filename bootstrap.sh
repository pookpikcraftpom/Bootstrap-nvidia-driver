#!/bin/bash
 set -e
 
 echo "=========================================="
 echo " BOOTSTRAP NVIDIA DRIVER + ROS KEY FIX"
 echo "=========================================="
 
 ### ------------------------------------------------
 ### 1) Check & Fix ROS key if expired
 ### ------------------------------------------------
 echo "[1/3] Checking ROS key..."
 
 ROS_KEY_ID="F42ED6FBAB17C654"
 ROS_KEY_PATH="/usr/share/keyrings/ros-archive-keyring.gpg"
 ROS_LIST_FILE="/etc/apt/sources.list.d/ros-latest.list"
 
 EXPIRED=false
 
 # Run apt update first (check expiry)
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
 ### 2) Download & Install NVIDIA Driver
 ### ------------------------------------------------
 echo "[2/3] Checking/Downloading NVIDIA driver"
 
 DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/580.105.08/NVIDIA-Linux-x86_64-580.105.08.run"
 DRIVER_FILE="NVIDIA-Linux-x86_64-580.105.08.run"
 INSTALLER_DIR="./offline-nvidia-driver"
 NVIDIA_RUN="$INSTALLER_DIR/$DRIVER_FILE"
 
 # สร้างโฟลเดอร์ (ไม่ใช้ sudo เพราะสคริปต์รันด้วย sudo อยู่แล้ว)
 mkdir -p "$INSTALLER_DIR"
 
 if [ ! -f "$NVIDIA_RUN" ]; then
 echo "→ Driver not found locally. Downloading with wget..."
 # ใช้ wget (ไม่ใช้ sudo)
 wget -O "$NVIDIA_RUN" "$DRIVER_URL"
 echo "✔ Download complete."
 else
 echo "→ Found local driver. Skipping download."
 fi
 
 echo "→ Installer path set to:"
 echo " $NVIDIA_RUN"
 
 # ให้สิทธิ์ (ไม่ใช้ sudo)
 chmod +x "$NVIDIA_RUN"
 
 echo "→ Running installer (silent mode)..."
 # รันตัวติดตั้ง (ไม่ใช้ sudo)
 sh "$NVIDIA_RUN" --silent --no-nouveau-check --no-cc-version-check
 
 echo "✔ NVIDIA driver installed successfully."
 
 
 ### ------------------------------------------------
 ### 3) Final apt update
 ### ------------------------------------------------
 echo "[3/3] Finishing apt update..."
 apt update --allow-releaseinfo-change || true
 
 echo "=========================================="
 echo " BOOTSTRAP COMPLETED SUCCESSFULLY"
 echo "=========================================="
