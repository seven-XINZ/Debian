#!/bin/bash
# 启动脚本 for napcat
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

docker run -d \
-e ACCOUNT="YOUR_QQ_ACCOUNT" `# 必须修改为你的QQ号` \
-e NAPCAT_GID=0 \
-e NAPCAT_UID=0 \
-e WSR_ENABLE=true \
-e WS_URLS=\[ws://172.17.0.1:5140/onebot,ws://172.17.0.1:9099/api/bot/qqws]'

