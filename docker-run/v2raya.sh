#!/bin/bash
# 启动脚本 for v2raya
# !!! 下面的 docker run 命令块将被主脚本解析 !!!

# 尝试创建默认的本地挂载目录 (如果不存在)
mkdir -p "/opt/apps/v2raya"

docker run -d \
  --restart=always \
  --privileged \
  --network=host `# 使用 host 网络` \
  --name v2raya \
  -e V2RAYA_LOG_FILE=/tmp/v2raya.log \
  -e V2RAYA_V2RAY_BIN=/usr/local/bin/v2ray `# 默认v2ray, 可改为xray路径` \
  -e V2RAYA_NFTABLES_SUPPORT=off `# 可按需开启` \
  -e IPTABLES_MODE=legacy `# 可选 nftables` \
  -v /lib/modules:/lib/modules:ro \
  -v /etc/resolv.conf:/etc/resolv.conf \
  -v /opt/apps/v2raya:/etc/v2raya `# 用户可自定义路径` \
  mzz2017/v2raya
# 可选使用xray: # -e V2RAYA_V2RAY_BIN=/usr/local/bin/xray

