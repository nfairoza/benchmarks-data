#!/bin/bash
#
# Benchmark Environment Setup Script
# This script sets up the environment for running benchmarks and downloads necessary files
#

echo "Starting benchmark environment setup..."

# Define variables and paths
HOME_DIR="/home/ubuntu"
CLDPERF_DIR="$HOME_DIR/cldperf-nflx-lab-benchmarks-main"
AUTOBENCH_DIR="$CLDPERF_DIR/autobench"
S3_PATH="s3://netflix-files-us-west2/cldperf-nflx-lab-benchmarks-main/"
GIT_REPO="https://github.com/nfairoza/benchmarks-data.git"
GIT_SUBDIR="cldperf-nflx-lab-benchmarks-main/autobench-aws"
TEMP_DIR="$HOME_DIR/temp_git_clone"
LOCAL_RESULTS_DIR="$HOME_DIR/benchmark_results"

sudo mkdir -p "$LOCAL_RESULTS_DIR"
export LOCAL_RESULTS_DIR=$(echo "$LOCAL_RESULTS_DIR")

echo "Updating package lists and installing required packages..."
sudo apt update

# Add repositories
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt update

# Install necessary drivers
sudo ubuntu-drivers autoinstall

# Install required packages
sudo apt install -y \
    build-essential \
    sudo \
    openjdk-17-jre-headless \
    openjdk-17-jdk-headless \
    linux-headers-$(uname -r) \
    p7zip-full \
    sysbench \
    lmbench \
    docker.io \
    docker-compose \
    cgroup-tools \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    g++ \
    git \
    tree \
    zip \
    unzip \
    wget \
    curl \
    htop \
    iotop

# Set up Python alternatives to make python command available
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Install common Python packages
echo "Installing common Python packages..."
sudo pip3 install --upgrade pip
sudo pip3 install numpy pandas matplotlib seaborn scikit-learn scipy requests jupyter

install_aws_cli() {
    echo "Installing AWS CLI..."

    . /etc/os-release
    arch=$(uname -m)

    case "$ID" in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y unzip
            ;;
        centos|rhel|almalinux|rocky|amazon)
            sudo yum update -y
            sudo yum install -y unzip
            ;;
        sles|opensuse-leap)
            sudo zypper refresh && sudo zypper update -y
            sudo zypper install -y unzip
            ;;
        *)
            echo "Unsupported Linux distribution: $ID."
            exit 1
            ;;
    esac

    if [[ "$arch" == "x86_64" ]]; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    elif [[ "$arch" == "aarch64" ]]; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
    else
        echo "Unsupported architecture: $arch"
        exit 1
    fi

    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
}

# Check if AWS CLI is installed, install if not
if ! aws --version &>/dev/null; then
    echo "AWS CLI not found. Installing..."
    install_aws_cli
fi

echo "Cleaning up package cache..."
sudo apt clean

echo "Checking for benchmark files..."
if [ ! -d "$CLDPERF_DIR" ]; then
    echo "Directory $CLDPERF_DIR does not exist. Attempting to download from S3..."
    aws s3 cp "$S3_PATH" "$CLDPERF_DIR" --recursive
    if [ $? -ne 0 ]; then
        echo "S3 download failed or aws CLI not configured properly."
    else
        echo "S3 download complete!"
    fi
else
    echo "Directory $CLDPERF_DIR already exists. Using existing files."
fi

echo "Setting up Java environment variables..."
sudo bash -c "cat << EOF >> /home/ubuntu/.bashrc
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH="\$JAVA_HOME/bin:\$PATH"
# Add Python to PATH if needed
export PATH="\$PATH:/usr/bin/python3"
EOF"

echo "Setting up the working directory..."
cd $HOME_DIR

echo "Downloading files from GitHub repository..."
if [ -d "$TEMP_DIR" ]; then
    sudo rm -rf "$TEMP_DIR"
fi

git clone --depth 1 "$GIT_REPO" "$TEMP_DIR"

if [ $? -ne 0 ]; then
    echo "Failed to clone the GitHub repository."
    exit 1
else
    if [ -d "$AUTOBENCH_DIR" ]; then
        echo "Found autobench directory at $AUTOBENCH_DIR"
        echo "Copying files from GitHub to $AUTOBENCH_DIR..."
        sudo cp -f "$TEMP_DIR/$GIT_SUBDIR"/* "$AUTOBENCH_DIR/" 2>/dev/null || echo "Warning: No files found or couldn't be copied"
        echo "Making all files executable..."
        sudo chmod -R +x "$AUTOBENCH_DIR"
    else
        echo "Warning: autobench directory not found at $AUTOBENCH_DIR"
        echo "Creating autobench directory and copying files from GitHub..."
        sudo mkdir -p "$AUTOBENCH_DIR"
        sudo cp -f "$TEMP_DIR/$GIT_SUBDIR"/* "$AUTOBENCH_DIR/" 2>/dev/null
        sudo chmod -R +x "$AUTOBENCH_DIR"
    fi
    sudo rm -rf "$TEMP_DIR"
    echo "GitHub repository processing complete."
fi

sudo chmod +x "$AUTOBENCH_DIR/run-benchmarks.sh" 2>/dev/null || true
sudo chmod +x "$AUTOBENCH_DIR/benchmarks_environment.sh" 2>/dev/null || true
sudo chmod +x "$AUTOBENCH_DIR/launch_containers-concurrent.sh" 2>/dev/null || true
sudo chmod +x "$AUTOBENCH_DIR/upload-results.sh" 2>/dev/null || true
sudo chmod -R +x "$AUTOBENCH_DIR/benchmarks" 2>/dev/null || true
sudo chmod -R +x "$AUTOBENCH_DIR/binaries" 2>/dev/null || true

# Verify Python installation
python_version=$(python --version 2>&1)
echo "Python version: $python_version"
pip_version=$(pip --version 2>&1)
echo "Pip version: $pip_version"

cd $AUTOBENCH_DIR
echo "Setup complete! You can now run benchmarks."

echo "................................Initial binaries and scripts setup complete.............................."
echo "cd $AUTOBENCH_DIR"
echo "To run benchmarks, execute: ./start-benchmarks.sh"
echo "................................Now you can run benchmarks.............................."
