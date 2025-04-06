#!/bin/bash
# 启动脚本 for emby-ks
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/emby-ks/config"
mkdir -p "/mnt/media"

docker run -d \
  -v /opt/apps/emby-ks/config:/config `# 用户可自定义路径` \
  -v /mnt/media:/media `# 媒体目录，必须修改` \
  -p 8097:8096 `# 映射到不同主机端口避免冲突` \
  -p 8921:8920 `# 映射到不同主机端口避免冲突` \
  --device /dev/dri:/dev/dri `# 可选，硬件转码` \
  -e UID=1000 `# 建议非 root` \
  -e GID=100 `# 建议对应用户的组` \
  -e GIDLIST=44,109 `# 显卡相关组 ID, 根据系统调整` \
  --restart=always \
  --name Emby-ks \
  amilys/embyserver:latest # 使用 latest 可能更方便，或指定版本如 4.8.0.56

