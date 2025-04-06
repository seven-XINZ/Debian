#!/bin/bash
# 启动脚本 for koishi
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/koishi"

docker run -d \
  --name koishi \
  --restart unless-stopped \
  -p 5140:5140 `# 用户可自定义主机端口` \
  -v /opt/apps/koishi:/koishi `# 用户可自定义路径` \
  -e TZ=Asia/Shanghai \
  -v /sata:/sata `# 示例，按需修改或添加其他挂载` \
  -v /sata1:/sata1 `# 示例` \
  koishijs/koishi:latest

