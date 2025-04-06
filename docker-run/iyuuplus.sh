#!/bin/bash
# 启动脚本 for iyuuplus
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/iyuuplus/config"
mkdir -p "/opt/apps/iyuuplus/db"
mkdir -p "/opt/apps/qbittorrent/config/qBittorrent/BT_backup"
mkdir -p "/opt/apps/transmission/config/torrents"

docker run -itd \
    -v /opt/apps/iyuuplus/config:/IYUU/config `# 用户可自定义路径` \
    -v /opt/apps/iyuuplus/db:/IYUU/db `# 用户可自定义路径` \
    -v /opt/apps/qbittorrent/config/qBittorrent/BT_backup:/qbit_backup:ro `# qb 种子备份目录, 必须修改为实际路径` \
    -v /opt/apps/transmission/config/torrents:/tr_torrents:ro `# tr 种子文件目录, 必须修改为实际路径` \
    -p 8780:8780 `# 用户可自定义主机端口` \
    --name IYUUPlus \
    --restart=always \
    iyuucn/iyuuplus:latest

