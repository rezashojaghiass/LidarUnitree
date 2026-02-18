# Unitree L1 4D LiDAR Setup Guide
**Jetson AGX Xavier - ROS2 Foxy**

Complete setup and configuration guide for Unitree L1 4D LiDAR on Jetson AGX Xavier.

---

## Table of Contents
1. [Hardware Setup](#hardware-setup)
2. [ROS2 Installation](#ros2-installation)
3. [Unitree SDK Installation](#unitree-sdk-installation)
4. [Building the Driver](#building-the-driver)
5. [Configuration & Optimization](#configuration--optimization)
6. [Usage](#usage)
7. [Troubleshooting](#troubleshooting)

---

## Hardware Setup

### Components
- **LiDAR**: Unitree L1 4D LiDAR
- **FOV**: 360° horizontal × 90° vertical
- **Connection**: USB (appears as `/dev/ttyUSB0`)
- **Bridge Chip**: Silicon Labs CP210x USB-to-UART
- **Baud Rate**: 2000000
- **Platform**: Jetson AGX Xavier (L4T R35.6.3, CUDA 11.4)

### Verify Connection
```bash
# Check device
ls -la /dev/ttyUSB0

# Check kernel messages
dmesg | grep -i "cp210x\|usb"

# Should see:
# cp210x converter detected
# cp210x converter now attached to ttyUSB0

# Check device info
udevadm info /dev/ttyUSB0 | grep -E "ID_VENDOR|ID_MODEL"
```

---

## ROS2 Installation

### Install ROS2 Foxy (if not already installed)
```bash
# Add ROS2 repository
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository universe

# Add ROS2 GPG key
sudo apt install curl gnupg lsb-release
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Install ROS2 Foxy
sudo apt update
sudo apt install ros-foxy-desktop

# Install additional packages
sudo apt install ros-foxy-pcl-conversions ros-foxy-pcl-ros
sudo apt install python3-colcon-common-extensions
```

### Setup Environment
```bash
# Add to ~/.bashrc
echo "source /opt/ros/foxy/setup.bash" >> ~/.bashrc
source ~/.bashrc

# Verify installation
ros2 --version
# Should output: ros2 run 0.9.x
```

---

## Unitree SDK Installation

### Clone Official Repository
```bash
# ⚠️ IMPORTANT: Clone to /mnt/nvme to avoid filling root partition
cd /mnt/nvme
git clone --recursive https://github.com/unitreerobotics/unilidar_sdk.git
cd unilidar_sdk

# Verify submodules
git submodule update --init --recursive
```

### Install Dependencies
```bash
# Install SDK dependencies
sudo apt install -y \
    build-essential \
    cmake \
    git \
    libpcl-dev \
    libeigen3-dev \
    libboost-all-dev

# Verify ROS2 dependencies
sudo apt install -y \
    ros-foxy-pcl-conversions \
    ros-foxy-pcl-ros \
    ros-foxy-sensor-msgs \
    ros-foxy-geometry-msgs
```

---

## Building the Driver

### Build with Colcon
```bash
cd /mnt/nvme/unilidar_sdk/unitree_lidar_ros2

# Source ROS2 environment
source /opt/ros/foxy/setup.bash

# Build (takes ~1-2 minutes)
colcon build

# Source workspace
source install/setup.bash

# Verify build
ls install/unitree_lidar_ros2/lib/unitree_lidar_ros2/
# Should see: unitree_lidar_ros2_node
```

### Add to Startup (optional)
```bash
# Add to ~/.bashrc for automatic sourcing
echo "source /mnt/nvme/unilidar_sdk/unitree_lidar_ros2/install/setup.bash" >> ~/.bashrc
```

---

## Configuration & Optimization

### Default Configuration
The default `launch.py` is located at:
```
install/unitree_lidar_ros2/share/unitree_lidar_ros2/launch.py
```

### Key Parameters
```python
port='/dev/ttyUSB0'           # LiDAR device
cloud_scan_num=18             # Default (sparse)
range_max=50.0                # Max detection range (meters)
range_min=0.0                 # Min detection range (meters)
cloud_frame='unilidar_lidar'  # TF frame name
cloud_topic='unilidar/cloud'  # PointCloud2 topic
```

### Optimized Configurations
Pre-configured launch files with different density settings:

```bash
cd /mnt/nvme/unilidar_sdk/unitree_lidar_ros2/config/

# Available configurations:
# - launch_30.py  : cloud_scan_num=30 (moderate)
# - launch_40.py  : cloud_scan_num=40 (good)
# - launch_50.py  : cloud_scan_num=50 (recommended - dense)
# - launch_72.py  : cloud_scan_num=72 (too dense, causes issues)

# Apply optimized configuration
cp config/launch_50.py install/unitree_lidar_ros2/share/unitree_lidar_ros2/launch.py
```

### RViz2 Configuration
Pre-configured RViz2 file for optimal visualization:

```bash
# Copy to home directory
cp /mnt/nvme/unilidar_sdk/unitree_lidar_ros2/config/unitree_l1.rviz ~/

# Settings:
# - Fixed Frame: unilidar_lidar
# - Decay Time: 5 seconds (accumulates ~20 clouds)
# - Point Style: Points (not Spheres)
# - Point Size: 4 pixels (0.01m)
# - Color: AxisColor (Z-axis rainbow)
# - Queue Size: 100
# - Topic Depth: 10
```

---

## Usage

### Basic Launch
```bash
# Terminal 1: Start LiDAR driver
cd /mnt/nvme/unilidar_sdk/unitree_lidar_ros2
source install/setup.bash
ros2 launch unitree_lidar_ros2 launch.py
```

### With Visualization
```bash
# Terminal 1: Start driver
cd /mnt/nvme/unilidar_sdk/unitree_lidar_ros2
source install/setup.bash
ros2 launch unitree_lidar_ros2 launch.py

# Terminal 2: Launch RViz2 with optimized config
rviz2 -d ~/unitree_l1.rviz
```

### Verify Topics
```bash
# List all topics
ros2 topic list
# Should see: /unilidar/cloud, /unilidar/imu

# Check publish rate
ros2 topic hz /unilidar/cloud
# Expected: ~4 Hz

# Echo point cloud data
ros2 topic echo /unilidar/cloud --once
```

### Stop Services
```bash
# Stop LiDAR driver
pkill -9 -f unitree_lidar_ros2

# Stop RViz2
pkill -9 rviz2

# Verify stopped
ps aux | grep -E "unitree_lidar|rviz2"
```

---

## Troubleshooting

### Device Not Found
```bash
# Check USB connection
ls -la /dev/ttyUSB*

# If not found, check dmesg
dmesg | tail -20

# Check USB permissions
sudo chmod 666 /dev/ttyUSB0

# Or add permanent udev rule
echo 'KERNEL=="ttyUSB[0-9]*", MODE="0666"' | sudo tee /etc/udev/rules.d/99-usb-serial.rules
sudo udevadm control --reload-rules
```

### Build Errors
```bash
# Clean and rebuild
cd /mnt/nvme/unilidar_sdk/unitree_lidar_ros2
rm -rf build/ install/ log/
colcon build

# Check dependencies
sudo apt install --reinstall ros-foxy-pcl-conversions ros-foxy-pcl-ros
```

### No Point Cloud in RViz2
```bash
# Check if driver is publishing
ros2 topic hz /unilidar/cloud

# Check topic type
ros2 topic info /unilidar/cloud
# Should be: sensor_msgs/msg/PointCloud2

# Verify Fixed Frame in RViz2 matches "unilidar_lidar"

# Check for errors
ros2 node list
ros2 node info /unitree_lidar_ros2_node
```

### Sparse Point Cloud
```bash
# Increase cloud_scan_num in launch.py
# Recommended: 50 (balance between density and performance)

# Apply configuration
cp config/launch_50.py install/unitree_lidar_ros2/share/unitree_lidar_ros2/launch.py

# Restart driver
pkill -9 -f unitree_lidar_ros2
ros2 launch unitree_lidar_ros2 launch.py
```

### High Memory Usage
```bash
# Check memory usage
free -h

# Check GPU usage (Jetson)
tegrastats

# Reduce density
cp config/launch_30.py install/unitree_lidar_ros2/share/unitree_lidar_ros2/launch.py

# Close RViz2 if only need raw data
pkill -9 rviz2

# Typical memory usage:
# - Driver only: ~100-200MB
# - Driver + RViz2: ~1.5GB
```

### Performance Issues
```bash
# Check CPU usage
top -p $(pgrep -f unitree_lidar)

# Set power mode to MAXN (Jetson)
sudo nvpmodel -m 0

# Enable max clocks
sudo jetson_clocks

# Verify
sudo nvpmodel -q
```

---

## Performance Metrics

### Measured Performance
- **Publish Rate**: ~4 Hz
- **Point Cloud Type**: sensor_msgs/msg/PointCloud2
- **Points per Cloud**: Varies with cloud_scan_num (50 = ~50,000-100,000 points)
- **RAM Usage**: 
  - Driver only: 100-200MB
  - Driver + RViz2: 1.5GB
- **CPU Usage**: 5-10% (4 cores @ 2.2GHz)
- **Latency**: <50ms

### Recommended Settings
```python
# Best balance: density vs performance
cloud_scan_num: 50
decay_time: 5 seconds  # In RViz2
point_size: 4 pixels   # In RViz2
color: AxisColor (Z)   # Rainbow by height
```

---

## Storage Information

### Installation Paths
- **SDK Source**: `/mnt/nvme/unilidar_sdk/`
- **ROS2 Package**: `/mnt/nvme/unilidar_sdk/unitree_lidar_ros2/`
- **Build Output**: `/mnt/nvme/unilidar_sdk/unitree_lidar_ros2/install/`
- **Configurations**: `/mnt/nvme/unilidar_sdk/unitree_lidar_ros2/config/`
- **RViz Config**: `~/unitree_l1.rviz`

### Disk Usage
```bash
# Check SDK size
du -sh /mnt/nvme/unilidar_sdk/
# ~200MB

# Check build size
du -sh /mnt/nvme/unilidar_sdk/unitree_lidar_ros2/install/
# ~50MB
```

---

## Resource Management

### Running with Other Services
When running LiDAR alongside RIVA or other GPU services:

```bash
# 1. Stop LiDAR to free memory
pkill -9 -f unitree_lidar_ros2
pkill -9 rviz2

# 2. Start RIVA first (needs more GPU memory)
cd /mnt/nvme/adrian/riva/riva_quickstart_arm64_v2.19.0
bash riva_start.sh

# 3. Then start LiDAR (if enough memory)
cd /mnt/nvme/unilidar_sdk/unitree_lidar_ros2
source install/setup.bash
ros2 launch unitree_lidar_ros2 launch.py
```

### Memory Budget (Jetson AGX Xavier - 14GB Unified Memory)
- **Base System**: ~2GB
- **RIVA Services**: ~3-4GB (ASR + TTS + models)
- **LiDAR + RViz2**: ~1.5GB
- **ChatBotRobot**: ~500MB (RAG + Python)
- **Available**: ~7GB free for other processes

---

## Git Repository

### Local Commit
The configurations are committed locally to the Unitree SDK:
```bash
cd /mnt/nvme/unilidar_sdk/unitree_lidar_ros2
git log --oneline | head -1
# Should show: "Add Unitree L1 4D LiDAR optimized configurations"
```

**Note**: This is a local commit to the cloned Unitree repository. The official Unitree repo doesn't include these custom configurations.

### Backup Configurations
```bash
# Backup your configs
tar -czf ~/unitree_l1_configs_$(date +%Y%m%d).tar.gz \
    /mnt/nvme/unilidar_sdk/unitree_lidar_ros2/config/ \
    ~/unitree_l1.rviz
```

---

## References

- **Official Unitree SDK**: https://github.com/unitreerobotics/unilidar_sdk
- **ROS2 Foxy Docs**: https://docs.ros.org/en/foxy/
- **Jetson AGX Xavier**: https://developer.nvidia.com/embedded/jetson-agx-xavier
- **PCL Library**: https://pointclouds.org/

---

## Changelog

**2026-02-17**: Initial setup and optimization
- Installed ROS2 Foxy on Jetson AGX Xavier
- Cloned and built Unitree L1 SDK
- Created optimized configurations (cloud_scan_num: 50)
- Configured RViz2 with 5s decay and rainbow colors
- Documented complete setup process
- Tested performance: 4Hz @ ~1.5GB RAM

---

## Author
Reza Shojaghias  
Platform: Jetson AGX Xavier  
Date: February 17, 2026
