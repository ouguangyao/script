#!/bin/bash
# install.MySQL5.7.Centos7.sh
# MySQL 5.7.26 安装脚本
# 自动安装: wget -q -O - https://raw.githubusercontent.com/ouguangyao/script/master/shell/install.MySQL5.7.Centos7.sh | bash


# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install MySQL"
    exit 1
fi


# 目录-程序包下载
down_dir=/data/down

# 目录-程序安装
mysql_dir=/usr/local/mysql

# 目录-数据存储
mysql_data=/data/mysql/data

# 数据库root用户密码
mysqlrootpwd=123456

# 检查删除原来的MySQL
rpm -qa|grep mysql
rpm -e mysql
yum -y remove mysql-server mysql mysql-libs

# 创建目录
mkdir -p $down_dir
mkdir -p $mysql_data


# 添加程序运行用户
groupadd mysql
useradd -s /sbin/nologin -M -g mysql mysql

# 组件
yum -y install ncurses-devel bison openssl openssl-devel 
yum -y install gcc-c++ libstdc++-devel cmake autoconf

cd $down_dir
wget https://sourceforge.net/projects/boost/files/boost/1.67.0/boost_1_67_0.tar.gz
tar zxvf boost_1_67_0.tar.gz
mv boost_1_67_0 /usr/local/boost

# 下载
cd $down_dir
wget https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.26.tar.gz

# 源码安装
tar zxvf mysql-5.7.26.tar.gz
cd mysql-5.7.26


# -----------------------------
# https://dev.mysql.com/doc/refman/5.7/en/source-configuration-options.html
#DCMAKE_INSTALL_PREFIX=/usr/local/mysql #安装路径
#DMYSQL_DATADIR=/data/mysql             #数据文件存放位置
#DSYSCONFDIR=/etc                       #my.cnf路径
#DWITH_MYISAM_STORAGE_ENGINE=1          #支持MyIASM引擎
#DWITH_INNOBASE_STORAGE_ENGINE=1        #支持InnoDB引擎
#DMYSQL_UNIX_ADDR=/var/run/mysql.sock   #连接数据库socket路径
#DMYSQL_TCP_PORT=3306                   #端口
#DENABLED_LOCAL_INFILE=1                #允许从本地导入数据
#DWITH_PARTITION_STORAGE_ENGINE=1       #安装支持数据库分区
#DEXTRA_CHARSETS=all                    #安装所有的字符集
#DDEFAULT_CHARSET=utf8                  #默认字符
#DWITH_EMBEDDED_SERVER=1                #嵌入式服务器
# ------------------------------------------------
cmake \
-DCMAKE_INSTALL_PREFIX=$mysql_dir \
-DMYSQL_DATADIR=$mysql_data \
-DSYSCONFDIR=/etc \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DMYSQL_USER=mysql \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DDOWNLOAD_BOOST=1 \
-DWITH_BOOST=/usr/local/boost


make && make install



#配置文件
cat > /etc/my.cnf << EOF
[mysqld]
port = 3306
user = mysql
basedir = /usr/local/mysql
datadir = /data/mysql/data
socket = /tmp/mysql.sock
lower_case_table_names=1
EOF



# 初始化数据库 (mysql_install_db被废弃了，取而代之的是mysqld –initialize)
# --initialize-insecure #创建空密码的root@localhost账号
$mysql_dir/bin/mysqld --defaults-file=/etc/my.cnf --initialize-insecure --datadir=$mysql_data --basedir=$mysql_dir --user=mysql 



# 服务启动脚本 
cp $mysql_dir/support-files/mysql.server /etc/init.d/mysqld
chmod 755 /etc/init.d/mysqld



# 添加到系统服务并开机自启
chkconfig --add mysqld
chkconfig --level 345 mysqld on


# 启动服务
/etc/init.d/mysqld start


# 环境变量
ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe

# 设置数据库root用户密码
/usr/local/mysql/bin/mysqladmin -u root password $mysqlrootpwd


echo "\n======== MySQL 安装完成  ==================="
echo "安装目录: $mysql_dir"
echo "数据目录: $mysql_data"
echo "root密码: $mysqlrootpwd"
echo "============================================="
