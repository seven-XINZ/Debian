#!/bin/bash
# 启动脚本 for jellyfin
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/mnt/media"
mkdir -p "/opt/apps/jellyfin/config"
mkdir -p "/opt/apps/jellyfin/cache"

docker run -d \
    --name=Jellyfin \
    -p 8099:8096 `# 映射到不同主机端口` \
    -v /mnt/media:/media `# 媒体目录，必须修改` \
    -v /opt/apps/jellyfin/config:/config `# 用户可自定义路径` \
    -v /opt/apps/jellyfin/cache:/cache `# 用户可自定义路径` \
    -e TZ=Asia/Shanghai \
    -e PUID=1000 `# 建议非 root` \
    -e PGID=1000 `# 建议非 root` \
    --device /dev/dri:/dev/dri `# 可选，硬件转码` \
    --restart unless-stopped \
    jellyfin/jellyfin:latest
# 可选镜像: linuxserver/jellyfin 或 nyanmisaka/jellyfin

