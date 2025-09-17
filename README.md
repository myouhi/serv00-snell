# Snell-server (serv00专用版V3版本 ）V4和v5不能使用
在 Serv00 平台，您需要先手动获取一个端口。
请按照以下步骤操作：
1. 在浏览器中打开并登录您的 Serv00 控制面板。
2. 在左侧菜单中找到 'Porty' (Ports) 选项并点击进入。
3. 点击 'Add port' 按钮，创建tcp端口号。
4. 运行脚本

bash <(curl -sSL https://raw.githubusercontent.com/myouhi/serv00-snell/refs/heads/master/snell.sh)

# 管理脚本快捷命令

1. 下载脚本到正确的位置

curl -o ~/snell/snell.sh https://raw.githubusercontent.com/myouhi/serv00-snell/master/snell.sh

2. 给脚本加上执行权限：chmod +x ~/snell/snell.sh

3. 测试：运行 source ~/.bashrc ，然后再次尝试 snell 命令。



