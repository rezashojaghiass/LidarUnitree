# Configuration Files

Optimized configurations for Unitree L1 4D LiDAR on Jetson AGX Xavier.

## Launch Files

Different density settings for the LiDAR driver:

- **launch_30.py**: cloud_scan_num=30 (moderate density)
- **launch_40.py**: cloud_scan_num=40 (good density)
- **launch_50.py**: cloud_scan_num=50 (recommended - dense)
- **launch_72.py**: cloud_scan_num=72 (too dense, causes visualization failure)
- **launch_optimized.py**: Current best configuration (cloud_scan_num=50)

## RViz2 Configuration

- **unitree_l1.rviz**: Optimized RViz2 visualization settings
  - Decay Time: 5 seconds
  - Point Size: 4 pixels
  - Color: AxisColor (Z-axis rainbow)
  - Queue Size: 100

## Usage

To apply a configuration:

```bash
# Copy desired launch file to driver location
cp launch_50.py /mnt/nvme/unilidar_sdk/unitree_lidar_ros2/install/unitree_lidar_ros2/share/unitree_lidar_ros2/launch.py

# Restart driver
pkill -9 -f unitree_lidar_ros2
cd /mnt/nvme/unilidar_sdk/unitree_lidar_ros2
source install/setup.bash
ros2 launch unitree_lidar_ros2 launch.py

# Launch RViz2 with optimized config
rviz2 -d unitree_l1.rviz
```

## Performance

- **Publish Rate**: ~4 Hz
- **Memory Usage**: ~1.5GB (driver + RViz2)
- **Recommended**: cloud_scan_num=50 for best density/performance balance
