#!/bin/sh

# 設定資料目錄
MYSQL_DATA_DIR=/var/lib/mysql

# 確保 socket 目錄存在並有正確權限
echo "建立並檢查 socket 目錄..."
mkdir -p /run/mysqld
chown root:root /run/mysqld
chmod 755 /run/mysqld
ls -ld /run/mysqld  # 確認目錄狀態

# 如果資料目錄沒初始化，重新初始化
if [ ! -d "$MYSQL_DATA_DIR/mysql" ]; then
    echo "初始化資料庫..."
    mariadb-install-db --user=root --datadir=$MYSQL_DATA_DIR || { echo "初始化失敗"; exit 1; }
fi

# 檢查是否有定義 MYSQL_ROOT_PASSWORD
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "錯誤：請使用 -e MYSQL_ROOT_PASSWORD 指定 root 密碼"
    exit 1
fi

# 啟動 MariaDB 服務，避免背景運行
echo "啟動 MariaDB..."
mysqld --user=root --datadir=$MYSQL_DATA_DIR --socket=/run/mysqld/mysqld.sock &
MYSQL_PID=$!

# 等待服務啟動並檢查
for i in $(seq 1 15); do
    if mariadb -u root -e "SELECT 1" 2>/dev/null; then
        echo "MariaDB 已啟動"
        break
    fi
    if ! kill -0 $MYSQL_PID 2>/dev/null; then
        echo "MariaDB 啟動失敗，檢查日誌..."
        cat /var/lib/mysql/*.err 2>/dev/null
        exit 1
    fi
    echo "等待 MariaDB 啟動... ($i/15)"
    sleep 1
done

# 檢查是否第一次運行，設定 root 密碼
if [ ! -f "$MYSQL_DATA_DIR/.initialized" ]; then
    echo "設定 root 帳號..."
    mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" || { echo "設定密碼失敗"; exit 1; }
    # 匯入 database_backup.sql
    echo "匯入 database_backup.sql..."
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" < /database_backup.sql || { echo "匯入 SQL 檔案失敗"; exit 1; }
    touch "$MYSQL_DATA_DIR/.initialized"
fi

# 保持容器運行
echo "MariaDB 運行中..."
tail -f /dev/null
