#!/bin/bash
set -eu

usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help                 Display this help message"
    echo "  --distro DISTRO            Specify the ROS distribution (e.g., humble, jazzy, lyrical, rolling)"
    echo "  --update                   Force a rebuild of the Docker image"
    echo "  --create                   Create the Docker container with default options"
    echo "  --name container_name      Set a custom name for the container. Default nale is ros-$distro-dev"
    echo "  --cmd container_cmd        Specify the command to execute on startup (default: terminator -u)"
    echo ""
    exit "${1:-1}";
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage 0;;
        --distro) o_distro=${2?argument missing}; shift 2;;
        --update) o_update=true; shift ;;
        --create) o_create=true; shift ;;
        --name) o_name=${2?argument missing}; shift 2;;
        --cmd) o_cmd=${2?argument missing}; shift 2;;
        -*)
            echo "unknown option '$1'"  >&2; usage;;
        *)
            if [ -n "${robot:-}" ]; then
                echo "extra option '$1'"  >&2; usage
            fi
            robot=$1; shift;;
    esac
done

distro=${o_distro:-$distro}

case "$distro" in
    humble) codename=humble-desktop;;
    jazzy) codename=jazzy-desktop;;
    lyrical) codename=lyrical-desktop;;
    rolling) codename=rolling-desktop;;
    *)
    if [ -z "$codename" ]; then
        echo "distro '$distro' unknown" >&2
        exit 1
    fi
esac

image="dev-ros2:$distro"
user=${SUDO_USER:-$USER} # user that launches the script
home=$(eval echo "~$user") # home of the user that launches the script
LOCAL_USER_ID=$(id -u "$user")
LOCAL_GROUP_ID=$(id -g "$user")
LOCAL_GROUP_NAME=$(id -gn "$user")

# Define dedicated vars for ViSP
docker_user="user"
docker_home="/home/${docker_user}"
visp_ws="${docker_home}/visp-ws"

if [ "${o_update:-}" == true ] || ! docker image inspect "$image" >/dev/null 2>&1; then
    docker buildx build --pull -t "$image"  --build-arg "NOW=$(date +%s)" --build-arg "USER_ID=$LOCAL_USER_ID" --build-arg "USER_NAME=$docker_user" --build-arg "CODENAME=$codename" --build-arg "HOME=/home/${docker_user}" .
else
    echo "Image $image already exists, use --update to force a rebuild"
fi

if [ "${o_create:-}" == true ]; then
    container="ros-$distro-dev"
    if docker container inspect "$container" >/dev/null 2>&1; then
        echo "container '$container' already exists" >&2
        echo "You can remove it with 'docker rm $container'" >&2
        exit 1
    fi
    mkdir -p "${home}/exchange"
    opts=(
    --volume "${home}/exchange:${docker_home}/exchange:rw" --workdir "${docker_home}"
    --env HOME=${docker_home}
    --env DISPLAY --env LOCAL_XDG_RUNTIME_DIR=/tmp/local-xdg-runtime --volume "$XAUTHORITY:${docker_home}/.Xauthority:rw" --env XAUTHORITY=${docker_home}/.Xauthority
    --volume "$XDG_RUNTIME_DIR:/tmp/local-xdg-runtime:ro" --volume /tmp/.X11-unix:/tmp/.X11-unix:rw 
    --env "LOCAL_USER_ID=${LOCAL_USER_ID}" --env "LOCAL_GROUP_ID=${LOCAL_GROUP_ID}" --env "LOCAL_GROUP_NAME=${LOCAL_GROUP_NAME}"
    --env QT_X11_NO_MITSHM=1
    --env ROS_LOCALHOST_ONLY=1
    --privileged
    --volume /dev:/dev:rw
    --net host
    )
    if [ -n "$(command -v nvidia-container-runtime)" ]; then
        opts+=(--gpus all)
        echo "Using GPU acceleration"
    else
        echo "No GPU acceleration available"
    fi

    read -r -a cmd <<< "${o_cmd:-terminator -u}"
    docker create "${opts[@]}" -it --name "$container" "$image" "${cmd[@]}" > /dev/null
    echo "Please run 'docker start -ai $container' to start the container"
fi
