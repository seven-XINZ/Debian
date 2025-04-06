#!/bin/bash
# 启动脚本 for moviepilot-v2
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/mnt/media"
mkdir -p "/opt/apps/moviepilot-v2/config"
mkdir -p "/opt/apps/moviepilot-v2/core"

docker run -itd \
    --name moviepilot-v2 \
    --hostname moviepilot-v2 \
    --network host `# 使用 host 网络` \
    # -p 3000:3000 # host模式下无需映射 \
    # -p 3001:3001 # host模式下无需映射 \
    -v /mnt/media:/media `# 媒体目录，必须修改` \
    -v /opt/apps/moviepilot-v2/config:/config `# 用户可自定义路径` \
    -v /opt/apps/moviepilot-v2/core:/moviepilot/.cache/ms-playwright `# 用户可自定义路径` \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -e "NGINX_PORT=3000" `# WebUI 访问端口` \
    -e "PORT=3001" `# 内部服务端口` \
    -e "PUID=1000" `# 建议非 root` \
    -e "PGID=1000" `# 建议非 root` \
    -e "UMASK=022" \
    -e "TZ=Asia/Shanghai" \
    -e "AUTH_SITE=iyuu" `# 修改为你的认证站点` \
    -e "IYUU_SIGN=YOUR_IYUU_TOKEN" `# 必须修改为你的 IYUU 令牌` \
    -e "SUPERUSER=admin" `# 建议修改默认管理员名` \
    -e "PROXY_HOST=" `# 按需设置代理` \
    -e "GITHUB_TOKEN=" `# 按需设置 Github PAT` \
    --restart always \
    jxxghp/moviepilot-v2:latest

