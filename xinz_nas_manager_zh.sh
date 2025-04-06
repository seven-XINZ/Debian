#!/bin/bash

# ======================= 配置与信息 =======================
# 作者信息
AUTHOR="xinz"
QQ_GROUP="849427892"
PROJECT_URL="https://github.com/seven-XINZ"
SCRIPT_NAME="xinz-自动脚本适配所有Linux系统的一键系统初始化及所需安装"
INIT_MSG="·系统安装后首次运行，建议执行“系统初始化”。后重启一次系统再使用。"

# 基础目录 (假设脚本在主目录运行)
BASE_DIR="."
COMPOSE_DIR="$BASE_DIR/docker-compose"
RUN_DIR="$BASE_DIR/docker-run"
SCRIPTS_DIR="$BASE_DIR/scripts" # Define scripts directory
DEFAULT_BACKUP_DIR="$BASE_DIR/backups/docker"

# 终端颜色代码
declare -A COLORS=(
    ["INFO"]=$'\e[0;36m'    # 青色 - 信息
    ["SUCCESS"]=$'\e[0;32m' # 绿色 - 成功
    ["WARNING"]=$'\e[0;33m' # 黄色 - 警告
    ["ERROR"]=$'\e[0;31m'   # 红色 - 错误
    ["ACTION"]=$'\e[0;34m'  # 蓝色 - 用户操作提示
    ["WHITE"]=$'\e[1;37m'   # 粗体白色 - 菜单项
    ["RESET"]=$'\e[0m'      # 重置颜色
)

# ======================= 全局变量 =======================
DETECTED_OS="Unknown"
DETECTED_OS_LOWER="unknown"
SELECTED_OS=""
USER_DOCKER_BACKUP_PATH=""
TEMP_DIR=""
BACK_EXIT_OPTION="0"

# ======================= 基础工具模块 =======================
output() {
    local type="${1}" msg="${2}" custom_color="${3}" is_log="${4:-false}"
    local color="${custom_color:-${COLORS[$type]}}" prefix="" no_newline=false
    [[ -z "${color}" ]] && color="${COLORS[INFO]}"
    [[ "$type" == "ACTION" ]] && no_newline=true
    [[ "${is_log}" == "true" ]] && prefix="[${type}] "
    if $no_newline; then printf "%b%s%b" "${color}" "${prefix}${msg}" "${COLORS[RESET]}"; else printf "%b%s%b\n" "${color}" "${prefix}${msg}" "${COLORS[RESET]}"; fi
}
prompt_action() {
    local prompt_text="${1:-请选择操作}" def_opt="${2:-$BACK_EXIT_OPTION}" choices
    output "WHITE" "支持单选、多选，空格分隔，如: 1 2 3"
    output "ACTION" "${prompt_text} (输入 ${def_opt} 返回/退出): " "" "false"
    read -r choices; echo "$choices"
}
pause() { output "ACTION" "按 Enter 键继续..." ""; read -r; }
execute_placeholder() { output "INFO" "-> [模拟] 执行: $1 ..." "true"; sleep 0.5; output "SUCCESS" "-> [模拟] 完成: $1。" "true"; return 0; }
check_command() { command -v "$1" >/dev/null 2>&1; }
check_dependencies() {
    local missing="" needed=(wget curl grep awk sed tar) docker_needed=true
    for cmd in "${needed[@]}"; do check_command "$cmd" || missing+=" $cmd"; done
    check_command docker || docker_needed=false
    [[ -n "$missing" ]] && { output "ERROR" "缺少核心命令:${missing}。请先安装。" "" "true"; exit 1; }
    $docker_needed || output "WARNING" "未检测到 Docker, 相关功能将受限。" "true"
}

# ======================= 系统检测模块 =======================
detect_system() {
    local system="Unknown" system_lower="unknown" id_like=""
    if [[ -f "/etc/os-release" ]]; then
        system=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | sed 's/"//g'); system="${system^}"
        id_like=$(grep '^ID_LIKE=' /etc/os-release | cut -d'=' -f2 | sed 's/"//g'); system_lower="${system,,}"
    elif [[ -f "/etc/debian_version" ]]; then system="Debian"; system_lower="debian";
    elif check_command "uname"; then system=$(uname -s); system_lower="${system,,}"; fi
    if [[ "$system_lower" == "debian" ]] && grep -qi "fnos" /etc/os-release &>/dev/null; then system="Fnos"; system_lower="fnos"; fi
    DETECTED_OS="$system"; DETECTED_OS_LOWER="$system_lower"
    case "$DETECTED_OS_LOWER" in debian|ubuntu|fnos) ;; *) output "WARNING" "当前系统 (${DETECTED_OS}) 未明确适配。" "" "true";; esac
}

# ======================= 菜单与脚本映射 =======================
# Key: Script ID, Value: "script_name.sh|中文描述|适用系统(可选,逗号分隔,小写)"
declare -A SCRIPT_INFO=(
    # 系统初始配置 1x
    ["c11"]="config_sources.sh|配置软件源|debian,ubuntu,fnos"
    ["c12"]="install_prereqs.sh|安装必备软件|debian,ubuntu,fnos"
    # 系统管理面板 2x
    ["c21"]="install_cockpit.sh|安装面板Cockpit|debian,ubuntu,fnos"
    ["c22"]="install_cockpit_vm.sh|安装虚拟机组件|debian,ubuntu,fnos"
    ["c23"]="setup_cockpit_access.sh|外网访问Cockpit"
    ["c24"]="remove_cockpit_access.sh|删除外网访问配置"
    ["d25"]="setup_cockpit_network_debian.sh|设置Cockpit管理网络(Debian)|debian"
    ["u25"]="setup_cockpit_network_ubuntu.sh|设置Cockpit管理网络(Ubuntu)|ubuntu"
    # 邮件通知服务 3x
    ["c31"]="setup_email.sh|设置发送邮件账户"
    ["c32"]="setup_login_notify.sh|用户登录发送通知"
    ["c33"]="remove_login_notify.sh|取消用户登录通知"
    # 系统安全防护 4x
    ["c41"]="setup_basic_security.sh|基础安全设置"
    ["c42"]="install_firewall.sh|安装配置防火墙 (UFW/firewalld)"
    ["c43"]="install_fail2ban.sh|安装 Fail2Ban 防暴力破解"
    # Docker 服务 5x
    ["c51"]="install_docker.sh|安装 Docker & Docker Compose"
    ["c52"]="setup_docker_mirror.sh|添加镜像加速地址"
    ["c53"]="menu_install_docker_apps.sh|安装容器应用" # 特殊: 调用子菜单函数
    ["c54"]="docker_backup_restore.sh|备份与恢复"       # 特殊: 需要路径输入
    # 综合应用服务 6x
    ["c61"]="service_checker.sh|服务状态检查"
    ["c62"]="install_tailscale.sh|安装 Tailscale 内网穿透"
    ["c63"]="update_hosts.sh|自动更新 Hosts"
    # HomeNAS 一键配置 7x
    ["homenas_basic"]="c11 c12 c21 c51 c52 c61|基础版 HomeNAS 配置"
    ["homenas_secure"]="c11 c12 c21 c31 c32 c41 c42 c43 c51 c52 c61|安全版 HomeNAS 配置"

    # Docker Run Apps
    ["app_trilium"]="trilium.sh|Trilium 知识库"
    ["app_wechatferry"]="wechatferry.sh|WeChat Ferry 微信机器人"
    ["app_koishi"]="koishi.sh|Koishi 跨平台机器人框架"
    ["app_v2raya"]="v2raya.sh|V2RayA 透明代理"
    ["app_napcat"]="napcat.sh|NapCat QQ 机器人"
    ["app_bncr"]="bncr.sh|BNCR QQ 机器人框架"
    ["app_nastools"]="nas-tools.sh|NAS Tools 媒体整理"
    ["app_cookiecloud"]="cookiecloud.sh|CookieCloud Cookie 同步"
    ["app_moviepilot"]="moviepilot-v2.sh|MoviePilot V2 影视自动化"
    ["app_chinesesub"]="chinesesubfinder.sh|ChineseSubFinder 自动下载字幕"
    ["app_emby_official"]="emby-official.sh|Emby Server (官方版)"
    ["app_emby_ks"]="emby-ks.sh|Emby Server (开心版)"
    ["app_jellyfin"]="jellyfin.sh|Jellyfin 媒体服务器"
    ["app_qbittorrent"]="qbittorrent.sh|qBittorrent 下载器"
    ["app_transmission"]="transmission.sh|Transmission 下载器"
    ["app_jackett"]="jackett.sh|Jackett 索引器聚合"
    ["app_flaresolverr"]="flaresolverr.sh|FlareSolverr Cloudflare 绕过"
    ["app_iyuuplus"]="iyuuplus.sh|IYUUPlus 自动辅种"
    ["docker_movie_suite"]="run_movie_suite.sh|一键安装影视全家桶" # 特殊 key

    # Docker Compose Apps
    ["compose_ddnsgo"]="ddns-go.sh|ddns-go 动态 DNS"
    ["compose_dockge"]="dockge.sh|Dockge Docker 管理"
    ["compose_dweebui"]="dweebui.sh|DweebUI Docker Web UI"
    ["compose_nginxui"]="nginx-ui.sh|Nginx UI 反代面板"
    ["compose_portainer"]="portainer.sh|Portainer Docker 管理"
    ["compose_portainerzh"]="portainer_zh-cn.sh|Portainer Docker 管理 (中文)"
    ["compose_scrutiny"]="scrutiny.sh|Scrutiny 硬盘监控"
)

# 主菜单定义
declare -a MAIN_MENU_ORDER=( "系统初始配置" "系统管理面板" "邮件通知服务" "系统安全防护" "Docker服务" "综合应用服务" "一键配置HomeNAS" )

# 子菜单定义
declare -A SUBMENU_ITEMS=(
    ["系统初始配置"]="c11 c12"
    ["系统管理面板"]="c21 c22 c23 c24 d25 u25"
    ["邮件通知服务"]="c31 c32 c33"
    ["系统安全防护"]="c41 c42 c43"
    ["Docker服务"]="c51 c52 c53 c54"
    ["综合应用服务"]="c61 c62 c63"
    ["一键配置HomeNAS"]="homenas_basic homenas_secure"
    # 以下为 Docker 子菜单内部使用 (Key 需与 list_docker_apps 函数中的 app_type_name 匹配)
    ["Docker Run"]="app_trilium app_wechatferry app_koishi app_v2raya app_napcat app_bncr app_nastools app_cookiecloud app_moviepilot app_chinesesub app_emby_official app_emby_ks app_jellyfin app_qbittorrent app_transmission app_jackett app_flaresolverr app_iyuuplus docker_movie_suite"
    ["Docker Compose"]="compose_ddnsgo compose_dockge compose_dweebui compose_nginxui compose_portainer compose_portainerzh compose_scrutiny"
)

# 特殊 Key 定义
DOCKER_APP_INSTALL_KEY="c53"
DOCKER_BACKUP_RESTORE_KEY="c54"
MOVIE_SUITE_KEY="docker_movie_suite"
MOVIE_SUITE_APPS=("app_nastools" "app_cookiecloud" "app_moviepilot" "app_chinesesub" "app_emby_ks" "app_jellyfin" "app_qbittorrent" "app_jackett" "app_flaresolverr" "app_iyuuplus")

# ======================= 辅助函数 (菜单与脚本) =======================
get_script_desc() { local key="${1}"; local info="${SCRIPT_INFO[$key]}"; echo "${info#*|}" | cut -d'|' -f1; }
get_script_filename() { local key="${1}"; local info="${SCRIPT_INFO[$key]}"; echo "${info%%|*}"; }
is_script_applicable() {
    local key="${1}" info="${SCRIPT_INFO[$key]}" applicable_os_list
    # HomeNAS 和 Movie Suite Key 始终适用，不检查 OS
    [[ "$key" == homenas_* || "$key" == "$MOVIE_SUITE_KEY" ]] && return 0
    applicable_os_list=$(echo "${info#*|}" | cut -s -d'|' -f2)
    [[ -z "$applicable_os_list" ]] && return 0
    [[ ",${applicable_os_list}," == *",${DETECTED_OS_LOWER},"* ]] && return 0
    return 1
}

# ======================= Docker 备份路径处理 =======================
get_docker_backup_path() {
    # !!! Function Implementation Placeholder !!!
    # >>> PASTE FULL get_docker_backup_path FUNCTION CODE HERE <<<
    # Example (replace with full code):
     if [[ -z "$USER_DOCKER_BACKUP_PATH" ]]; then
        output "INFO" "尚未设置 Docker 备份目录。" true
        read -rp "$(output ACTION "请输入 Docker 备份的绝对路径 (留空使用 $DEFAULT_BACKUP_DIR): " "" false)" input_path
        USER_DOCKER_BACKUP_PATH="${input_path:-$DEFAULT_BACKUP_DIR}"
        if [[ "$USER_DOCKER_BACKUP_PATH" != /* ]]; then
            output "ERROR" "路径 '$USER_DOCKER_BACKUP_PATH' 不是绝对路径！" true; USER_DOCKER_BACKUP_PATH=""; return 1;
        fi
        # 尝试创建目录
        if ! mkdir -p "$USER_DOCKER_BACKUP_PATH"; then
             output "ERROR" "无法创建目录 '$USER_DOCKER_BACKUP_PATH'，请检查权限或路径。" true; USER_DOCKER_BACKUP_PATH=""; return 1;
        else
             output "SUCCESS" "备份路径设置为: $USER_DOCKER_BACKUP_PATH" true
        fi
     else
        output "INFO" "当前备份路径: $USER_DOCKER_BACKUP_PATH" true
        read -rp "$(output ACTION "确认使用此路径进行备份/恢复? (y/n/c 更改): " "" false)" confirm
        case "$confirm" in
            [Nn]) output "WARNING" "操作取消。" true; return 1 ;;
            [Cc]) USER_DOCKER_BACKUP_PATH=""; return $(get_docker_backup_path) ;; # 递归获取
            *) ;; # Yes or default
        esac
     fi
     # 检查可写性
     if [ ! -d "$USER_DOCKER_BACKUP_PATH" ] || [ ! -w "$USER_DOCKER_BACKUP_PATH" ]; then
         output "ERROR" "备份目录 '$USER_DOCKER_BACKUP_PATH' 不存在或不可写！" true; return 1;
     fi
     return 0
}

# ======================= Docker Run 定制模块 =======================
get_default_run_command() {
    # !!! Function Implementation Placeholder !!!
    # >>> PASTE FULL get_default_run_command FUNCTION CODE HERE <<<
    # Example (replace with full code):
    local script_file="$1" cmd="" capture=false line
    [[ ! -f "$script_file" ]] && return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        if ! $capture && [[ "$line" =~ ^# || -z "$line" ]]; then continue; fi
        if [[ "$line" =~ ^docker[[:space:]]+run ]]; then capture=true; cmd="$line";
        elif $capture; then cmd+="$line"; fi
        if $capture && [[ "$line" =~ \\$ ]]; then cmd=$(echo "$cmd" | sed 's/\\$//'); cmd+=" "; else break; fi
    done < "$script_file"
    cmd=$(echo "$cmd" | tr -s ' '); echo "$cmd"
    [[ "$cmd" =~ ^docker[[:space:]]+run ]] && return 0 || return 1
}
extract_docker_option() {
    # !!! Function Implementation Placeholder !!!
    # >>> PASTE FULL extract_docker_option FUNCTION CODE HERE <<<
    # Example (replace with full code):
    local command="$1" option="$2"; echo "$command" | grep -oP "(?<=${option}\s)(\S+)" | head -n 1
}
extract_docker_multi_option() {
    # !!! Function Implementation Placeholder !!!
    # >>> PASTE FULL extract_docker_multi_option FUNCTION CODE HERE <<<
    # Example (replace with full code):
    local command="$1" option="$2"; echo "$command" | grep -oP "${option}\s+[^[:space:]]+" | sed "s/${option}\s*//"
}
customize_and_run_docker() {
    # !!! Function Implementation Placeholder !!!
    # >>> PASTE FULL customize_and_run_docker FUNCTION CODE HERE <<<
    # Example (replace with full code):
    local script_file="$1" app_name="$2" default_cmd cmd_oneline image_name
    local default_name default_network default_restart default_puid default_pgid
    local -a default_ports default_volumes default_envs
    local use_default container_name network_mode restart_policy puid pgid
    local -a ports volumes envs
    local input_name net_choice custom_net input_ports input_volumes_str temp_vols current_vol valid_vols v
    local restart_choice retries input_puid input_pgid input_envs_str valid_envs e
    local final_cmd execute_final

    output "INFO" "--- 配置 Docker Run 应用: $app_name ---" true
    default_cmd=$(get_default_run_command "$script_file")
    if [[ $? -ne 0 || -z "$default_cmd" ]]; then
        output "ERROR" "无法从 $script_file 提取有效的 'docker run' 命令。" true; pause; return 1;
    fi
    output "WHITE" "检测到的默认命令:" "" false; echo ""; echo "$default_cmd" | sed 's/ -/\n  -/g' | sed 's/ \\//g'; echo "--------------------"

    read -rp "$(output ACTION "使用默认命令(1) 或 自定义(2)? [1]: " "" false)" use_default; use_default=${use_default:-1}

    if [[ "$use_default" == "1" ]]; then
        # -- 选择重启策略 --
        echo "选择容器启动项设置 (重启策略):"; echo "  1) no (不重启)"; echo "  2) on-failure[:次数]"; echo "  3) unless-stopped (默认)"; echo "  4) always"
        read -rp "$(output ACTION "请选择 [1-4, 回车默认 3]: " "" false)" restart_choice; restart_choice=${restart_choice:-3}
        case "$restart_choice" in
            1) restart_policy="no" ;;
            2) read -rp "$(output ACTION "输入 on-failure 重试次数 (可选, 如 :5): " "" false)" retries; restart_policy="on-failure${retries}" ;;
            4) restart_policy="always" ;;
            *) restart_policy="unless-stopped" ;;
        esac
        # 简单替换或添加 --restart (需要更健壮的实现来处理已有策略)
        cmd_oneline=$(echo "$default_cmd" | tr -d '\\\n' | tr -s ' ')
        final_cmd=$(echo "$cmd_oneline" | sed 's/--restart[= ][^ ]*//g') # 移除旧的
        if [[ "$restart_policy" != "no" ]]; then final_cmd+=" --restart=${restart_policy}"; fi
        output "INFO" "将使用默认命令并设置重启策略为: ${restart_policy}" true
        execute_placeholder "运行 $app_name (默认命令, 重启策略: $restart_policy)" "$final_cmd" # 模拟执行
        pause; return 0;
    fi

    # --- 开始自定义 ---
    output "INFO" "--- 开始自定义配置 ---" true
    cmd_oneline=$(echo "$default_cmd" | tr -d '\\\n' | tr -s ' ')
    image_name=$(echo "$cmd_oneline" | awk '{print $NF}')
    default_name=$(extract_docker_option "$cmd_oneline" "--name"); default_name=${default_name:-$app_name}
    default_network=$(extract_docker_option "$cmd_oneline" "--network"); default_network=${default_network:-bridge}
    default_restart=$(extract_docker_option "$cmd_oneline" "--restart"); default_restart=${default_restart:-no}
    default_puid=$(echo "$cmd_oneline" | grep -oP '(?<=-e\sPUID=)(\d+)' | head -n 1); default_puid=${default_puid:-1000}
    default_pgid=$(echo "$cmd_oneline" | grep -oP '(?<=-e\sPGID=)(\d+)' | head -n 1); default_pgid=${default_pgid:-1000}
    readarray -t default_ports < <(extract_docker_multi_option "$cmd_oneline" "-p")
    readarray -t default_volumes < <(extract_docker_multi_option "$cmd_oneline" "-v")
    readarray -t default_envs < <(extract_docker_multi_option "$cmd_oneline" "-e" | grep -v -e '^PUID=' -e '^PGID=')

    # -- 容器名称 --
    read -rp "$(output ACTION "容器名称 [默认: ${default_name}]: " "" false)" input_name; container_name="${input_name:-$default_name}"
    # -- 网络设置 --
    echo "网络模式: 1) bridge(默认) 2) host 3) 自定义"; echo "当前默认: ${default_network}"
    read -rp "$(output ACTION "请选择 [1-3, 回车默认]: " "" false)" net_choice
    case "$net_choice" in 1|"") network_mode="bridge";; 2) network_mode="host"; ports=();; 3) read -rp "$(output ACTION "输入自定义网络名: " "" false)" custom_net; network_mode="${custom_net:-bridge}";; *) network_mode="$default_network";; esac
    # -- 端口设置 --
    ports=("${default_ports[@]}"); if [[ "$network_mode" != "host" ]]; then echo "当前端口 (-p): ${ports[*]:-(无)}"; read -rp "$(output ACTION "新端口(空格分隔 host:cont): " "" false)" input_ports; if [[ -n "$input_ports" ]]; then read -r -a ports <<< "$input_ports"; fi; fi
    # -- 映射目录 --
    volumes=("${default_volumes[@]}"); echo "当前目录 (-v):"; if [[ ${#volumes[@]} -gt 0 ]]; then for vol in "${volumes[@]}"; do echo "  -v $vol"; done; else echo "  (无)"; fi
    echo "输入新目录(空格分隔 '-v /host:/cont'):"; read -rp "$(output ACTION "> " "" false)" input_volumes_str
    if [[ -n "$input_volumes_str" ]]; then temp_vols=(); current_vol=""; for item in $input_volumes_str; do if [[ "$item" == "-v" ]]; then [[ -n "$current_vol" ]] && temp_vols+=("$current_vol"); current_vol=""; else current_vol+="$item"; fi; done; [[ -n "$current_vol" ]] && temp_vols+=("$current_vol"); valid_vols=(); for v in "${temp_vols[@]}"; do [[ "$v" == *":"* && "$v" == *"/"* ]] && valid_vols+=("$v") || output WARNING "忽略无效卷 '$v'"; done; volumes=("${valid_vols[@]}"); fi
    # -- PUID/GUID --
    echo "PUID/PGID (0=root, 1000=普通用户):"
    read -rp "$(output ACTION "PUID [默认: ${default_puid}]: " "" false)" input_puid; puid="${input_puid:-$default_puid}"
    read -rp "$(output ACTION "PGID [默认: ${default_pgid}]: " "" false)" input_pgid; pgid="${input_pgid:-$default_pgid}"
    # -- 环境变量 --
    envs=("${default_envs[@]}"); echo "当前环境变量 (-e, 除PUID/PGID):"; if [[ ${#envs[@]} -gt 0 ]]; then for env_var in "${envs[@]}"; do echo "  -e $env_var"; done; else echo "  (无)"; fi
    echo "输入新环境变量(空格分隔 'VAR=val'):"; read -rp "$(output ACTION "> " "" false)" input_envs_str
    if [[ -n "$input_envs_str" ]]; then read -r -a envs <<< "$input_envs_str"; valid_envs=(); for e in "${envs[@]}"; do [[ "$e" == *"="* ]] && valid_envs+=("$e") || output WARNING "忽略无效环境变量 '$e'"; done; envs=("${valid_envs[@]}"); fi
    # -- 重启策略 --
    echo "重启策略: 1) no 2) on-failure[:次数] 3) unless-stopped(默认) 4) always"; echo "当前默认: ${default_restart}"
    read -rp "$(output ACTION "请选择 [1-4, 回车默认 3]: " "" false)" restart_choice; restart_choice=${restart_choice:-3}
    case "$restart_choice" in 1) restart_policy="no";; 2) read -rp "$(output ACTION "输入on-failure重试次数(如 :5): " "" false)" retries; restart_policy="on-failure${retries}";; 4) restart_policy="always";; *) restart_policy="unless-stopped";; esac

    # -- 构建命令 --
    final_cmd="docker run -d"; final_cmd+=" --name \"$container_name\""
    [[ "$network_mode" != "bridge" ]] && final_cmd+=" --network=\"$network_mode\""
    [[ "$restart_policy" != "no" ]] && final_cmd+=" --restart=\"$restart_policy\""
    if [[ "$network_mode" != "host" ]]; then for p in "${ports[@]}"; do final_cmd+=" -p \"$p\""; done; fi
    for v in "${volumes[@]}"; do final_cmd+=" -v \"$v\""; done
    for e in "${envs[@]}"; do final_cmd+=" -e \"$e\""; done
    [[ -n "$puid" ]] && final_cmd+=" -e PUID=\"$puid\""; [[ -n "$pgid" ]] && final_cmd+=" -e PGID=\"$pgid\""
    final_cmd+=" \"$image_name\""

    # -- 确认执行 --
    output "INFO" "--- 最终配置和命令 ---" true; echo "名称: $container_name, 网络: $network_mode, 重启: $restart_policy"; echo "端口: ${ports[*] TBC}"; echo "卷: ${volumes[*] TBC}"; echo "PUID/PGID: $puid/$pgid"; echo "环境变量: ${envs[*] TBC}"; echo "镜像: $image_name"
    output "WHITE" "生成的命令:"; echo "$final_cmd" | sed 's/ -/\n  -/g'; echo "--------------------"
    read -rp "$(output ACTION "是否执行此命令? (y/n): " "" false)" execute_final
    if [[ "$execute_final" =~ ^[Yy]$ ]]; then execute_placeholder "运行 $app_name (自定义命令)" "$final_cmd"; else output "WARNING" "操作已取消。" true; fi
    pause; return 0;
}

# ======================= Docker 应用列表与处理 =======================
run_docker_compose_app() {
    local script_file="$1" app_name="$2" compose_file yaml_content cmd
    output "INFO" "--- 执行 Docker Compose 应用: $app_name ---" true
    output "INFO" "脚本/YAML文件: $script_file" true
    compose_file="${script_file%.sh}.yaml"
    cmd=""
    if [[ -f "$script_file" && "$script_file" == *.sh ]]; then # 如果是 .sh 脚本
        if grep -q "docker-compose" "$script_file"; then # 脚本内含 compose 命令
           cmd="bash \"$script_file\""
        elif head -n 1 "$script_file" | grep -q -e "version:" -e "services:"; then # 看起来像 YAML
           output "INFO" "检测到脚本 '$script_file' 可能包含 YAML 内容，尝试直接使用..." true
           cmd="docker-compose -f \"$script_file\" up -d"
        elif [[ -f "$compose_file" ]]; then # 检查同名 YAML
           output "INFO" "找到同名 YAML 文件 '$compose_file'，将使用它..." true
           cmd="docker-compose -f \"$compose_file\" up -d"
        fi
    elif [[ -f "$script_file" && "$script_file" == *.yaml || "$script_file" == *.yml" ]]; then # 如果直接给了 YAML
        cmd="docker-compose -f \"$script_file\" up -d"
    elif [[ -f "$compose_file" ]]; then # 如果给了 .sh 但实际是 .yaml
         output "INFO" "找到同名 YAML 文件 '$compose_file'，将使用它..." true
         cmd="docker-compose -f \"$compose_file\" up -d"
    fi

    if [[ -n "$cmd" ]]; then
        execute_placeholder "部署 Compose 应用: $app_name" "$cmd"
    else
        output "ERROR" "无法确定如何执行 Compose 应用 '$app_name' (检查脚本/YAML文件是否存在或格式正确)。" true
        return 1
    fi
    pause
}
list_docker_apps() {
    local app_dir="$1" app_type_name="$2" run_handler="$3" # app_type_name is "Docker Run" or "Docker Compose"
    local options=() filenames=() file_key_map=() i=1
    local menu_keys=(${SUBMENU_ITEMS["$app_type_name"]}) # Use app_type_name to get keys
    local selected_items=() choice choice_array valid confirm

    output "INFO" "查找 '$app_dir' 中的 $app_type_name 应用..." true

    for key in "${menu_keys[@]}"; do
        local filename=$(get_script_filename "$key")
        local desc=$(get_script_desc "$key")
        local filepath="${app_dir}/${filename}"
        # 对于 Compose，也接受 .yaml/.yml 文件
        local check_path="$filepath"
        [[ "$app_type_name" == "Docker Compose" && ! -f "$check_path" ]] && check_path="${filepath%.sh}.yaml"
        [[ "$app_type_name" == "Docker Compose" && ! -f "$check_path" ]] && check_path="${filepath%.sh}.yml"

        if [[ -f "$check_path" || "$key" == "$MOVIE_SUITE_KEY" ]]; then
             options+=("$check_path") # Store the actual path found (.sh, .yaml, or dummy for suite)
             filenames+=("$desc")
             file_key_map["$check_path"]="$key" # Map actual path to key
             output "WHITE" "$i) $desc"
             ((i++))
        else
            output "WARNING" "配置文件中定义的文件 '$filename' (或 .yaml/.yml) 未在 '$app_dir' 找到，已跳过。" true
        fi
    done

    [[ ${#options[@]} -eq 0 ]] && { output "WARNING" "在 '$app_dir' 中未找到可用的应用。" true; pause; return; }
    output "WHITE" "$BACK_EXIT_OPTION) 返回"

    local choices=$(prompt_action)
    [[ -z "$choices" ]] && choices="0"
    IFS=' ' read -r -a choice_array <<< "$choices"; [[ " ${choice_array[*]} " =~ " $BACK_EXIT_OPTION " ]] && return

    valid=true; declare -A seen; selected_items=()
    for choice in "${choice_array[@]}"; do
        if ! [[ "$choice" =~ ^[1-9][0-9]*$ && "$choice" -le ${#options[@]} ]]; then valid=false; break; fi
        if [[ -z "${seen[$choice]}" ]]; then seen[$choice]=1; selected_items+=("$choice"); fi
    done

    if [[ "$valid" == "true" && ${#selected_items[@]} -gt 0 ]]; then
        output "INFO" "已选应用:" true; local item_descs=(); for idx in "${selected_items[@]}"; do item_descs+=("${filenames[$((idx - 1))]}"); done
        printf "  - %s\n" "${item_descs[@]}"
        read -rp "$(output ACTION "确认安装/执行? (y/n): " "" false)" confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            for idx in "${selected_items[@]}"; do
                local selected_filepath="${options[$((idx - 1))]}"
                local selected_key="${file_key_map[$selected_filepath]}"
                local selected_desc="${filenames[$((idx - 1))]}"

                if [[ "$selected_key" == "$MOVIE_SUITE_KEY" ]]; then run_movie_suite;
                elif declare -f "$run_handler" > /dev/null; then "$run_handler" "$selected_filepath" "$selected_desc";
                else output "ERROR" "处理函数 '$run_handler' 未定义！" true; execute_placeholder "执行 $selected_desc" "echo Error"; fi
            done
        else output "WARNING" "操作已取消。" true; fi
    else output "ERROR" "输入包含无效选项。" true; fi
    pause
}

# ======================= 脚本执行与菜单显示 =======================
execute_script_or_action() {
    local key="${1}" filename description script_path
    filename=$(get_script_filename "${key}")
    description=$(get_script_desc "${key}")
    script_path="${SCRIPTS_DIR}/${filename}"

    output "ACTION" "--- 开始执行: ${description} (${key}) ---" "" false; echo "" # Add newline after prompt

    case "$key" in
        "$DOCKER_APP_INSTALL_KEY") show_docker_install_apps_menu ;;
        "$DOCKER_BACKUP_RESTORE_KEY")
            if get_docker_backup_path; then
                output "INFO" "使用目录 '$USER_DOCKER_BACKUP_PATH' 进行 Docker 备份/恢复。" true
                # bash "${SCRIPTS_DIR}/docker_backup_restore_helper.sh" "$USER_DOCKER_BACKUP_PATH" || return 1 # Call helper script
                execute_placeholder "Docker 备份与恢复 (使用 $USER_DOCKER_BACKUP_PATH)"
                pause
            else
                output "WARNING" "未设置或确认备份目录，操作中止。" true; pause; return 1;
            fi
            ;;
        *) # 执行普通子脚本
            if [[ -f "$script_path" ]]; then
                [[ ! -x "$script_path" ]] && chmod +x "$script_path"
                # 使用 sudo 执行子脚本，因为很多操作需要 root 权限
                # 如果子脚本内部处理了 sudo，则这里不需要
                # 为了简单起见，如果主脚本是 sudo 运行的，子脚本自然也是
                if bash "$script_path"; then
                    output "SUCCESS" "--- ${description} (${key}) 执行成功 ---" true
                else
                    output "ERROR" "--- ${description} (${key}) 执行失败 ---" true; pause; return 1;
                fi
            else
                output "ERROR" "子脚本文件 '$script_path' 未找到！" true; pause; return 1;
            fi
            ;;
    esac
    return 0
}
run_homenas_config() {
    local key="${1}" description script_keys_string script_keys total_steps current_step=1 confirm sub_key sub_desc
    description=$(get_script_desc "${key}")
    script_keys_string=$(echo "${SCRIPT_INFO[$key]}" | cut -d'|' -f1)
    script_keys=($script_keys_string)
    total_steps=${#script_keys[@]}

    output "ACTION" "--- 开始执行一键配置: ${description} ---"
    read -rp "$(output ACTION "此操作将执行 ${total_steps} 个步骤，确认开始? (y/n): " "" false)" confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { output "WARNING" "操作已取消。" true; return; }

    for sub_key in "${script_keys[@]}"; do
        sub_desc=$(get_script_desc "$sub_key")
        output "INFO" "==> [步骤 ${current_step}/${total_steps}] 正在执行: ${sub_desc} <==" true
        if is_script_applicable "$sub_key"; then
             if ! execute_script_or_action "$sub_key"; then
                 output "ERROR" "步骤 ${current_step} (${sub_desc}) 执行失败！中止一键配置。" true; pause; return 1;
             fi
        else
             output "WARNING" "步骤 ${current_step} (${sub_desc}) 不适用于当前系统 (${DETECTED_OS})，已跳过。" true
        fi
        ((current_step++))
    done
    output "SUCCESS" "--- 一键配置 (${description}) 执行完成 ---"; pause
}
run_movie_suite() {
    output "ACTION" "--- 开始执行一键安装影视全家桶 ---"
    local total_steps=${#MOVIE_SUITE_APPS[@]} current_step=1 confirm sub_key sub_desc app_filepath app_desc

    read -rp "$(output ACTION "此操作将安装 ${total_steps} 个影视相关应用，确认开始? (y/n): " "" false)" confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { output "WARNING" "操作已取消。" true; return; }

    for sub_key in "${MOVIE_SUITE_APPS[@]}"; do
        app_filepath="${RUN_DIR}/$(get_script_filename "$sub_key")"
        app_desc=$(get_script_desc "$sub_key")

        output "INFO" "==> [影视套件 ${current_step}/${total_steps}] 正在安装: ${app_desc} <==" true
        if [[ -f "$app_filepath" ]]; then
            if ! customize_and_run_docker "$app_filepath" "$app_desc"; then # Use customize function
                 output "ERROR" "安装 ${app_desc} 失败！中止影视套件安装。" true; pause; return 1;
            fi
        else
             output "ERROR" "应用脚本 '$app_filepath' 未找到！跳过 ${app_desc}。" true
        fi
        ((current_step++))
    done
     output "SUCCESS" "--- 一键安装影视全家桶 执行完成 ---"; pause
}
show_docker_install_apps_menu() {
     while true; do
        show_header
        output "INFO" "已选: 5 Docker服务 -> 3 安装容器应用"
        output "WHITE" "1、Docker Compose 应用 (来自 '$COMPOSE_DIR')"
        output "WHITE" "2、Docker Run 应用 (来自 '$RUN_DIR')"
        output "WHITE" "$BACK_EXIT_OPTION、返回"
        output "INFO" "===================="

        local choice=$(prompt_action "" "$BACK_EXIT_OPTION")
        case "$choice" in
            1) list_docker_apps "$COMPOSE_DIR" "Docker Compose" "run_docker_compose_app" ;;
            2) list_docker_apps "$RUN_DIR" "Docker Run" "customize_and_run_docker" ;; # Use correct type name
            "$BACK_EXIT_OPTION") break ;;
            *) output "ERROR" "无效选择。" ; sleep 1 ;;
        esac
    done
}
display_submenu() {
    local title="${1}" menu_keys_string all_menu_keys applicable_keys=() i=1 key choices choice_array valid_selection selected_keys confirm_execution exec_success
    menu_keys_string="${SUBMENU_ITEMS[$title]}"
    all_menu_keys=($menu_keys_string)

    for key in "${all_menu_keys[@]}"; do is_script_applicable "$key" && applicable_keys+=("$key"); done
    [[ ${#applicable_keys[@]} -eq 0 ]] && { output "WARNING" "菜单 '${title}' 下无适用选项。" true; pause; return; }

    while true; do
        show_header; output "INFO" "已选: ${title}"; output "INFO" "--------------------------------------------------"
        i=1; for key in "${applicable_keys[@]}"; do output "WHITE" "${i}) $(get_script_desc "${key}")"; ((i++)); done
        output "WHITE" "${BACK_EXIT_OPTION}) 返回"; output "INFO" "=================================================="

        choices=$(prompt_action); [[ -z "$choices" ]] && choices="0"
        IFS=' ' read -r -a choice_array <<< "$choices"; [[ " ${choice_array[*]} " =~ " $BACK_EXIT_OPTION " ]] && break

        valid_selection=true; selected_keys=(); declare -A seen_choice
        for c in "${choice_array[@]}"; do
             if ! [[ "$c" =~ ^[1-9][0-9]*$ && "$c" -le ${#applicable_keys[@]} ]]; then [[ "$c" == "$BACK_EXIT_OPTION" ]] && continue; valid_selection=false; break; fi
             if [[ -z "${seen_choice[$c]}" ]]; then seen_choice[$c]=1; selected_keys+=("${applicable_keys[$((c - 1))]}") ;fi
        done

        if [[ "$valid_selection" == "true" && ${#selected_keys[@]} -gt 0 ]]; then
            output "INFO" "已选操作:" true; local item_descs=(); for key in "${selected_keys[@]}"; do item_descs+=("$(get_script_desc "${key}")"); done; printf "  - %s\n" "${item_descs[@]}"
            read -rp "$(output ACTION "确认执行? (y/n): " "" false)" confirm_execution
            if [[ "$confirm_execution" =~ ^[Yy]$ ]]; then
                exec_success=true
                for key in "${selected_keys[@]}"; do
                    # Handle one-click configs first
                    if [[ "$key" == homenas_* ]]; then run_homenas_config "$key" || exec_success=false
                    # No Movie suite here, it's under Docker Run apps
                    else execute_script_or_action "$key" || exec_success=false; fi
                    $exec_success || { output "ERROR" "执行 '$(get_script_desc "$key")' 时出错。" true; break; }
                done
                if $exec_success; then output "SUCCESS" "所选操作已执行完毕。"; else output "WARNING" "部分操作执行失败。"; fi; pause;
                # Optional: break here to return to main menu after execution
                # break
            else output "WARNING" "操作已取消。" true; sleep 1; fi
        else output "ERROR" "输入包含无效选项。" true; sleep 1; fi
    done
}
main_menu() {
    if [[ -z "$SELECTED_OS" ]]; then
        show_header; output "INFO" "检测到系统: ${DETECTED_OS} (${DETECTED_OS_LOWER})"; output "WHITE" "选择目标配置系统:"
        output "WHITE" "1) Debian"; output "WHITE" "2) Ubuntu"; output "WHITE" "3) Fnos"; output "WHITE" "4) 其他 (使用 ${DETECTED_OS})"
        local os_choice; while true; do os_choice=$(prompt_action "请选择" "4"); case "$os_choice" in 1) SELECTED_OS="debian";break;; 2) SELECTED_OS="ubuntu";break;; 3) SELECTED_OS="fnos";break;; 4|"") SELECTED_OS="${DETECTED_OS_LOWER}";break;; *) output "ERROR" "无效选择.";; esac; done
        output "SUCCESS" "配置目标系统: ${SELECTED_OS^}"; sleep 1;
    fi
    while true; do
        show_header; output "INFO" "主菜单 (系统: ${DETECTED_OS}, 目标: ${SELECTED_OS^})"; output "INFO" "--------------------------------------------------"
        local i=1; for title in "${MAIN_MENU_ORDER[@]}"; do output "WHITE" "$i) $title"; ((i++)); done
        output "WHITE" "$BACK_EXIT_OPTION) 退出"; output "INFO" "=================================================="
        local choice=$(prompt_action "" "$BACK_EXIT_OPTION")
        [[ "$choice" == "$BACK_EXIT_OPTION" ]] && break
        if [[ "$choice" =~ ^[1-9][0-9]*$ && "$choice" -le ${#MAIN_MENU_ORDER[@]} ]]; then display_submenu "${MAIN_MENU_ORDER[$((choice - 1))]}";
        else output "ERROR" "无效选择。"; sleep 1; fi
    done
}

# ======================= 主程序入口 =======================
# 检查是否以 root 运行 (如果需要)
# [[ $EUID -ne 0 ]] && { output "ERROR" "此脚本需要 root 权限运行。" "" "true"; exit 1; }

check_dependencies
detect_system
TEMP_DIR=$(mktemp -d /tmp/xinz_nas_script.XXXXXX); [[ -z "$TEMP_DIR" || ! -d "$TEMP_DIR" ]] && { echo "无法创建临时目录"; exit 1; }
output "INFO" "使用临时目录: $TEMP_DIR" true
trap 'printf "\n"; output "WARNING" "用户中断，清理退出..." "" "true"; rm -rf "${TEMP_DIR}"; exit 1' INT TERM
trap 'output "INFO" "脚本结束，清理..."; rm -rf "${TEMP_DIR}"; exit 0' EXIT

# 显示首次运行提示
[[ -n "$INIT_MSG" ]] && output "WARNING" "$INIT_MSG"

# 启动主菜单
main_menu

# 退出 (被 EXIT trap 处理)
exit 0
