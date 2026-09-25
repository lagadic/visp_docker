ARG CODENAME=jazzy-desktop
FROM osrf/ros:$CODENAME
ARG CODENAME
ENV CODENAME=$CODENAME
ARG DEBIAN_FRONTEND=noninteractive
ARG USER_ID
ENV USER_ID=$USER_ID
ARG USER_NAME
ENV USER_NAME=$USER_NAME
ARG HOME
ENV HOME=$HOME
ENV TZ=Europe/Paris

RUN if id -u $USER_ID ; then userdel `id -un $USER_ID` ; fi
RUN useradd -U --uid $USER_ID -d /home/${USER_NAME} -ms /bin/bash ${USER_NAME} \
    && echo "${USER_NAME}:${USER_NAME}" | chpasswd \
    && adduser ${USER_NAME} sudo \
    && echo "$USER_NAME ALL=NOPASSWD: ALL" >> /etc/sudoers.d/${USER_NAME} \
    && adduser ${USER_NAME} video

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    cmake-curses-gui \
    curl \
    gedit \
    gdb \
    git \
    iputils-ping \
    locales \
    locate \
    net-tools \
    sudo \
    terminator \
    vim \
    xauth

RUN locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    export LANG=en_US.UTF-8

# Additional packages for ViSP
RUN apt-get update && apt-get install -y \
    nlohmann-json3-dev

# Additional packages needed for ros2 lyrical
RUN apt-get update && apt-get install -y \
    bubblewrap \
    librsvg2-common \
    libcanberra-gtk3-module \
    adwaita-icon-theme

RUN mkdir -p /etc/xdg/terminator && \
    touch /etc/xdg/terminator/config && \
    chown -R ${USER_NAME}:${USER_NAME} /etc/xdg/terminator

# RUN apt-get update && apt-get install -y \
#      bubblewrap

# RUN mkdir -p /etc/xdg/terminator && \
#    touch /etc/xdg/terminator/config
# Here ends lyrical specific requirements

# Commands below are now run as normal user
USER ${USER_NAME}

# Commands below are now run as normal user
WORKDIR ${HOME}

# Create visp workspace
ENV VISP_WS=${HOME}/visp-ws

# Install visp-images
RUN mkdir -p $VISP_WS \
    && cd $VISP_WS \
    && echo "export VISP_WS=$VISP_WS" >> ${HOME}/.bashrc 

# Clone ViSP repo only if not already present, otherwise pull
WORKDIR ${HOME}

RUN git clone https://github.com/lagadic/visp.git $VISP_WS/visp;

# Now, configure and build ViSP
RUN mkdir -p $VISP_WS/visp-build \
  && cd $VISP_WS/visp-build \
  && cmake ../visp -DALLOW_SYSTEM_PYTHON=ON \
  && make -j$(nproc) visp_modules \
  && echo "export VISP_DIR=${HOME}/visp-ws/visp-build" >> ${HOME}/.bashrc \
  && echo 'export LD_LIBRARY_PATH=${VISP_WS}/visp-build:$LD_LIBRARY_PATH' >> ${HOME}/.bashrc

# Install VS code
# RUN sudo apt install -y wget gpg
# RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
# RUN sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
# RUN echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
# RUN rm -f packages.microsoft.gpg
# RUN sudo apt install -y apt-transport-https && sudo apt update && sudo apt install -y code
# RUN code --install-extension ms-vscode.cpptools && code --install-extension ms-iot.vscode-ros && code --install-extension ms-python.python && code --install-extension  ms-vscode.cpptools-themes && code --install-extension  ms-vscode.cpptools-extension-pack && code --install-extension cschlosser.doxdocgen
# RUN cp $VISP_WS/visp/.vscode/settings.json /home/user/.config/Code/User/settings.json

# The following line is needed in order to avoid 'groupmod: cannot lock /etc/grpup' error
#USER root

LABEL devcontainer.metadata='[{ \
  "remoteUser": "user", \
  "containerEnv": { \
    "XAUTHORITY": "/tmp/.Xauthority" \
  }, \
  "remoteEnv": { \
    "DISPLAY": "\${localEnv:DISPLAY}" \
  }, \
  "mounts": [ \
    "source=/tmp/.X11-unix,target=/tmp/.X11-unix,type=bind,consistency=cached", \
    "source=\${localEnv:HOME}/.Xauthority,target=/tmp/.Xauthority,type=bind,consistency=cached", \
    "source=/dev/dri,target=/dev/dri,type=bind,consistency=cached" \
  ] \
  }]'
