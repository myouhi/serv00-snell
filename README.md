# Snell-server (serv00专用版）
在 Serv00 平台，您需要先手动获取一个端口。
请按照以下步骤操作：
1. 在浏览器中打开并登录您的 Serv00 控制面板。
2. 在左侧菜单中找到 'Porty' (Ports) 选项并点击进入。
3. 点击 'Add port' 按钮，创建tcp端口号。

运行脚本

bash <(curl -sSL https://raw.githubusercontent.com/myouhi/serv00-snell/refs/heads/master/snell.sh)

管理脚本快捷命令

第一步：下载脚本到正确的位置
这条命令会从您的 GitHub 仓库下载脚本，并直接保存为 /home/kimoo/snell/snell.sh。
curl -o ~/snell/snell.sh https://raw.githubusercontent.com/myouhi/serv00-snell/master/snell.sh
(注意：我使用了您之前提供的 GitHub 链接，并确保脚本文件名是 snell.sh)

第二步：给脚本加上执行权限
chmod +x ~/snell/snell.sh
最后一步：测试
现在，快捷方式指向的文件已经被我们恢复了。
请您关闭当前的终端窗口，然后重新打开一个（或者运行 source ~/.bashrc），然后再次尝试 snell 命令。
snell
这次应该就万无一失了。这个问题的根本原因就是主脚本文件丢失了。


