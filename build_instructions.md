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
    # Ensure pip for Python 2 is installed
    if ! command -v pip2 &> /dev/null; then
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
        sudo python2 get-pip.py
        rm get-pip.py
    fi
}

# Setup build environment
setup_environment() {
    print_status "Setting up build environment..."
    mkdir -p ~/OrangeFox_sync
    cd ~/OrangeFox_sync
    if [ ! -d "sync" ]; then
        git clone https://gitlab.com/OrangeFox/sync.git
    fi
    cd sync
    ./orangefox_sync.sh --branch 11.0 --path ~/fox_11.0
}

# Setup device tree
setup_device_tree() {
    print_status "Setting up device tree..."
    cd ~/fox_11.0
    git clone https://github.com/CaullenOmdahl/Blackshark-3-TWRP-Device-Tree device/blackshark/klein
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
    lunch orangefox_klein-eng
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
    setup_device_tree
    build_recovery

    print_status "Build process completed!"
}

# Execute main function
main
