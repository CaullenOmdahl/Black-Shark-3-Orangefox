# Device Tree for BlackShark SHARK KLE-H0 (klein)

This document provides a comprehensive overview of the device tree for the BlackShark SHARK KLE-H0 (codename: klein) used for building TWRP Recovery.

## Device Specifications

### Hardware
- **SoC**: Qualcomm Kona (SM8250)
- **CPU**: 
  - **Primary**: ARM64 (armv8-a)
  - **Secondary**: ARM (armv7-a-neon)
- **Architecture**: 
  - **Primary**: arm64-v8a (Kryo 300)
  - **Secondary**: armeabi-v7a (Cortex-A75)
- **Screen Density**: 440 DPI

### Software
- **Android Version**: 11
- **Build Number**: KLEN2108271OS00MR0
- **JOYUI Version**: V11.0.4.0
- **Security Patch Level**: 2021-08-01

## Build Information

### Partitions
- **Dynamic Partitions**: Yes
- **Super Partition Size**: 9,126,805,504 bytes
- **Dynamic Partitions List**: system, system_ext, product, vendor, odm
- **File System**: 
  - **System**: ext4
  - **Data**: f2fs/ext4
  - **Vendor**: ext4

### A/B Partitioning
- **A/B Device**: Yes
- **A/B Partitions**:
  - odm
  - system
  - product
  - system_ext
  - vendor

### Kernel
- **Source**: kernel/blackshark/klein
- **Config**: klein_defconfig
- **Base Address**: 0x00000000
- **Page Size**: 4096
- **Kernel Image**: Image
- **DTB Support**: Yes
- **DTBO**: Separated

## Building

### Build Environment

1. **Initialize your build environment**:
   ```bash
   . build/envsetup.sh
   ```

2. **Choose a build target**:
   ```bash
   lunch omni_klein-eng
   ```
   or
   ```bash
   lunch omni_klein-user
   ```
   or
   ```bash
   lunch omni_klein-userdebug
   ```

### Required Packages
To build the device, ensure the following packages are included:
```bash
android.hardware.boot@1.0-impl
android.hardware.boot@1.0-service
bootctrl.kona
bootctrl.kona.recovery
libgptutils
libz
libcutils
```

## Notes
- The device uses TWRP with a portrait HDPI theme.
- Supports additional languages.
- Utilizes Toolbox.
- Includes repacktools.
- Uses recovery as boot.

## Credits
- SebaUbuntu's TWRP device tree generator
- The Android Open Source Project
- LineageOS Project
- CyanogenMod Project

## License
This project is licensed under the Apache License 2.0.

## Additional Information
This README is based on information from the following files:

### Architecture
```makefile
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 := 
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a75
```

### A/B Configuration
```makefile
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true
```

### Boot Control HAL
```makefile
PRODUCT_PACKAGES += \
    android.hardware.boot@1.0-impl \
    android.hardware.boot@1.0-service \
    bootctrl.kona \
    bootctrl.kona.recovery
```

### Additional Dependencies
```makefile
PRODUCT_PACKAGES += \
    libgptutils \
    libz \
    libcutils
```

### Product Information
```makefile
PRODUCT_DEVICE := klein
PRODUCT_NAME := omni_klein
PRODUCT_BRAND := blackshark
PRODUCT_MODEL := SHARK KLE-H0
PRODUCT_MANUFACTURER := blackshark

PRODUCT_GMS_CLIENTID_BASE := android-blackshark

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="KLE-H0-user 11 KLEN2108271OS00MR0 V11.0.4.0.JOYUI release-keys"

BUILD_FINGERPRINT := blackshark/KLE-H0/klein:11/KLEN2108271OS00MR0/V11.0.4.0.JOYUI:user/release-keys
```