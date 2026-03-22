# Unitree L1 4D LiDAR Setup Guide
**Jetson AGX Xavier - ROS2 Foxy**

Complete setup and configuration guide for Unitree L1 4D LiDAR on Jetson AGX Xavier.

---

## Quick Start

```bash
# Simply run:
cd /home/reza/LidarUnitree
bash launch_unitree_l1.sh
```

**Features:**
- ✅ Config 50 (recommended) - optimal density/performance balance
- ✅ 50 cloud scans per second
- ✅ Automatic RViz2 visualization with proper configuration
- ✅ All dependencies sourced from `/mnt/nvme` (no main disk pollution)
- ✅ Rainbow point cloud coloring by Z-axis height
- ✅ ~4Hz publish rate, ~1.5GB RAM usage

---

## Table of Contents
1. [Hardware Setup](#hardware-setup)
2. [Quick Configuration](#quick-configuration)
3. [Available Configs](#available-configs)
4. [Usage](#usage)
5. [Troubleshooting](#troubleshooting)

---

## Hardware Setup

### Components
- **LiDAR**: Unitree L1 4D LiDAR
- **FOV**: 360° horizontal × 90° vertical
- **Connection**: USB (appears as `/dev/ttyUSB0`)
- **Baud Rate**: 2000000
- **Platform**: Jetson AGX Xavier (L4T R35.6.3, CUDA 11.4)

### Verify Connection
```bash
# Check device
ls -la /dev/ttyUSB0

# Check kernel messages
dmesg | grep -i "cp210x\|usb"
```

---

## Quick Configuration

**Current Setup:** Config 50 (launch_50.py)
- **Cloud Scan Num**: 50
- **Publish Rate**: ~4Hz
- **Memory Usage**: ~1.5GB
- **Recommendation**: Best for most applications

### To Switch Configuration

Edit `/home/reza/LidarUnitree/launch_unitree_l1.sh` line 22:

```bash
# Change this:
ros2 launch unitree_lidar_ros2 launch_50.py &

# To one of these:
ros2 launch unitree_lidar_ros2 launch_30.py &  # Lower density, less RAM
ros2 launch unitree_lidar_ros2 launch_40.py &  # Medium density
ros2 launch unitree_lidar_ros2 launch_50.py &  # Recommended (current)
ros2 launch unitree_lidar_ros2 launch_72.py &  # Maximum density
```

---

## Available Configs

All configurations are located in: `/mnt/nvme/unilidar_sdk/unitree_lidar_ros2/config/`

| Config | Cloud Scans | Use Case |
|--------|------------|----------|
| launch_30.py | 30 | Low density, minimal RAM |
| launch_40.py | 40 | Balanced option |
| **launch_50.py** | 50 | **Recommended** |
| launch_72.py | 72 | Maximum density/detail |

---

## Usage

### Start LiDAR Driver

```bash
cd /home/reza/LidarUnitree
bash launch_unitree_l1.sh
```

### Topics

- **Point Cloud**: `/unilidar/cloud` (sensor_msgs/PointCloud2)
- **IMU**: `/unilidar/imu` (sensor_msgs/Imu)

### Visualization

RViz2 automatically starts with proper configuration:
- Rainbow coloring by Z-axis height
- 5-second point decay
- 4-pixel point size
- Rotate with mouse

### Stop

Press `Ctrl+C` in the terminal running the script.

---

## Important: Storage Location

⚠️ **ALL installations use `/mnt/nvme` (secondary NVMe drive)**

This prevents filling the main disk. The setup respects:
- SDK location: `/mnt/nvme/unilidar_sdk/`
- Build directory: `/mnt/nvme/unilidar_sdk/unitree_lidar_ros2/install/`
- Configurations: `/mnt/nvme/unilidar_sdk/unitree_lidar_ros2/config/`

No files are copied to `/home` or `/root`.

---

## Troubleshooting

### "Permission denied" error
```bash
chmod +x /home/reza/LidarUnitree/launch_unitree_l1.sh
```

### No point cloud visible in RViz2
1. Check LiDAR connection: `ls -la /dev/ttyUSB0`
2. Verify ROS2 sourcing works: `source /opt/ros/foxy/setup.bash`
3. Check /mnt/nvme is accessible: `ls /mnt/nvme/unilidar_sdk/`

### High memory usage
Use a lower configuration:
```bash
# Edit launch_unitree_l1.sh and change to launch_30.py
```

### LiDAR driver won't start
```bash
# Check ROS2 Foxy is installed
which ros2

# Verify installation sourced correctly
source /opt/ros/foxy/setup.bash
source /mnt/nvme/unilidar_sdk/unitree_lidar_ros2/install/setup.bash
```

---

## Performance Notes

- **Publish Rate**: ~4Hz (determined by hardware)
- **Memory**: ~1.5GB (ROS2 driver + RViz2)
- **CPU Usage**: Moderate (visualization handled by GPU when available)
- **Point Count per Frame**: ~50,000 (with config 50)

---

## Documentation

For advanced configuration and details, see:
- Config details: `/mnt/nvme/unilidar_sdk/unitree_lidar_ros2/config/README.md`
- Original repository: `/mnt/nvme/unilidar_sdk/README.md`

