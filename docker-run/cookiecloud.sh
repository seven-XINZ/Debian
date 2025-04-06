#!/bin/bash
# 启动脚本 for cookiecloud
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/cookiecloud/data"

docker run -d \
  --name cookiecloud-app \
  --restart always \
  -e API_ROOT=/cookie \
  -v /opt/apps/cookiecloud/data:/data/api/data `# 用户可自定义路径` \
  -p 8088:8088 `# 用户可自定义主机端口` \
  easychen/cookiecloud:latest

