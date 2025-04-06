#!/bin/bash
# 启动脚本 for flaresolverr
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

docker run -d \
  --name=flaresolverr \
  -p 8191:8191 `# 用户可自定义主机端口` \
  -e LOG_LEVEL=info \
  -e TZ=Asia/Shanghai \
  -e TEST_URL=https://www.cloudflare.com/ `# 测试 URL` \
  --restart unless-stopped \
  ghcr.io/flaresolverr/flaresolverr:latest

