#!/bin/bash
# 启动脚本 for emby-official
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/emby-official/config"
mkdir -p "/mnt/media"

docker run -d \
  --name emby-official \
  -p 8096:8096 `# 用户可自定义主机端口` \
  -p 8920:8920 `# 用户可自定义主机端口 (SSL)` \
  -v /opt/apps/emby-official/config:/config `# 用户可自定义路径` \
  -v /mnt/media:/media `# 媒体目录，必须修改` \
  --device /dev/dri:/dev/dri `# 可选，用于硬件转码, 确保设备存在` \
  -e UID=1000 `# 建议非 root` \
  -e GID=100 `# 建议对应用户的组，可能是 users 或 users` \
  -e GIDLIST=44,109 `# 显卡相关组 ID, 根据系统调整 video, render` \
  --restart unless-stopped \
  emby/embyserver:latest

