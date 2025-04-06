#!/bin/bash
# 启动 scrutiny 的 Compose 脚本
SCRIPT_DIR="$(dirname "$0")"
YAML_FILE="${SCRIPT_DIR}/scrutiny.yaml"
echo "部署 scrutiny (Compose)..."
echo "!!! 重要: 请先编辑 ${YAML_FILE} 文件，确保 'devices' 部分正确映射了你系统上的所有物理硬盘设备 (例如 /dev/sda, /dev/sdb 等) !!!"
read -p "编辑完成后按 Enter 继续部署..."

# 检查 docker-compose 命令
if ! command -v docker-compose &> /dev/null; then
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose -f "${YAML_FILE}" up -d
    else
        echo "错误: 未找到 docker-compose 或 docker compose 命令。" >&2
        exit 1
    fi
else
    docker-compose -f "${YAML_FILE}" up -d
fi
