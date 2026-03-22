#!/bin/bash
# Unitree L1 LiDAR Launcher - Config 50 with Auto-Detection
# Automatically detects correct USB device based on Silicon Labs CP210x ID

cd /mnt/nvme/unilidar_sdk/unitree_lidar_ros2

# Source ROS2
source /opt/ros/foxy/setup.bash
source ./install/setup.bash

echo "🚀 Starting Unitree L1 4D LiDAR (Config 50 - Optimized)..."
echo "   Auto-detecting Unitree LiDAR device..."

# Auto-detect correct USB device based on Silicon Labs CP210x (ID 10c4:ea60)
LIDAR_PORT=""
for device in /sys/bus/usb-serial/devices/*/; do
  if [ -f "$device/../../idVendor" ]; then
    vendor=$(cat "$device/../../idVendor")
    product=$(cat "$device/../../idProduct")
    if [ "$vendor" = "10c4" ] && [ "$product" = "ea60" ]; then
      LIDAR_PORT="/dev/$(basename "$device")"
      break
    fi
  fi
done

if [ -z "$LIDAR_PORT" ]; then
  echo "❌ ERROR: Could not find Unitree LiDAR (Silicon Labs CP210x device)"
  echo "   Expected: USB device with ID 10c4:ea60"
  echo "   Available devices:"
  lsusb
  exit 1
fi

echo "✅ Found Unitree LiDAR at: $LIDAR_PORT"
echo "   Configuring serial port..."

# Set USB serial baud rate to 2000000
sudo stty -F "$LIDAR_PORT" 2000000 raw -echo

echo "✅ Serial port configured (2000000 baud)"
echo "   PointCloud2 topic: /unilidar/cloud"
echo "   IMU topic: /unilidar/imu"
echo "   Cloud Scan Num: 50 (optimal density/performance)"
echo ""

# Apply config 50: Copy launch_50.py → launch.py
cp config/launch_50.py install/unitree_lidar_ros2/share/unitree_lidar_ros2/launch.py

# Update launch file to use detected port
sed -i "s|'/dev/ttyUSB[0-9]*'|'$LIDAR_PORT'|g" install/unitree_lidar_ros2/share/unitree_lidar_ros2/launch.py

# Launch driver with config 50 and RViz2
ros2 launch unitree_lidar_ros2 launch.py &
LIDAR_PID=$!

sleep 3

# Launch RViz2 with Unitree L1 config
rviz2 -d /mnt/nvme/unilidar_sdk/unitree_lidar_ros2/config/unitree_l1.rviz &
RVIZ_PID=$!

echo "✓ Processes started"
echo "  LiDAR driver PID: $LIDAR_PID"
echo "  RViz2 PID: $RVIZ_PID"
echo ""
echo "✓ RViz2 configured with:"
echo "  - Fixed Frame: unilidar_lidar"
echo "  - Decay Time: 5 seconds"
echo "  - Point Size: 4 pixels"
echo "  - Color: Rainbow (Z-axis)"
echo ""
echo "Press Ctrl+C to stop"

trap "kill $LIDAR_PID $RVIZ_PID 2>/dev/null; echo 'Stopped'; exit 0" INT

wait
