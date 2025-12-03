FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Layer for stable base dependencies that rarely change
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core toolchain
    build-essential \
    gcc \
    g++ \
    gdb \
    cmake \
    # SSH and utilities
    openssh-server \
    git \
    vim \
    curl \
    unzip \
    zip \
    wget \    
    ca-certificates \    
    sudo \
    gosu \
    software-properties-common \
    # Recommended C++ tools
    linux-tools-common \
    # Python
    python3 \
    python3-pip \    
    && rm -rf /var/lib/apt/lists/*

# 4. 配置 NVIDIA 运行时环境变量
# 即使没有 CUDA Toolkit，这两个变量告诉 nvidia-container-toolkit 注入驱动和图形库
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,graphics,utility,display

# Create a non-root user for development
ARG HOST_UID=1000
ARG HOST_GID=1000

# Set up SSH daemon directory
RUN mkdir -p /var/run/sshd

# Modified to use ARG and add to root group
RUN (getent passwd $HOST_UID | cut -d: -f1 | xargs -r userdel -f) && \
    (getent group $HOST_GID | cut -d: -f1 | xargs -r groupdel) && \
    groupadd -g $HOST_GID dev && \
    useradd -m -s /bin/bash -u $HOST_UID -g $HOST_GID -G root,sudo dev && \
    echo 'root:root' | chpasswd && \
    echo 'dev:dev' | chpasswd && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Configure SSH to permit root login with a password
# [修改点] 将默认监听端口从 22 改为 2222
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

EXPOSE 2222

WORKDIR /workspace

# Layer for frequently updated libraries.
# Place any library you expect to update often here.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libeigen3-dev \
    # 图形开发库 (编译 OpenLoong 必须)
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libglvnd-dev \
    libglfw3-dev \
    libx11-dev \
    libxrandr-dev \
    libxi-dev \
    libxcursor-dev \
    libxinerama-dev \
    freeglut3-dev \
    # 图形测试工具
    mesa-utils \
    x11-apps \
    # analysis tools
    valgrind \
    cppcheck \
    && rm -rf /var/lib/apt/lists/*


# 5. 创建启动脚本 (Entrypoint) (要求 3)
# 逻辑：Root 启动 SSH -> 降权切换 dev -> 执行命令
RUN echo '#!/bin/bash\n\
# [新增] 自动设置 XDG_RUNTIME_DIR 以解决 GLFW/MuJoCo 报错\n\
export XDG_RUNTIME_DIR=/tmp/runtime-dev\n\
mkdir -p $XDG_RUNTIME_DIR\n\
chmod 700 $XDG_RUNTIME_DIR\n\
\n\
# 将环境变量保存到 /etc/environment，供 SSH 使用\n\
env | grep "^DISPLAY" >> /etc/environment\n\
# [新增] 也将 XDG 变量保存给 SSH\n\
echo "XDG_RUNTIME_DIR=/tmp/runtime-dev" >> /etc/environment\n\
\n\
# add dev for vscode-server\n\
chown -R dev:dev /home/dev/.vscode-server 2>/dev/null || true \n\
# Start SSH service\n\
service ssh start\n\
\n\
# Switch to dev user and execute command\n\
exec gosu dev "$@"' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh


ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
