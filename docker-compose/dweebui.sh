#!/bin/bash
# 启动 dweebui 的 Compose 脚本
SCRIPT_DIR="$(dirname "$0")"
YAML_FILE="${SCRIPT_DIR}/dweebui.yaml"
echo "正在使用 ${YAML_FILE} 部署 dweebui..."
# 检查 docker-compose 命令
if ! command -v docker-compose &> /dev/null; then
    # 如果 docker-compose 不存在，尝试使用 docker compose (v2)
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose -f "${YAML_FILE}" up -d
    else
        echo "错误: 未找到 docker-compose 或 docker compose 命令。" >&2
        exit 1
    fi
else
    docker-compose -f "${YAML_FILE}" up -d
fi
