#!/bin/bash
# 启动脚本 for qbittorrent
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/qbittorrent/config"
mkdir -p "/mnt/downloads"
mkdir -p "/mnt/media"

docker run -d \
  --name=qbittorrent \
  --network host `# 使用 host 网络` \
  -e PUID=1000 `# 建议非 root` \
  -e PGID=1000 `# 建议非 root` \
  -e TZ=Asia/Shanghai \
  -e WEBUI_PORT=18080 `# WebUI 端口` \
  -e TORRENTING_PORT=6881 `# BT 传入端口 (TCP/UDP)` \
  -v /opt/apps/qbittorrent/config:/config `# 用户可自定义路径` \
  -v /mnt/downloads:/downloads `# 下载目录，必须修改` \
  -v /mnt/media:/media `# 挂载媒体目录方便移动` \
  --restart unless-stopped \
  linuxserver/qbittorrent:latest

