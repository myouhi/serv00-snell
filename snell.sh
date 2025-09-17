#!/bin/bash

#================================================================
# Snell Server 管理脚本 (V16 - 直接显示配置文件)
#
# 更新日志:
# - 根据用户建议，将“查看节点信息”功能修改为直接使用 cat 命令
#   显示配置文件的原始内容，确保信息显示的绝对可靠。
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

# 显示当前配置 (根据您的建议重写)
display_config() {
    if ! [ -r "$SNELL_CONFIG" ]; then
        print_error "错误：配置文件不存在或无法读取于 $SNELL_CONFIG"
        return
    fi

    clear
    print_info "以下是您的 Snell 配置文件 ($SNELL_CONFIG) 的原始内容："
    echo
    echo "=================================================="
    # 直接使用 cat 命令显示文件内容
    cat "$SNELL_CONFIG"
    echo "=================================================="
    echo
    print_info "您的 IP 地址是: $(curl -s icanhazip.com)"
    print_info "请根据以上信息在您的客户端中进行配置。"
}

# 设置开机自启
setup_autostart() {
    if ! check_installation; then print_error "Snell 未安装，无法设置自启。"; return; fi
    local cron_command="@reboot nohup $SNELL_EXECUTABLE -c $SNELL_CONFIG > $SNELL_LOG_FILE 2>&1 &"
    (crontab -l 2>/dev/null | grep -Fv "snell-server"; echo "$cron_command") | crontab -
    print_info "✅ 开机自启设置/更新成功！"
}

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
    # 注意这里写入文件的格式，确保没有多余空格
    echo "[snell-server]" > "$SNELL_CONFIG"
    echo "listen = 0.0.0.0:$LISTEN_PORT" >> "$SNELL_CONFIG"
    echo "psk = $PSK" >> "$SNELL_CONFIG"
    echo "obfs = http" >> "$SNELL_CONFIG"

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
            sed -i "s/^listen = .*/listen = 0.0.0.0:$NEW_PORT/" "$SNELL_CONFIG"
            print_info "端口已更新为 $NEW_PORT。"
            ;;
        2)
            NEW_PSK=$(openssl rand -base64 24)
            sed -i "s/^psk = .*/psk = $NEW_PSK/" "$SNELL_CONFIG"
            print_info "PSK 已被重置为一个新的随机密码。"
            ;;
        *) print_warning "无效选择。"; return ;;
    esac

    print_info "配置已修改，为使新配置生效，服务将自动重启..."
    stop_snell
    start_snell
}

# 卸载
run_uninstall() {
    read -p "这将彻底删除 Snell 所有文件和配置，确定吗? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then print_info "操作已取消。"; return; fi

    stop_snell
    crontab -l 2>/dev/null | grep -v "snell-server" | crontab -
    rm -rf "$SNELL_DIR"
    print_info "✅ Snell 已被成功卸载。"
}

# --- 菜单逻辑 ---

# 管理菜单 (已安装时显示)
show_management_menu() {
    while true; do
        clear
        echo "========================================"
        echo "      Snell Server 管理菜单"
        echo "========================================"
        check_running_status # 显示运行状态

        echo
        echo "请选择操作："
        echo "  1. 启动 Snell 服务"
        echo "  2. 停止 Snell 服务"
        echo "  3. 重启 Snell 服务"
        echo "  4. 修改配置 (端口 / PSK)"
        echo "  5. 设置/更新开机自启"
        echo "  6. 查看节点信息 (直接显示配置文件)"
        echo "  7. 卸载 Snell"
        echo "  q. 退出脚本"
        echo

        read -p "请输入选项: " choice
        case "$choice" in
            1) start_snell ;;
            2) stop_snell ;;
            3) print_info "正在重启服务..."; stop_snell; start_snell ;;
            4) run_modify_config ;;
            5) setup_autostart ;;
            6) display_config ;;
            7) run_uninstall; echo "卸载完成，脚本将退出。"; sleep 2; exit 0 ;;
            q|Q) echo "正在退出。"; exit 0 ;;
            *) print_warning "无效输入。" ;;
        esac

        echo
        read -n 1 -s -r -p "按任意键返回主菜单..."
    done
}

# 初始菜单 (未安装时显示)
show_initial_menu() {
    clear
    echo "========================================"
    echo "      Snell Server 安装向导 (Serv00)"
    echo "      (未检测到 Snell 安装)"
    echo "========================================"
    echo
    echo "请选择操作："
    echo "  1. 开始全新安装 Snell"
    echo "  q. 退出安装"
    echo

    read -p "请输入选项 [1, q]: " choice

    case "$choice" in
        1) run_installation ;;
        q|Q) echo "正在退出。"; exit 0 ;;
        *) print_error "无效输入。"; exit 1 ;;
    esac
}

# --- 脚本主入口 ---
if ! command -v curl &> /dev/null || ! command -v openssl &> /dev/null || ! command -v awk &> /dev/null; then
    print_error "错误：本脚本需要 'curl', 'openssl' 和 'awk'，请先确保它们已安装。"
    exit 1
fi

if check_installation; then
    show_management_menu
else
    show_initial_menu
fi
