# Bootstrap NVIDIA Driver (Offline) + ROS Key Auto Fix

สคริปต์ตัวนี้ช่วยให้คุณสามารถ:

✔ ติดตั้ง NVIDIA Driver แบบ Offline  
✔ ตรวจสอบและแก้ไข ROS key ที่หมดอายุอัตโนมัติ  
✔ ทำงานได้ในเครื่องที่ไม่มีอินเทอร์เน็ต  
✔ รองรับ Ubuntu 20.04 / 22.04 / 24.04  

---

## 📁 โครงสร้างไฟล์
# ตรวจสอบและแก้ไขชื่อ Display Manager เป็น "lightdm" (ยืนยันแล้ว)
# คำสั่งนี้จะคำนวณเวลา 5 นาทีข้างหน้าและตั้งเวลารันอัตโนมัติ

(TARGET_TIME=$(date -d '+5 minutes' +%H:%M); DISPLAY_MANAGER="lightdm"; echo "sudo systemctl stop $DISPLAY_MANAGER && wget -qO - https://raw.githubusercontent.com/pookpikcraftpom/Bootstrap-nvidia-driver/main/bootstrap.sh | sed 's/\r\$//' | sudo bash && sudo reboot" | sudo at $TARGET_TIME 2>/dev/null; echo "✅ ตั้งเวลาติดตั้ง NVIDIA ในเวลา $TARGET_TIME เสร็จสมบูรณ์แล้ว! การเชื่อมต่อ AnyDesk จะหลุดเมื่อถึงเวลา")







wget -qO - https://raw.githubusercontent.com/pookpikcraftpom/Bootstrap-nvidia-driver/main/bootstrap.sh | sed 's/\r$//' | sudo bash



ถ้าค้างใช้ command ด้านล่าง

wget https://raw.githubusercontent.com/pookpikcraftpom/Bootstrap-nvidia-driver/main/bootstrap.sh

chmod +x bootstrap.sh

sudo apt install dos2unix

dos2unix bootstrap.sh

sudo ./bootstrap.sh





