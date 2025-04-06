#!/bin/bash
# 启动脚本 for nas-tools
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/nas-tools/config"
mkdir -p "/mnt/media"

docker run -d \
    --name nas-tools \
    --hostname nas-tools \
    -p 3000:3000 `# 用户可自定义主机端口` \
    -v /opt/apps/nas-tools/config:/config `# 用户可自定义路径` \
    -v /mnt/media:/media    `# 媒体目录，必须修改为你的实际媒体库路径` \
    -e PUID=1000 `# 建议使用非 root 用户 ID` \
    -e PGID=1000 `# 建议使用非 root 组 ID` \
    -e UMASK=022 `# 推荐的 umask` \
    -e NASTOOL_AUTO_UPDATE=false \
    -e NASTOOL_CN_UPDATE=false \
    --restart unless-stopped \
    hsuyelin/nas-tools

