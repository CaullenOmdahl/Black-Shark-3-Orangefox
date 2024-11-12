#!/bin/bash

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
        print_status "Setting up Git user email..."
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    fi
    
    if [ -z "$(git config --global user.name)" ]; then
        print_status "Setting up Git user name..."
        read -p "Enter your Git name: " git_name
        git config --global user.name "$git_name"
    fi
}

# Install required packages
install_packages() {
    print_status "Installing required packages..."
    sudo apt update
    sudo apt install -y \
        git-core gnupg flex bison build-essential zip curl zlib1g-dev \
        gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev \
        x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils \
        xsltproc unzip fontconfig python2.7 python-is-python2 aria2 \
        android-sdk-platform-tools adb fastboot repo openjdk-8-jdk
}

# Setup Python 2 as default for building
setup_python() {
    print_status "Setting up Python environment..."
    if ! command -v python2.7 &> /dev/null; then
        sudo apt install -y python2.7
    fi
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 2
    sudo update-alternatives --set python /usr/bin/python2.7
}

# Setup build environment
setup_environment() {
    print_status "Setting up build environment..."
    
    # Initialize repo tool
    if [ ! -d "OrangeFox_sync" ]; then
        print_status "Initializing sync tool..."
        mkdir ~/OrangeFox_sync
        cd OrangeFox_sync
        git clone https://gitlab.com/OrangeFox/sync.git
        cd sync
        ./orangefox_sync.sh --branch 11.0 --path ~/fox_11.0
    fi
    
    # Clone necessary repositories
    if [ ! -d "scripts" ]; then
        git clone https://gitlab.com/OrangeFox/misc/scripts
        cd scripts
        sudo bash setup/android_build_env.sh
        sudo bash setup/install_android_sdk.sh
        cd ~/
    fi
}

# Setup device tree
setup_device_tree() {
    print_status "Setting up device tree..."
    cd ~/fox_11.0
    
    # Clone device tree
    if [ ! -d "device/blackshark/" ]; then
        mkdir -p device/blackshark
        git clone https://github.com/CaullenOmdahl/Blackshark-3-TWRP-Device-Tree device/blackshark/
    fi

    # Clone theme
    if [ ! -d "bootable/recovery/gui/theme" ]; then
        mkdir -p bootable/recovery/gui
        git clone https://gitlab.com/OrangeFox/misc/theme.git bootable/recovery/gui/theme
    fi
}

# Create roomservice.xml
create_roomservice() {
    print_status "Creating roomservice.xml..."
    mkdir -p ~/.repo/local_manifests
    cat > ~/.repo/local_manifests/roomservice.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <project path="device/blackshark/klein"
             name="CaullenOmdahl/Blackshark-3-TWRP-Device-Tree"
             remote="github"
             revision="main" />
</manifest>
EOF
}

# Build OrangeFox
build_recovery() {
    print_status "Starting build process..."
    cd ~/fox_11.0
    
    # Set up build environment
    if [ -f "build/envsetup.sh" ]; then
        source build/envsetup.sh
    else
        print_error "build/envsetup.sh not found! Build environment setup failed."
        exit 1
    fi
    
    # Export necessary variables
    export ALLOW_MISSING_DEPENDENCIES=true
    export FOX_BUILD_DEVICE="klein"
    export LC_ALL="C"
    export FOX_AB_DEVICE=1

    # Build for A/B device
    lunch omni_klein-eng
    mka adbd bootimage
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check available disk space (need at least 100GB)
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
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
    print_status "Starting OrangeFox build process for BlackShark SHARK KLE-H0..."
    
    check_requirements
    setup_git
    install_packages
    setup_python
    setup_environment
    setup_device_tree
    create_roomservice
    build_recovery
    
    print_status "Build process completed!"
}

# Execute main function
main