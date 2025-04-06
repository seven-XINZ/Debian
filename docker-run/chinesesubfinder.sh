#!/bin/bash
# 启动脚本 for chinesesubfinder
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/chinesesubfinder/config"
mkdir -p "/mnt/media"
mkdir -p "/opt/apps/chinesesubfinder/cache"

docker run -d \
    -v /opt/apps/chinesesubfinder/config:/config `# 用户可自定义路径` \
    -v /mnt/media:/media `# 媒体目录，必须修改` \
    -v /opt/apps/chinesesubfinder/cache:/root/.cache/rod/browser `# 用户可自定义路径` \
    -e PUID=1000 `# 建议非 root` \
    -e PGID=1000 `# 建议非 root` \
    -e PERMS=true \
    -e TZ=Asia/Shanghai \
    -e UMASK=022 \
    -p 19035:19035 `# 用户可自定义主机端口` \
    --name chinesesubfinder \
    --hostname chinesesubfinder \
    --log-driver "json-file" \
    --log-opt "max-size=100m" \
    --restart unless-stopped \
    allanpk716/chinesesubfinder

