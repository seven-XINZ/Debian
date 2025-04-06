#!/bin/bash
# 启动脚本 for wechatferry
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/wechatferry/wechat"

docker run --name wechatferry -d \
 -p 8001:8080 `# 用户可自定义主机端口` \
 -p 8000:8000 `# 用户可自定义主机端口` \
 -v /opt/apps/wechatferry/wechat:/home/app/wechat `# 用户可自定义路径` \
 -e CALLBACK_URL="http://172.17.0.1:9090/api/bot/ferry" `# 需要修改为实际回调地址` \
 jackytj/wcf-docker

