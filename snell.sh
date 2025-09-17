#!/bin/bash

#================================================================
# Snell Server 管理脚本 (serv00专用版V3版本 ）V4和v5不能使用
# 在 Serv00 平台，您需要先手动获取一个端口。
# 请按照以下步骤操作：
# 1. 在浏览器中打开并登录您的 Serv00 控制面板。
# 2. 在左侧菜单中找到 'Porty' (Ports) 选项并点击进入。
# 3. 点击 'Add port' 按钮，创建tcp端口号。
# 4. 运行脚本
# 5. bash <(curl -sSL https://raw.githubusercontent.com/myouhi/serv00-snell/refs/heads/master/snell.sh)

# 管理脚本快捷命令
# 1. 下载脚本到正确的位置
# 2. curl -o ~/snell/snell.sh https://raw.githubusercontent.com/myouhi/serv00-snell/master/snell.sh
# 3. 给脚本加上执行权限
# 4. chmod +x ~/snell/snell.sh
# 5. 运行
# 6. source ~/.bashrc
# 7. 然后再次尝试 snell 命令
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

# 重启 Snell 服务 (更可靠)
restart_snell() {
    if ! check_installation; then print_error "Snell 未安装，无法重启。"; return 1; fi
    
    print_info "正在执行重启操作..."
    
    # 步骤1: 停止当前服务
    if pgrep -f "snell-server" > /dev/null; then
        print_info "  -> 正在停止当前服务..."
        killall snell-server &>/dev/null
        
        # 循环检测以确认进程已终止
        local counter=0
        while pgrep -f "snell-server" > /dev/null; do
            if [ $counter -ge 5 ]; then
                print_error "  -> 无法停止旧的 Snell 进程！请手动检查。"
                return 1
            fi
            sleep 1
            ((counter++))
        done
        print_info "  -> 服务已停止。"
    else
        print_warning "  -> 服务当前未在运行，将直接启动。"
    fi
    
    # 步骤2: 启动新服务
    print_info "  -> 正在启动新服务..."
    nohup "$SNELL_EXECUTABLE" -c "$SNELL_CONFIG" > "$SNELL_LOG_FILE" 2>&1 &
    sleep 2
    if pgrep -f "snell-server" > /dev/null; then
        print_info "✅ 服务已成功重启！"
    else
        print_error "❌ 服务启动失败！请检查日志。"
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

    ln -sf "$SCRIPT_PATH" "$user_bin_dir/snell"

    local profile_file="$HOME/.bashrc"
    local path_config='export PATH="$HOME/bin:$PATH"'

    if ! grep -qF "$path_config" "$profile_file" 2>/dev/null; then
        print_info "正在将 '$user_bin_dir' 添加到您的 PATH 环境变量中..."
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

# 全新安装
run_installation() {
    clear
    echo "========================================"
    echo "      安装向导 (Serv00)"
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

    setup_shortcut
}

# 【全新重写】修改配置 (使用临时文件，确保兼容性)
run_modify_config() {
    if ! [ -w "$SNELL_CONFIG" ]; then
        print_error "错误：配置文件不可写！请检查权限：$SNELL_CONFIG"
        return 1
    fi
    
    print_warning "修改端口前，请确保新端口已经在 Serv00 后台为您分配！"
    echo "您想修改什么？"
    echo "  1. 修改端口号"
    echo "  2. 重新生成 PSK (密码)"
    read -p "请输入选项: " choice

    local temp_file="$SNELL_CONFIG.tmp"
    local success=false

    case "$choice" in
        1)
            while true; do
                read -p "请输入 Serv00 为您分配的【新】端口号: " NEW_PORT
                if [[ "$NEW_PORT" =~ ^[0-9]+$ ]] && [ "$NEW_PORT" -gt 1024 ]; then break; else print_warning "输入无效！"; fi
            done
            # 读取原文件，修改 listen 行，输出到临时文件
            sed "s/^listen = .*/listen = 0.0.0.0:$NEW_PORT/" "$SNELL_CONFIG" > "$temp_file"
            if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
                # 成功后，用临时文件覆盖原文件
                mv "$temp_file" "$SNELL_CONFIG"
                print_info "端口已更新为 $NEW_PORT。"
                success=true
            else
                print_error "创建临时配置文件失败！"
            fi
            ;;
        2)
            NEW_PSK=$(openssl rand -base64 24)
            # 读取原文件，修改 psk 行，输出到临时文件
            sed "s/^psk = .*/psk = $NEW_PSK/" "$SNELL_CONFIG" > "$temp_file"
            if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
                # 成功后，用临时文件覆盖原文件
                mv "$temp_file" "$SNELL_CONFIG"
                print_info "PSK 已被重置为一个新的随机密码。"
                success=true
            else
                print_error "创建临时配置文件失败！"
            fi
            ;;
        *) 
            print_warning "无效选择。"
            return
            ;;
    esac

    # 清理可能残留的临时文件
    [ -f "$temp_file" ] && rm -f "$temp_file"

    if [ "$success" = true ]; then
        print_info "配置已修改，正在重启服务以应用新配置..."
        restart_snell
    else
        print_error "配置修改失败，服务未重启。"
    fi
}

# 卸载
run_uninstall() {
    read -p "这将彻底删除 Snell 所有文件和配置，确定吗? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then print_info "操作已取消。"; return; fi

    stop_snell
    crontab -l 2>/dev/null | grep -v "snell-server" | crontab -
    rm -rf "$SCRIPT_DIR"
    print_info "✅ Snell 已被成功卸载。"
}

# --- 菜单逻辑 ---
show_management_menu() {
    while true; do
        clear
        echo "========================================"
        echo "      Snell Server 管理菜单"
        echo "========================================"
        check_running_status

        echo
        echo "请选择操作："
        echo "  1. 启动"
        echo "  2. 停止"
        echo "  3. 重启"
        echo "  4. 修改配置"
        echo "  5. 开机自启"
        echo "  6. 节点信息"
        echo "  7. 卸载"
        echo "  0. 退出脚本"
        echo

        read -p "请输入选项: " choice
        case "$choice" in
            1) start_snell ;;
            2) stop_snell ;;
            3) restart_snell ;;
            4) run_modify_config ;;
            5) setup_autostart ;;
            6) display_config ;;
            7) run_uninstall; echo "卸载完成，脚本将退出。"; sleep 2; exit 0 ;;
            0) echo "正在退出。"; exit 0 ;;
            *) print_warning "无效输入。" ;;
        esac

        echo
        read -n 1 -s -r -p "按任意键返回主菜单..."
    done
}
show_initial_menu() {
    clear
    echo "========================================"
    echo "      安装向导 (Serv00)"
    echo "      (未检测到 Snell 安装)"
    echo "========================================"
    echo
    echo "请选择操作："
    echo "  1. 安装"
    echo "  0. 退出安装"
    echo

    read -p "请输入选项 [1, 0]: " choice

    case "$choice" in
        1) run_installation ;;
        0) echo "正在退出。"; exit 0 ;;
        *) print_error "无效输入。"; exit 1 ;;
    esac
}


# --- 脚本主入口 ---

# 步骤1: 脚本自我保存
if [ ! -f "$SCRIPT_PATH" ] && [ "$(basename "$0")" = "bash" ]; then
    print_info "首次运行，正在将脚本自身保存到 $SCRIPT_PATH ..."
    mkdir -p "$SCRIPT_DIR"
    cat > "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    print_info "保存成功。正在从本地文件重新启动脚本..."
    echo "----------------------------------------------------"
    exec "$SCRIPT_PATH" "$@"
fi


# 步骤2: 检查依赖
if ! command -v curl &> /dev/null || ! command -v openssl &> /dev/null || ! command -v awk &> /dev/null; then
    print_error "错误：本脚本需要 'curl', 'openssl' 和 'awk'，请先确保它们已安装。"
    exit 1
fi

# 步骤3: 执行快捷命令或进入菜单
if [ "$#" -gt 0 ]; then
    case "$1" in
        start) start_snell ;;
        stop) stop_snell ;;
        restart) restart_snell ;;
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
            echo "  $0 start          - 启动"
            echo "  $0 stop           - 停止"
            echo "  $0 restart        - 重启"
            echo "  $0 status         - 查看运行状态"
            echo "  $0 config|info    - 节点信息"
            echo "  $0 log            - 实时查看日志"
            echo "  $0 uninstall      - 卸载"
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
