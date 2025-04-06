#!/bin/bash
# 启动脚本 for trilium
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/trilium/data"

docker run -d \
  --name trilium \
  --restart=always \
  --log-opt max-size=1m \
  -v /opt/apps/trilium/data:/root/trilium-data `# 用户可自定义路径` \
  -e TRILIUM_DATA_DIR=/root/trilium-data \
  -p 8080:8080 `# 用户可自定义主机端口` \
  nriver/trilium-cn:latest

