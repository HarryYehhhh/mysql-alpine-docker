# 使用官方的 Alpine Linux 作為基礎映像
FROM alpine:latest

# 安裝 MySQL 8 (MariaDB 是 Alpine 上輕量的 MySQL 相容選項)
RUN apk update && apk add --no-cache mariadb mariadb-client

# 設定 MySQL 的資料目錄
ENV MYSQL_DATA_DIR=/var/lib/mysql
ENV MYSQL_SCHEMA_DIR=/schema-data

# 建立 volume 目錄來儲存 schema data
RUN mkdir -p $MYSQL_SCHEMA_DIR

# 初始化 MySQL 資料庫
RUN mysql_install_db --user=root --datadir=$MYSQL_DATA_DIR

# 複製啟動腳本
COPY start-mysql.sh /start-mysql.sh
RUN chmod +x /start-mysql.sh

# 設定 volume，讓外部可以掛載
VOLUME ["/schema-data"]

# 暴露 MySQL 的預設端口
EXPOSE 3306

# 啟動 MySQL 服務並設定帳號密碼
CMD ["/start-mysql.sh"]
