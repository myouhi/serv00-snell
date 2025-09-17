#!/bin/bash

#================================================================
# Snell Server 管理脚本 (V13 - Bug修复版)
#
# 更新日志:
# - 修复了导致 "unexpected EOF" 错误的语法问题。
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

# 显示当前配置
display_config() {
    if ! check_installation; then print_error "Snell 未安装。"; return; fi

    print_info "正在刷新节点信息..."
    local ip=$(curl -s icanhazip.com)
    local port=$(awk -F':' '/listen/ {print $NF}' "$SNELL_CONFIG")
    local psk=$(awk -F'=' '/psk/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$SNELL_CONFIG")

    clear
    echo -e "\033[1;32m========== SNELL 节点信息 ==========\033[0m"
    if [[ -z "$port" || -z "$psk" ]]; then
        echo -e "  \033[1;31m错误：无法从配置文件中读取端口或PSK！\033[0m"
        echo -e
