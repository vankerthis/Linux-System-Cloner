# Linux System Cloner

## Overview
This script allows you to **clone a Linux system** onto another disk partition, making it bootable and fully operational. The cloned system becomes **the primary OS** in the GRUB boot menu, while all other systems are correctly recognized and added.

### Features:
- ✅ Clone either a **running system (`/`)** or **a mounted partition (`/mnt/...`)**  
- ✅ GRUB **automatically sets the clone as the default system**  
- ✅ fstab modification — **only the root (`/`) entry is updated**  
- ✅ Optional disk cleanup (`--delete`) for **accurate replication**  
- ✅ Prevents conflicts with boot files — **excludes `/boot` from cloning**  

---

## Installation & Usage
### Step 1: Download the script
```bash
git clone https://github.com/<your-repository>/Linux-System-Cloner.git
cd Linux-System-Cloner
chmod +x clone_system.sh
```
### Step 2: Run the script
```bash
sudo ./clone_system.sh <SOURCE> <TARGET_PARTITION>
```
#### Examples:
- Cloning a running system:
```bash
sudo ./clone_system.sh / /dev/sdb1
```
- Cloning a mounted partition:
```bash
sudo ./clone_system.sh /mnt/original-system /dev/sdb1
```
### Step 3: Reboot the system
After cloning is complete, restart your computer, enter GRUB, and select the newly cloned system.

### Philosophy of the Script
This project is not just a tool, it's an educational resource.

🔹 The main goal is to help users understand Linux cloning, GRUB booting, and system configurations.

🔹 Always clone under personal supervision — automation is useful, but understanding the process is crucial.

🔹 If something doesn’t work, explore the script’s code — every step can be executed manually!

💡 This script is your personal learning guide for Linux cloning.

### Additional Information

#### Automatic Disk Check
Before cloning, the script scans the target partition after mounting it. If it detects existing files, it prompts the user to delete them for a clean clone.

#### GRUB & fstab Modifications
* GRUB is installed within the cloned system
* Boot menu is updated from inside the clone
* fstab is adjusted → only the root (/) entry is modified, keeping all other mount points unchanged.

### License
This project is distributed under the MIT License. You are free to use, modify, and share it.

Author:Ilia GitHub: [Your Repository Link]