# Building OrangeFox

## Requirements
- **Disk Space**: You will need a minimum of **60GB** free space on your PC/Server. It is recommended to provide about **double** that amount. This space is needed for:
  - The build system itself (about 35GB-45GB, depending on the manifest version).
  - Device trees.
  - The actual build (between 8GB to 12GB for each device).
  - ccache's cache (if you use ccache).

- **RAM**: 
  - For the **11.0** manifest, a minimum of **16GB RAM** is required (20GB is better).
  - For the **12.1** manifest, a minimum of **20GB RAM** is required (24GB is better).
  - Insufficient RAM will lead to random build errors.

- **Operating System**: A proper and full **Linux development system** (note: "Linux" - NOT "Windows"). A Debian-based Linux distro (e.g., Ubuntu 20.04, Linux Mint 21.1) with a full development environment is recommended (including Java, GCC, etc.). If you use any other Linux distro, you are on your own.

- **Python**: Python **2.x** is required (to find out your Python version, run `python -V`; if it is not v2.x, then you need to symlink Python to whatever Python 2 version is installed on your system) - only if you're using older OrangeFox sources.

- **Device Tree**: OrangeFox/TWRP device tree for the device.

- **Shell**: Up-to-date **bash shell** (note: "bash", NOT "zsh", or "tcsh", or "ksh", or "csh", or "dash", or any other shell).

- **Note**: Do **NOT** build as root.

## Initial Build of OrangeFox

### 0. Prepare the Build Environment (Debian-based Linux Distros)
```bash
cd ~
sudo apt install git aria2 -y
git clone https://gitlab.com/OrangeFox/misc/scripts
cd scripts
sudo bash setup/android_build_env.sh
sudo bash setup/install_android_sdk.sh
```

### 1. Sync OrangeFox Sources and Minimal Manifest
Using the sync shell script from the "sync" repository; do **NOT** run this as root. The example below uses a script to sync the `fox_12.1` branch.

- This method requires familiarity with Linux shell scripts.
- If you want to build for Android 12 and higher ROMs, sync the `fox_12.1` branch. If you want to build for Android 11 ROMs, sync the `fox_11.0` branch.

```bash
mkdir ~/OrangeFox_sync
cd ~/OrangeFox_sync
git clone https://gitlab.com/OrangeFox/sync.git
cd ~/OrangeFox_sync/sync/
./orangefox_sync.sh --branch 12.1 --path ~/fox_12.1
```

**Tip**: The version number of the build manifest is very different from the OrangeFox release version numbers. If you have synced as shown above, you already have the sources for the latest OrangeFox Stable releases for whichever branch you have synced.

**Notes**:
- The process of syncing the sources will take a long time. Depending on your internet connection speed and the syncing method, it can take hours.
- After building, your build may have problems with decryption. If this happens, you will need to work on your device tree.

### 2. Place Device Trees and Kernel
You have to place your device trees and kernels in the proper locations. For example:
```bash
cd ~/fox_12.1
git clone https://gitlab.com/OrangeFox/device/lavender.git device/xiaomi/lavender
```

**What if there is no device tree for my device?**
- Amend the OrangeFox/TWRP device tree for a device with similar specifications, or create a new device tree from scratch, either manually or by editing a template produced by some sort of "twrpgen" site (this is not a trivial task).

### 3. Build It
```bash
cd ~/OrangeFox
/bin/bash # if your Linux shell isn't bash
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=<device>
export LC_ALL="C"

# For all branches
source build/envsetup.sh

# For the 11.0 (or higher) branch, if the device has a separate recovery partition
lunch twrp_<device>-eng && mka adbd recoveryimage

# For the 11.0 (or higher) branch, with A/B partitioning, and no separate recovery partition
lunch twrp_<device>-eng && mka adbd bootimage

# For the 12.1 (or higher) branch, vendor_boot-as-recovery builds [this is highly experimental and unsupported!]
lunch twrp_<device>-eng && mka adbd vendorbootimage
```

### Building Tips
- If you encounter errors related to anything with a ".py" extension or anything containing "py2", it means you need to install Python 2.x. Run `python --version` to check your default version.
- Ensure that your default Python for building is Python 2.x.
- If you get build errors related to "ui.xml for TW_THEME", ensure that the `bootable/recovery/gui/theme/` directory has been properly synced. You might need to run:
  ```bash
  git clone https://gitlab.com/OrangeFox/misc/theme.git bootable/recovery/gui/theme
  ```
- If the device is not a Xiaomi MIUI device, consider adding:
  ```bash
  export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
  ```
  or
  ```bash
  export FOX_VANILLA_BUILD=1
  ```

### If the Build Fails Because the Size of the Recovery is Too Big
1. If the kernel supports LZMA compression, use:
   ```bash
   export OF_USE_LZMA_COMPRESSION=1
   ```
2. Use:
   ```bash
   export FOX_DRASTIC_SIZE_REDUCTION=1
   ```
   (this must come after all other exports).
3. Other potential ways to reduce the size of the recovery image:
   - Disable extra languages in `BoardConfig.mk`: `TW_EXTRA_LANGUAGES :=`
   - Disable NTFS_3G in `BoardConfig.mk`: `TW_INCLUDE_NTFS_3G :=`
   - Disable some other features in `BoardConfig.mk`:
     ```bash
     TW_EXCLUDE_TZDATA := true
     TW_EXCLUDE_LPDUMP := true
     ```

### Final Recovery Image
If there were no errors during compilation, the final recovery image will be present in:
```
out/target/product/[device]/OrangeFox-unofficial-[device].img
```

### Help
If you want help/support with respect to building OrangeFox for your device, go to the [OrangeFox Recovery Discord server](https://wiki.orangefox.tech/en/dev/building).

Make sure to follow the rules of the Telegram and Discord groups to avoid warnings or bans.

If you encounter build errors or issues booting up a successful build, provide:
- A link to your device tree (exact version used).
- A link to a full log of your entire build process (do NOT just post screenshots).
- A list of all the exact commands used in building.

For detailed assistance, provide:
- A detailed account of what you tried and what happened.
- A full account of the OrangeFox build variables used.
- A logcat if booting is unsuccessful, or recovery logs if the recovery is not behaving correctly.

**Do NOT post vague messages like "it doesn't boot" or "it fails". Provide detailed information for effective help.**

### Configurations
OrangeFox has many configurations and build variables ("build vars") that give developers control over the features built into the recovery. You should put the OrangeFox-specific build vars in a shell script or in `vendorsetup.sh` in your device tree.

**Note**: Do NOT put OrangeFox-specific build variables that start with "FOX_" in `BoardConfig.mk` - they will not be processed properly if they are in any ".mk" file.

### Additional Resources
- [OrangeFox Sync Repository](https://gitlab.com/OrangeFox/sync)
- [OrangeFox Building Instructions](https://wiki.orangefox.tech/en/dev/building)