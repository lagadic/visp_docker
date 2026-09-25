ROS 2 Docker Development Environment
====================================

This guide explains how to build, manage, and use a Docker environment tailored for developing and testing ROS 2 packages (such as [visp_tk](https://github.com/lagadic/visp_tk).

## 1. Prerequisites

To run the `build-ros-docker.sh` script on an Ubuntu host, make sure you have the `docker-buildx` package 
installed on your Ubuntu distribution:

```bash
$ sudo apt install docker-buildx
```

## 2. Create Docker Image

The `build-ros-docker.sh` script allows you to create a ready-to-use Docker container for ROS 2 distributions such as `jazzy`, `lyrical` or `rolling`.  

For example, to create a container with ROS 2 `jazzy`, run:

```bash
$ bash ./build-ros-docker.sh --distro jazzy --create
```

**Note: Permission denied error**
- If you encounter this error:
  ```bash
  $ bash ./build-ros-docker.sh --distro jazzy --create
  ERROR: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Head "http://%2Fvar%2Frun%2Fdocker.sock/_ping": dial unix /var/run/docker.sock: connect: permission denied
  ```
  Add your user to the docker group and reboot:
  ```bash
  $ sudo usermod -aG docker $USER
  $ sudo reboot
  ```

The built image is based on the official `osrf/ros:<distro>-desktop` image available on [Docker Hub](https://hub.docker.com/r/osrf/ros/).

## 3. Manage Docker Images
### 3.1. Update an Image

If the image is already built and you have modified the `Dockerfile`, update it using:

```bash
$ docker rm ros-jazzy-dev
$ bash ./build-ros-docker.sh --distro jazzy --create --update
```

### 3.2. Remove an Image (Clean Build)

Removing an existing image is useful if you want to create a fresh container from scratch:

- Check active containers:
  ```bash
  $ docker ps --all
  CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS    PORTS     NAMES
  7344ceba4d33   dev-ros2:jazzy   "/ros_entrypoint.sh …"   5 minutes ago   Created             ros-jazzy-dev
  ```
- Stop and remove the container using its `CONTAINER ID`:
  ```bash
  $ docker stop 7344ceba4d33
  $ docker rm 7344ceba4d33
  ```
- Identify docker image name
  ```bash
  $ docker image ls
  IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
  dev-ros2:jazzy   0acf2946e34f        7.2GB         1.83GB    U 
  ```
- Remove docker image
  ```bash
  $ docker image rm dev-ros2:jazzy
  ```

# Start the Docker container

To start your ROS 2 `jazzy` container, run:

```bash
$ docker start -ai ros-jazzy-dev
```

This opens a `terminator` terminal running inside the container. If you split this terminal, you will remain in the docker container.

**Note: GUI / X11 Authorization Error:**
- If you get the following error:
  ```bash
  $ docker start -ai ros-jazzy-dev
  Authorization required, but no authorization protocol specified
  You need to run terminator in an X environment. Make sure $DISPLAY is properly set
  ```
  authorize local Docker X11 connections on your host before starting the container with:
  ```bash
  $ xhost +local:docker
  non-network local connections being added to access control list
  ```

# Sharing files via the exchange folder

To easily share files between your host machine and the Docker container, the script automatically sets up a shared bind-mount directory:  

Directory Paths
- Host Machine: `~/exchange/` (located in your local user home directory)
- Inside the Container: `~/exchange/` (mapped to `${docker_home}/exchange` inside the container)

Any changes made to files in this folder on your host machine instantly reflect inside the container, and vice versa, while maintaining proper user permissions mapping.

# Usage example
## Testing `visp_tk`

A recommended workflow is to store the `visp_tk` source code on your host machine (for easy editing) and build/run the ROS 2 packages inside the Docker container.

- On your host machine clone `visp_tk` into the `~/exchange/` folder

  ```bash
  $ mkdir -p ~/exchange/ros2-src && cd ~/exchange/ros2-src
  $ git clone https://github.com/lagadic/visp_tk.git -b <branch to test>
  ```

- Inside your ROS 2 container, create a workspace and link the source code:

  ```bash
  docker $ mkdir -p ~/ros2_ws/src && cd ~/ros2_ws/src
  docker $ ln -s ~/exchange/ros2-src/visp_tk
  docker $ cd ~/ros2_ws
  ```

- Install required ROS dependencies via `rosdep`:

  ```bash
  docker $ rosdep update && rosdep install --from-paths src --ignore-src
  ```

- Build the `visp_tk` packages using `colcon`:

  ```bash
  docker $ colcon build --symlink-install --packages-up-to visp_tk
  ```

- Alternatively, build the `visp_tk_tutorials` package to see examples of use:

  ```bash
  docker $ colcon build --symlink-install --packages-up-to visp_tk_tutorials
  ```

- Once the workspace is successfully built, source your local setup:

  ```bash
  docker $ source install/setup.bash
  ```

- Running tutorials

  - Apriltag detection using a rosbag

    ```bash
    ros2 launch visp_tk_tutorials apriltag_tracker_bag_launch.py
    ```

  - Apriltag detection using a camera compatible with video4Linux (typically a webcam)

    ```bash
    ros2 launch visp_tk_tutorials apriltag_tracker_live_v4l_launch.py
    ```

  - Model-Based Tracker using a rosbag

    ```bash
    ros2 launch visp_tk_tutorials mbt_json_launch.py
    ```

- Running individual nodes

  - AprilTag Detector Node:

    ```bash
    ros2 run visp_apriltag visp_apriltag_node --ros-args -p size:=0.05
    ```

  - Model-Based Tracker (MBT) Node:
    ```bash
    ros2 run visp_mbt visp_mbt_node
    ```

  Detailed launch files, parameters description, and configuration examples for each package are available in their respective subdirectories following <https://github.com/lagadic/visp_tk.git>.