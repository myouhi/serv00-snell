#!/bin/bash

#================================================================
# Snell Server 管理脚本 (serv00专用版 V24)
#
# 更新日志 (V24):
# - 菜单文本优化: 在修改配置菜单中加入 port/psk 关键字。
#================================================================

# --- 全局变量定义 ---
SCRIPT_DIR="$HOME/app-data"
SCRIPT_PATH="$SCRIPT_DIR/app.sh"
SNELL_EXECUTABLE="$SCRIPT_DIR/bin/core-service"
SNELL_CONFIG="$SCRIPT_DIR/etc/app.json"
SNELL_LOG_FILE="$SCRIPT_DIR/service.log"
DOWNLOAD_URL="https://raw.githubusercontent.com/myouhi/app-data/master/core-service"

# --- 基础函数 ---
print_info() { echo -e "\033[32m[信息]\033[0m $1"; }
print_warning() { echo -e "\033[33m[警告]\033[0m $1"; }
print_error() { echo -e "\033[31m[错误]\033[0m $1"; }

# 检查 Snell 是否已安装
check_installation() {
    [ -f "$SNELL_EXECUTABLE" ]
}

# --- 核心功能函数 ---

# 获取 Snell 程序版本
get_snell_version() {
    if ! check_installation; then
        echo "未知"
        return
    fi
    local version_output
    version_output=$("$SNELL_EXECUTABLE" -v 2>&1)
    local version
    version=$(echo "$version_output" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "v3" 
    fi
}

# 检查当前运行状态并显示
check_running_status() {
    if pgrep -f "$SNELL_EXECUTABLE" > /dev/null; then
        echo -e "  运行状态: \033[1;32m● 运行中\033[0m"
    else
        echo -e "  运行状态: \033[1;31m● 已停止\033[0m"
    fi
}

# 启动 Snell 服务
start_snell() {
    if ! check_installation; then print_error "Snell 未安装，无法启动。"; return 1; fi
    if pgrep -f "$SNELL_EXECUTABLE" > /dev/null; then print_warning "Snell 服务已经在运行中。"; return; fi
    print_info "正在启动 Snell 服务..."
    nohup "$SNELL_EXECUTABLE" -c "$SNELL_CONFIG" > "$SNELL_LOG_FILE" 2>&1 &
    sleep 2
    if pgrep -f "$SNELL_EXECUTABLE" > /dev/null; then print_info "✅ 服务已成功启动！"; else print_error "❌ 服务启动失败！请检查日志或确认tls证书配置是否正确。"; fi
}

# 停止 Snell 服务
stop_snell() {
    if ! check_installation; then print_error "Snell 未安装，无法停止。"; return 1; fi
    print_info "正在停止 Snell 服务..."
    if pgrep -f "$SNELL_EXECUTABLE" > /dev/null; then
        killall snell-server &>/dev/null; sleep 1; print_info "✅ 服务已停止。"
    else
        print_warning "Snell 服务当前未在运行。"
    fi
}

# 重启 Snell 服务
restart_snell() {
    if ! check_installation; then print_error "Snell 未安装，无法重启。"; return 1; fi
    stop_snell; start_snell
}

# 查看配置
display_config() {
    if ! check_installation; then print_error "Snell 未安装，无法查看配置。"; return 1; fi
    if ! [ -r "$SNELL_CONFIG" ]; then print_error "配置文件不存在: $SNELL_CONFIG"; return; fi
    clear
    print_info "以下是您的 Snell 配置文件 ($SNELL_CONFIG) 的原始内容："
    echo; echo "=================================================="
    cat "$SNELL_CONFIG"
    echo "=================================================="; echo
    print_info "您的 IP 地址是: $(curl -s icanhazip.com)"
    print_info "请根据以上信息在您的客户端中进行配置。"
}

# 设置开机自启
setup_autostart() {
    if ! check_installation; then print_error "Snell 未安装，无法设置自启。"; return 1; fi
    local cron_command="@reboot nohup $SNELL_EXECUTABLE -c $SNELL_CONFIG > $SNELL_LOG_FILE 2>&1 &"
    (crontab -l 2>/dev/null | grep -Fv "snell-server"; echo "$cron_command") | crontab -
    print_info "✅ 开机自启设置/更新成功！"
}

# 安装 Snell 服务
run_installation() {
    clear
    if check_installation; then
        print_warning "检测到已安装Snell，继续操作将覆盖现有配置！"
        read -p "是否继续? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then print_info "操作已取消。"; return; fi
    fi

    echo "========================================"
    echo "      Snell Server 安装程序 (Serv00)"
    echo "========================================"; echo
    
    print_warning "请确保您已在 Serv00 面板的 'Porty' 中获取了端口。"
    while true; do
        read -p "请输入 Serv00 为您分配的端口号: " LISTEN_PORT
        if [[ "$LISTEN_PORT" =~ ^[0-9]+$ ]] && [ "$LISTEN_PORT" -gt 1024 ]; then break; else print_warning "输入无效！"; fi
    done

    print_info "请选择流量混淆模式 (obfs):"
    echo "  1. none (默认, 无混淆)"
    echo "  2. http (简单兼容)"
    echo "  3. tls (更安全, 但需要您手动提供证书)"
    local obfs_choice
    while true; do
        read -p "请输入选项 [1-3, 默认为 1]: " obfs_choice
        obfs_choice=${obfs_choice:-1}
        if [[ "$obfs_choice" =~ ^[1-3]$ ]]; then break; else print_warning "输入无效!"; fi
    done

    local obfs_mode_text="none"
    if [ "$obfs_choice" -eq 2 ]; then
        obfs_mode_text="http"
    elif [ "$obfs_choice" -eq 3 ]; then
        obfs_mode_text="tls"
    fi

    print_info "好的，将使用端口:$LISTEN_PORT, 混淆模式:$obfs_mode_text"
    print_info "开始执行自动化安装..."
    PSK=$(openssl rand -base64 24)
    mkdir -p "$SCRIPT_DIR/bin" "$SCRIPT_DIR/etc"
    
    {
        echo "[snell-server]"
        echo "listen = 0.0.0.0:$LISTEN_PORT"
        echo "psk = $PSK"
        if [ "$obfs_choice" -eq 2 ]; then
            echo "obfs = http"
        elif [ "$obfs_choice" -eq 3 ]; then
            echo "obfs = tls"
            echo "tls-cert = /path/to/your/fullchain.pem"
            echo "tls-key = /path/to/your/private.key"
        fi
    } > "$SNELL_CONFIG"

    print_info "正在下载 Snell 程序..."
    curl -L -s "$DOWNLOAD_URL" -o "$SNELL_EXECUTABLE" && chmod +x "$SNELL_EXECUTABLE"
    print_info "配置完成，正在启动服务..."
    restart_snell
    display_config

    if [ "$obfs_choice" -eq 3 ]; then
        echo
        print_warning "############################################################"
        print_warning "# 重要提示: 您选择了 tls 混淆模式!                         #"
        print_warning "#                                                          #"
        print_warning "# 服务可能无法正常启动, 直到您手动编辑以下文件:              #"
        print_warning "#   $SNELL_CONFIG   #"
        print_warning "#                                                          #"
        print_warning "# 并将 tls-cert 和 tls-key 指向您真实的证书和私钥文件路径. #"
        print_warning "############################################################"
        echo
    fi

    read -p "您想设置开机自动启动吗? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then setup_autostart; fi
}

# 修改配置
run_modify_config() {
    if ! check_installation; then print_error "Snell 未安装，无法修改配置。"; return 1; fi
    if ! [ -w "$SNELL_CONFIG" ]; then print_error "错误：配置文件不可写！"; return 1; fi
    
    echo "您想修改什么？"
    echo "  1. 修改 port 端口号"
    echo "  2. 生成 psk 密码"
    echo "  3. 修改 obfs 混淆模式"
    echo "  0. 返回主菜单"
    read -p "请输入选项: " choice

    local temp_file="$SNELL_CONFIG.tmp"
    local success=false
    local show_tls_warning=false

    case "$choice" in
        1)
            print_warning "修改端口前，请确保新端口已经在 Serv00 后台为您分配！"
            while true; do read -p "请输入新端口号: " NEW_PORT; if [[ "$NEW_PORT" =~ ^[0-9]+$ ]] && [ "$NEW_PORT" -gt 1024 ]; then break; else print_warning "输入无效！"; fi; done
            local current_ip; current_ip=$(grep "^listen =" "$SNELL_CONFIG" | cut -d'=' -f2 | cut -d':' -f1 | xargs)
            sed "s|^listen = .*|listen = $current_ip:$NEW_PORT|" "$SNELL_CONFIG" > "$temp_file" && success=true
            ;;
        2)
            NEW_PSK=$(openssl rand -base64 24)
            sed "s|^psk = .*|psk = $NEW_PSK|" "$SNELL_CONFIG" > "$temp_file" && success=true
            ;;
        3)
            print_info "请选择新的流量混淆模式 (obfs):"
            echo "  1. none (默认, 无混淆)"
            echo "  2. http (简单兼容)"
            echo "  3. tls (更安全, 但需要您手动提供证书)"
            local obfs_choice
            while true; do
                read -p "请输入选项 [1-3, 默认为 1]: " obfs_choice
                obfs_choice=${obfs_choice:-1}
                if [[ "$obfs_choice" =~ ^[1-3]$ ]]; then break; else print_warning "输入无效!"; fi
            done

            sed '/^obfs =/d;/^tls-cert =/d;/^tls-key =/d' "$SNELL_CONFIG" > "$temp_file"

            if [ "$obfs_choice" -eq 2 ]; then
                echo "obfs = http" >> "$temp_file"
                print_info "obfs 模式已修改为 http。"
            elif [ "$obfs_choice" -eq 3 ]; then
                echo "obfs = tls" >> "$temp_file"
                echo "tls-cert = /path/to/your/fullchain.pem" >> "$temp_file"
                echo "tls-key = /path/to/your/private.key" >> "$temp_file"
                show_tls_warning=true
                print_info "obfs 模式已修改为 tls。"
            else
                print_info "obfs 模式已修改为 none (无混淆)。"
            fi
            mv "$temp_file" "$SNELL_CONFIG"
            success=true
            ;;
        0)
            return
            ;;
        *) 
            print_warning "无效选择。"; return
            ;;
    esac

    if [ "$success" = true ]; then
        print_info "配置已修改，正在重启服务以应用新配置..."
        restart_snell
        
        if [ "$show_tls_warning" = true ]; then
            echo
            print_warning "############################################################"
            print_warning "# 重要提示: 您选择了 tls 混淆模式!                         #"
            print_warning "#                                                          #"
            print_warning "# 服务可能无法正常启动, 直到您手动编辑以下文件:              #"
            print_warning "#   $SNELL_CONFIG   #"
            print_warning "#                                                          #"
            print_warning "# 并将 tls-cert 和 tls-key 指向您真实的证书和私钥文件路径. #"
            print_warning "############################################################"
            echo
        fi

        read -n 1 -s -r -p "按任意键查看更新后的配置..."
        display_config
    else 
        print_error "配置修改失败！"
        [ -f "$temp_file" ] && rm "$temp_file"
    fi
}


# 卸载服务
run_uninstall() {
    if ! check_installation; then print_error "Snell 未安装，无需卸载。"; return 1; fi
    read -p "这将彻底删除 Snell 所有文件和配置，确定吗? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then print_info "操作已取消。"; return; fi
    stop_snell
    crontab -l 2>/dev/null | grep -v "snell-server" | crontab -
    rm -rf "$SCRIPT_DIR"
    print_info "✅ Snell 已被成功卸载。"
}

# --- 静态菜单逻辑 ---
show_main_menu() {
    while true; do
        clear
        echo "========================================"
        echo "             Snell 管理工具"
        echo "----------------------------------------"

        if check_installation; then
            local version; version=$(get_snell_version)
            echo -e "  安装状态: \033[1;32m● 已安装 (版本: $version)\033[0m"
            check_running_status
        else
            echo -e "  安装状态: \033[1;31m● 未安装\033[0m"
            echo -e "  运行状态: \033[1;31m● 已停止\033[0m"
        fi
        echo "========================================"; echo

        echo "  1. 安装服务"
        echo "  2. 启动服务"
        echo "  3. 停止服务"
        echo "  4. 重启服务"
        echo "  5. 查看配置"
        echo "  6. 修改配置"
        echo "  7. 开机自启"
        echo "  8. 卸载服务"
        echo
        echo "  0. 退出脚本"
        echo

        read -p "请输入选项: " choice
        case "$choice" in
            1) run_installation ;;
            2) start_snell ;;
            3) stop_snell ;;
            4) restart_snell ;;
            5) display_config ;;
            6) run_modify_config ;;
            7) setup_autostart ;;
            8) run_uninstall ;;
            0) echo "正在退出。"; exit 0 ;;
            *) print_warning "无效输入。" ;;
        esac

        echo
        read -n 1 -s -r -p "按任意键返回主菜单..."
    done
}


# --- 脚本主入口 ---

# 自我保存
if [ ! -f "$SCRIPT_PATH" ] && [ "$(basename "$0")" = "bash" ]; then
    print_info "首次运行，正在将脚本自身保存到 $SCRIPT_PATH ..."
    mkdir -p "$SCRIPT_DIR"; cat > "$SCRIPT_PATH"; chmod +x "$SCRIPT_PATH"
    print_info "保存成功。正在从本地文件重新启动脚本..."; echo "----------------------------------------------------"
    exec "$SCRIPT_PATH" "$@"
fi

# 依赖检查
if ! command -v curl &> /dev/null || ! command -v openssl &> /dev/null || ! command -v sed &> /dev/null || ! command -v strings &> /dev/null; then
    print_error "错误：本脚本需要 'curl', 'openssl', 'sed', 'strings'，请先确保它们已安装。"
    exit 1
fi

# 始终只显示菜单
show_main_menu
