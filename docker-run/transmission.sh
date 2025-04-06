#!/bin/bash
# 启动脚本 for transmission
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/transmission/config"
mkdir -p "/mnt/downloads"
mkdir -p "/opt/apps/transmission/watch"
mkdir -p "/opt/apps/transmission/webui"

docker run -d \
  --name=transmission \
  --network=host `# 使用 host 网络` \
  -e PUID=1000 `# 建议非 root` \
  -e PGID=1000 `# 建议非 root` \
  -e TZ=Asia/Shanghai \
  -e TRANSMISSION_WEB_HOME=/webui/combustion-release/ `# 使用 Combustion WebUI` \
  -e USER="admin" `# WebUI 用户名, 建议修改` \
  -e PASS="password" `# WebUI 密码, 必须修改!` \
  -e PEERPORT="51413" `# BT 传入端口` \
  -v /opt/apps/transmission/config:/config `# 用户可自定义路径` \
  -v /mnt/downloads:/downloads `# 下载目录，必须修改` \
  -v /opt/apps/transmission/watch:/watch `# 监控目录` \
  -v /opt/apps/transmission/webui:/webui `# 挂载 WebUI 文件` \
  --restart unless-stopped \
  linuxserver/transmission:latest

