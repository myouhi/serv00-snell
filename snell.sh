#!/bin/bash

#================================================================
# Snell Server 管理脚本 (V13 - 调试版)
#
# 更新日志:
# - 在 display_config 函数中增加了详细的调试输出，用于定位问题。
#================================================================

# --- 全局变量定义 ---
SNELL_DIR="$HOME/snell"
SNELL_EXECUTABLE="$SNELL_DIR/bin/snell-server"
SNELL_CONFIG="$SNELL_DIR/etc/snell-server.conf"
SNELL_LOG_FILE="$SNELL_DIR/snell.log"
DOWNLOAD_URL="https://raw.githubusercontent.com/myouhi/serv00-snell/master/snell-server"

# --- 基础函数 ---
print_info() { echo -e "\033[32m[信息]\033[0m $1"; }
print_warning() { echo -e "\033[33m[警告]\033[0m $1"; }
print_error() { echo -e "\033[31m[错误]\033[0m $1"; }
print_debug() { echo -e "\033[35m[DEBUG]\033[0m $1"; } # 新增调试信息打印函数

# 检查 Snell 是否已安装
check_installation() {
    [ -f "$SNELL_EXECUTABLE" ]
}

# --- 核心功能函数 ---

# 检查当前运行状态并显示
check_running_status() {
    if pgrep -f "snell-server" > /dev/null; then
        echo -e "  当前状态: \033[1;32m● 运行中\033[0m"
    else
        echo -e "  当前状态: \033[1;31m● 已停止\033[0m"
    fi
}

# 启动 Snell 服务
start_snell() {
    if ! check_installation; then print_error "Snell 未安装，无法启动。"; return 1; fi
    if pgrep -f "snell-server" > /dev/null; then
        print_warning "Snell 服务已经在运行中。"
        return
    fi
    print_info "正在启动 Snell 服务..."
    nohup "$SNELL_EXECUTABLE" -c "$SNELL_CONFIG" > "$SNELL_LOG_FILE" 2>&1 &
    sleep 2
    if pgrep -f "snell-server" > /dev/null; then print_info "✅ 服务已成功启动！"; else print_error "❌ 服务启动失败！请检查日志。"; fi
}

# 停止 Snell 服务
stop_snell() {
    if ! check_installation; then print_error "Snell 未安装，无法停止。"; return 1; fi
    print_info "正在停止 Snell 服务..."
    if pgrep -f "snell-server" > /dev/null; then
        killall snell-server &>/dev/null
        sleep 1
        print_info "✅ 服务已停止。"
    else
        print_warning "Snell 服务当前未在运行。"
    fi
}

# 显示当前配置 (增加了调试功能)
display_config() {
    if ! check_installation; then print_error "Snell 未安装。"; return; fi
    
    print_info "正在刷新节点信息..."
    
    # --- 新增的调试步骤 ---
    echo
    print_debug "开始诊断..."
    print_debug "配置文件路径: $SNELL_CONFIG"

    if [ -f "$SNELL_CONFIG" ]; then
        print_debug "文件存在。正在检查文件权限..."
        ls -l "$SNELL_CONFIG"
        print_debug "正在打印文件原始内容 (使用 cat 命令):"
        echo "--- 文件内容开始 ---"
        cat "$SNELL_CONFIG"
        echo "--- 文件内容结束 ---"
    else
        print_debug "错误：配置文件不存在！"
        return
    fi
    
    # 使用 awk 提取信息
    local port_cmd="awk -F':' '/listen/ {print \$NF}' \"$SNELL_CONFIG\""
    local psk_cmd="awk -F'=' '/psk/ {gsub(/^[ \t]+|[ \t]+$/, \"\", \$2); print \$2}' \"$SNELL_CONFIG\""
    
    print_debug "将要执行的 port提取命令: $port_cmd"
    local port=$(eval "$port_cmd")
    
    print_debug "将要执行的 psk 提取命令: $psk_cmd"
    local psk=$(eval "$psk_cmd")
    
    print_debug "提取后的 port 变量值为: '$port'"
    print_debug "提取后的 psk 变量值为: '$psk'"
    print_debug "诊断结束。"
    echo
    # --- 调试步骤结束 ---

    local ip=$(curl -s icanhazip.com)

    clear
    echo -e "\033[1;32m========== SNELL 节点信息 ==========\033[0m"
    if [[ -z "$port" || -z "$psk" ]]; then
        echo -e "  \033[1;31m错误：无法从配置文件中读取端口或PSK！\033[0m"
        echo -e "  \033[1;31m请查看上方的 [DEBUG] 信息以分析原因。\033[0m"
    else
        echo -e "  服务器地址: \033[1;33m${ip:-<获取失败, 请手动查询>}\033[0m"
        echo -e "  端口: \033[1;33m${port}\033[0m"
        echo -e "  密码 (PSK): \033[1;33m${psk}\033[0m"
        echo -e "  混淆 (obfs): \033[1;33mhttp\033[0m"
    fi
    echo -e "\033[1;32m====================================\033[0m"
}


# (此处省略其他未修改的函数: setup_autostart, run_installation, run_modify_config, run_uninstall)
# ...
# 全新安装 (专为 Serv00 优化)
run_installation() {
    clear
    echo "========================================"
    echo "      Snell Server 安装向导 (Serv00)"
    echo "========================================"
    echo
    print_warning "重要：在 Serv00 平台，您需要先手动获取一个端口。"
    echo "请按照以下步骤操作："
    echo "  1. 在浏览器中打开并登录您的 Serv00 控制面板。"
    echo "  2. 在左侧菜单中找到 'Porty' (Ports) 选项并点击进入。"
    echo "  3. 点击 'Add port' 按钮，Serv00 会为您分配一个端口号。"
    echo "  4. 将那个分配给您的端口号，输入到下面的提示框中。"
    echo
    
    while true; do
        read -p "请输入 Serv00 为您分配的端口号: " LISTEN_PORT
        if [[ "$LISTEN_PORT" =~ ^[0-9]+$ ]] && [ "$LISTEN_PORT" -gt 1024 ]; then
            break
        else
            print_warning "输入无效！请输入一个有效的数字端口号。"
        fi
    done

    print_info "好的，将使用端口: $LISTEN_PORT"
    print_info "开始执行自动化安装..."

    PSK=$(openssl rand -base64 24)
    mkdir -p "$SNELL_DIR/bin" "$SNELL_DIR/etc"
    echo -e "[snell-server]\nlisten = 0.0.0.0:$LISTEN_PORT\npsk = $PSK\nobfs = http" > "$SNELL_CONFIG"
    print_info "正在下载 Snell 程序..."
    curl -L -s "$DOWNLOAD_URL" -o "$SNELL_EXECUTABLE" && chmod +x "$SNELL_EXECUTABLE"
    
    print_info "配置完成，正在启动服务..."
    start_snell
    display_config
    
    read -p "您想设置开机自动启动吗? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        setup_autostart
    fi
}

# 修改配置 (专为 Serv00 优化)
run_modify_config() {
    print_warning "修改端口前，请确保新端口已经在 Serv00 后台为您分配！"
    echo "您想修改什么？"
    echo "  1. 修改端口号"
    echo "  2. 重新生成 PSK (密码)"
    read -p "请输入选项: " choice
    case "$choice" in
        1)
            while true; do
                read -p "请输入 Serv00 为您分配的【新】端口号: " NEW_PORT
                if [[ "$NEW_PORT" =~ ^[0-9]+$ ]] && [ "$NEW_PORT" -gt 1024 ]; then break; else print_warning "输入无效！"; fi
            done
            sed -i "s/listen = .*/listen = 0.0.0.0:$NEW_PORT/" "$SNELL_CONFIG"
            print_info "端口已更新为 $
