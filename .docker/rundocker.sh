xhost +local:root

HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose up -d --build

