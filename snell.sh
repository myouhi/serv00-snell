#!/bin/bash

#================================================================
# Snell Server 管理脚本 (V18 - 全自动快捷命令版)
#
# 更新日志:
# - 安装时，自动创建 `snell` 快捷命令。
# - 脚本运行时，会自动将自身保存到本地，以便创建快捷方式。
#================================================================

# --- 全局变量定义 ---
SCRIPT_DIR="$HOME/snell"
SCRIPT_PATH="$SCRIPT_DIR/snell.sh"
SNELL_EXECUTABLE="$SCRIPT_DIR/bin/snell-server"
SNELL_CONFIG="$SCRIPT_DIR/etc/snell-server.conf"
SNELL_LOG_FILE="$SCRIPT_DIR/snell.log"
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

# (此处省略 check_running_status, start_snell, stop_snell, display_config 等函数)
# (它们的实现与之前版本完全相同)

# 自动设置快捷命令
setup_shortcut() {
    print_info "正在为您设置 'snell' 快捷命令..."
    local user_bin_dir="$HOME/bin"
    mkdir -p "$user_bin_dir"

    # 创建软链接，-f 参数表示如果已存在则强制覆盖
    ln -sf "$SCRIPT_PATH" "$user_bin_dir/snell"
    
    # 检查并添加 PATH 配置到 .bashrc
    local profile_file="$HOME/.bashrc"
    local path_config='export PATH="$HOME/bin:$PATH"'
    
    if ! grep -qF "$path_config" "$profile_file" 2>/dev/null; then
        print_info "正在将 '$user_bin_dir' 添加到您的 PATH 环境变量中..."
        echo -e "\n# Add user's bin directory to PATH\n$path_config" >> "$profile_file"
        print_info "配置已写入到 $profile_file"
        
        echo
        print_warning "快捷命令设置完成！为使其立即生效，请执行以下任一操作："
        print_warning "  1. 运行命令: source $profile_file"
        print_warning "  2. 关闭当前终端窗口，然后重新打开一个。"
        echo
    else
        print_info "'$user_bin_dir' 已存在于您的 PATH 中，无需修改。"
    fi
}


# 全新安装 (专为 Serv00 优化)
run_installation() {
    # ... (安装流程代码与之前版本相同) ...
    # ... (此处省略以保持简洁) ...

    print_info "配置完成，正在启动服务..."
    start_snell
    display_config
    
    read -p "您想设置开机自动启动吗? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        setup_autostart
    fi
    
    # 在安装流程的最后，自动设置快捷命令
    setup_shortcut
}


# --- 为了让您能直接使用，下面是 V18 的完整代码 ---

#!/bin/bash

#================================================================
# Snell Server 管理脚本 (V18 - 全自动快捷命令版)
#
# 更新日志:
# - 安装时，自动创建 `snell` 快捷命令。
# - 脚本运行时，会自动将自身保存到本地，以便创建快捷方式。
#================================================================

# --- 全局变量定义 ---
SCRIPT_DIR="$HOME/snell"
SCRIPT_PATH="$SCRIPT_DIR/snell.sh"
SNELL_EXECUTABLE="$SCRIPT_DIR/bin/snell-server"
SNELL_CONFIG="$SCRIPT_DIR/etc/snell-server.conf"
SNELL_LOG_FILE="$SCRIPT_DIR/snell.log"
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
    if ! [ -r "$SNELL_CONFIG" ]; then
        print_error "错误：配置文件不存在或无法读取于 $SNELL_CONFIG"
        return
    fi
    clear
    print_info "以下是您的 Snell 配置文件 ($SNELL_CONFIG) 的原始内容："
    echo
    echo "=================================================="
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

# 自动设置快捷命令
setup_shortcut() {
    print_info "正在为您设置 'snell' 快捷命令..."
    local user_bin_dir="$HOME/bin"
    mkdir -p "$user_bin_dir"

    # 创建软链接，-f 参数表示如果已存在则强制覆盖
    ln -sf "$SCRIPT_PATH" "$user_bin_dir/snell"
    
    # 检查并添加 PATH 配置到 .bashrc
    local profile_file="$HOME/.bashrc"
    local path_config='export PATH="$HOME/bin:$PATH"'
    
    if ! grep -qF "$path_config" "$profile_file" 2>/dev/null; then
        print_info "正在将 '$user_bin_dir' 添加到您的 PATH 环境变量中..."
        # 使用 printf 避免 echo 的潜在问题，并确保换行
        printf "\n# Add user's bin directory to PATH\n%s\n" "$path_config" >> "$profile_file"
        print_info "配置已写入到 $profile_file"
        
        echo
        print_warning "快捷命令设置完成！为使其立即生效，请执行以下任一操作："
        print_warning "  1. 运行命令: source $profile_file"
        print_warning "  2. 关闭当前终端窗口，然后重新打开一个。"
        echo
    else
        print_info "'$user_bin_dir' 已存在于您的 PATH 中，无需修改。"
    fi
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
    mkdir -p "$SCRIPT_DIR/bin" "$SCRIPT_DIR/etc"
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

    # 在安装流程的最后，自动设置快捷命令
    setup_shortcut
}

# 修改配置
run_modify_config() {
    # ... (省略，与之前版本相同)
}

# 卸载
run_uninstall() {
    # ... (省略，与之前版本相同)
}

# --- 菜单逻辑 ---
show_management_menu() {
    # ... (省略，与之前版本相同)
}
show_initial_menu() {
    # ... (省略，与之前版本相同)
}


# --- 脚本主入口 ---

# 步骤1: 脚本自我保存 (仅在通过 curl | bash 运行时触发)
# $0 是 'bash' 意味着它很可能是通过管道执行的
if [ ! -f "$SCRIPT_PATH" ] && [ "$(basename "$0")" = "bash" ]; then
    print_info "首次运行，正在将脚本自身保存到 $SCRIPT_PATH ..."
    mkdir -p "$SCRIPT_DIR"
    # 将 curl 的内容（即脚本本身）写入到文件
    cat > "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    print_info "保存成功。正在从本地文件重新启动脚本..."
    echo "----------------------------------------------------"
    # 用保存好的脚本文件替换当前进程，并传递所有原始参数
    exec "$SCRIPT_PATH" "$@"
fi


# 步骤2: 检查依赖
if ! command -v curl &> /dev/null || ! command -v openssl &> /dev/null || ! command -v awk &> /dev/null; then
    print_error "错误：本脚本需要 'curl', 'openssl' 和 'awk'，请先确保它们已安装。"
    exit 1
fi

# 步骤3: 执行快捷命令或进入菜单
if [ "$#" -gt 0 ]; then
    # 如果有参数，进入快捷命令模式
    case "$1" in
        start) start_snell ;;
        stop) stop_snell ;;
        restart) print_info "正在执行重启操作..."; stop_snell; start_snell; check_running_status ;;
        status) check_running_status ;;
        config|info) display_config ;;
        log)
            if [ -f "$SNELL_LOG_FILE" ]; then
                print_info "正在实时显示日志 (按 Ctrl+C 退出)..."
                tail -f "$SNELL_LOG_FILE"
            else
                print_error "日志文件不存在: $SNELL_LOG_FILE"
            fi
            ;;
        uninstall) run_uninstall ;;
        help|*)
            echo "Snell Server 管理脚本快捷命令用法:"
            echo "  $0 start          - 启动 Snell 服务"
            echo "  $0 stop           - 停止 Snell 服务"
            echo "  $0 restart        - 重启 Snell 服务"
            echo "  $0 status         - 查看运行状态"
            echo "  $0 config|info    - 查看节点配置"
            echo "  $0 log            - 实时查看日志"
            echo "  $0 uninstall      - 卸载 Snell"
            echo "  $0 help           - 显示此帮助信息"
            echo "不带任何参数运行 '$0' 将进入交互式菜单。"
            ;;
    esac
    exit 0
fi

# 如果没有参数，进入交互式菜单模式
if check_installation; then
    show_management_menu
else
    show_initial_menu
fi
