#!/bin/bash

export PATH=~/bin:$PATH

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] ${1}${NC}"
}

print_error() {
    echo -e "${RED}[!] ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] ${1}${NC}"
}

# Configure Git
setup_git() {
    print_status "Configuring Git..."
    if [ -z "$(git config --global user.email)" ]; then
        git config --global user.email "Caullen.Omdahl@gmail.com"
    fi

    if [ -z "$(git config --global user.name)" ]; then
        git config --global user.name "CaullenOmdahl"
    fi
}

# Install required packages
install_packages() {
    print_status "Installing required packages..."
    sudo apt update
    sudo apt install -y \
        git gnupg flex bison build-essential zip curl zlib1g-dev \
        gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses-dev \
        x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils \
        xsltproc unzip fontconfig aria2 \
        android-sdk-platform-tools adb fastboot openjdk-8-jdk python2
}

# Install repo tool
install_repo() {
    print_status "Installing the repo command..."
    mkdir -p ~/bin
    if [ ! -f ~/bin/repo ]; then
        curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
        chmod a+x ~/bin/repo
    fi
}

# Setup Python environment
setup_python() {
    print_status "Setting up Python environment..."
    # Update alternatives to use python2
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python2 1
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 2
    sudo update-alternatives --set python /usr/bin/python2
}

# Create roomservice.xml
create_roomservice() {
    print_status "Creating roomservice.xml..."
    mkdir -p "$HOME/fox_11.0/.repo/local_manifests"
    cat > "$HOME/fox_11.0/.repo/local_manifests/roomservice.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <remote name="github-caullen" fetch="https://github.com/CaullenOmdahl/" />
    <project path="device/blackshark"
             name="Blackshark-3-TWRP-Device-Tree"
             remote="github-caullen"
             revision="main" />
</manifest>
EOF
}

# Setup build environment
setup_environment() {
    print_status "Setting up build environment..."
    mkdir -p "$HOME/OrangeFox_sync"
    cd "$HOME/OrangeFox_sync"
    if [ ! -d "sync" ]; then
        git clone https://gitlab.com/OrangeFox/sync.git
    else
        print_status "OrangeFox sync repository already exists. Updating..."
        cd sync
        git pull
        cd ..
    fi
    cd sync

    # Create roomservice.xml to include device tree during sync
    create_roomservice

    # Sync OrangeFox sources
    if [ ! -d "$HOME/fox_11.0" ]; then
        print_status "Syncing OrangeFox source code..."
        ./orangefox_sync.sh --branch 11.0 --path "$HOME/fox_11.0"
    else
        print_status "OrangeFox source code already exists. Updating..."
        cd "$HOME/fox_11.0"
        repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune
        cd -
    fi
}

# Clone missing repositories
clone_additional_repos() {
    print_status "Cloning additional repositories..."
    cd "$HOME/fox_11.0"
    # Clone vendor/twrp if missing
    if [ ! -d "vendor/twrp" ]; then
        mkdir -p vendor
        cd vendor
        git clone https://github.com/TeamWin/android_vendor_twrp.git twrp
        cd ../
    else
        print_status "vendor/twrp already exists. Updating..."
        cd vendor/twrp
        git pull
        cd ../../
    fi
    # Clone vendor/recovery if missing
    if [ ! -d "vendor/recovery" ]; then
        mkdir -p vendor
        cd vendor
        git clone https://gitlab.com/OrangeFox/vendor/recovery.git recovery
        cd ../
    else
        print_status "vendor/recovery already exists. Updating..."
        cd vendor/recovery
        git pull
        cd ../../
    fi
    # Clone bootable/recovery if missing
    if [ ! -d "bootable/recovery" ]; then
        mkdir -p bootable
        cd bootable
        git clone https://gitlab.com/OrangeFox/android_bootable_recovery.git recovery
        cd ../
    else
        print_status "bootable/recovery already exists. Updating..."
        cd bootable/recovery
        git pull
        cd ../../
    fi
}

# Fix obsolete variables and syntax in device tree
fix_device_tree() {
    print_status "Fixing device tree issues..."
    DEVICE_MK="$HOME/fox_11.0/device/blackshark/klein/device.mk"

    # Remove obsolete PRODUCT_STATIC_BOOT_CONTROL_HAL
    if grep -q "PRODUCT_STATIC_BOOT_CONTROL_HAL" "$DEVICE_MK"; then
        sed -i '/PRODUCT_STATIC_BOOT_CONTROL_HAL/d' "$DEVICE_MK"
        echo 'PRODUCT_PACKAGES += libbootcontrol' >> "$DEVICE_MK"
        print_status "Replaced obsolete PRODUCT_STATIC_BOOT_CONTROL_HAL with libbootcontrol."
    fi

    # Ensure proper indentation and separators in device.mk
    sed -i 's/^[ ]\+/\t/' "$DEVICE_MK"

    # Fix any missing backslashes in device.mk
    sed -i '/^[^#].*[^\\]$/ s/$/ \\/' "$DEVICE_MK"

    # Fix vendorsetup.sh to remove obsolete commands
    VENDOR_SETUP="$HOME/fox_11.0/device/blackshark/klein/vendorsetup.sh"
    if [ -f "$VENDOR_SETUP" ]; then
        sed -i '/add_lunch_combo/d' "$VENDOR_SETUP"
        print_status "Removed obsolete add_lunch_combo from vendorsetup.sh."
    fi

    # Ensure vendorsetup.sh is executable
    chmod +x "$VENDOR_SETUP"

    # Define COMMON_LUNCH_CHOICES in AndroidProducts.mk
    ANDROID_PRODUCTS_MK="$HOME/fox_11.0/device/blackshark/klein/AndroidProducts.mk"
    if [ -f "$ANDROID_PRODUCTS_MK" ]; then
        if ! grep -q "COMMON_LUNCH_CHOICES" "$ANDROID_PRODUCTS_MK"; then
            echo -e '\nCOMMON_LUNCH_CHOICES += \\' >> "$ANDROID_PRODUCTS_MK"
            echo '    omni_klein-eng \\' >> "$ANDROID_PRODUCTS_MK"
            echo '    omni_klein-userdebug' >> "$ANDROID_PRODUCTS_MK"
            print_status "Added COMMON_LUNCH_CHOICES to AndroidProducts.mk."
        fi
    fi
}

# Build OrangeFox
build_recovery() {
    print_status "Starting build process..."
    cd "$HOME/fox_11.0"

    # Set up build environment
    if [ -f "build/envsetup.sh" ]; then
        source build/envsetup.sh
    else
        print_error "build/envsetup.sh not found! Build environment setup failed."
        exit 1
    fi

    # Export necessary variables
    export ALLOW_MISSING_DEPENDENCIES=true
    export LC_ALL="C"

    # Remove sourcing of vendorsetup.sh
    # source "$VENDOR_SETUP"  # Remove or comment out this line

    # Use lunch to select the device
    lunch omni_klein-eng

    # Clean previous builds
    print_status "Cleaning previous builds..."
    mka clean

    # Start the build
    mka recoveryimage
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."

    # Check available disk space (need at least 100GB)
    available_space=$(df -BG ~ | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 100 ]; then
        print_error "Insufficient disk space. Need at least 100GB, have ${available_space}GB"
        exit 1
    fi

    # Check RAM (need at least 16GB)
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 16 ]; then
        print_error "Insufficient RAM. Need at least 16GB, have ${total_ram}GB"
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting OrangeFox build process for Black Shark 3 (Klein)..."

    check_requirements
    setup_git
    install_packages
    install_repo
    setup_python
    setup_environment
    clone_additional_repos
    fix_device_tree
    build_recovery

    print_status "Build process completed!"
}

# Execute main function
main
