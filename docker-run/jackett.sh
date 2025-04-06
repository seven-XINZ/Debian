#!/bin/bash
# 启动脚本 for jackett
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/jackett/config"
mkdir -p "/mnt/downloads/blackhole"

docker run -d \
  --name=jackett \
  -e PUID=1000 `# 建议非 root` \
  -e PGID=1000 `# 建议非 root` \
  -e TZ=Asia/Shanghai \
  -p 9117:9117 `# 用户可自定义主机端口` \
  -v /opt/apps/jackett/config:/config `# 用户可自定义路径` \
  -v /mnt/downloads/blackhole:/downloads `# Jackett 的黑洞目录` \
  --restart unless-stopped \
  linuxserver/jackett:latest

