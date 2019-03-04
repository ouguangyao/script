#!/bin/bash
#instal nginx1.15.5
#auth:ogy
#自动安装: wget -q -O - https://raw.githubusercontent.com/ouguangyao/script/master/shell/Nginx1.15.5.Centos7.sh | bash

#chcek status
function check ()
{
   if [ $? -eq 0 ];then
       echo ''
   else
       exit 1
   fi
}


# Check if user is root
if [ $(id -u) != "0" ];then
    echo "Error,You must be root to run this script,please use root to install nginx"
	exit 1
fi

#安装组件
yum -y install gcc gcc-c++ autoconf automake libtool make cmake wget net-tools
yum -y install zlib zlib-devel openssl openssl-devel pcre-devel


#程序包下载所在目录
down_dir=/data/down

#程序安装所在目录
nginx_dir=/usr/local/nginx

#检查删除原来的nginx
rpm -qa | grep nginx
rpm -e nginx

#创建程序包下载目录
if [ ! -d $down_dir ];then
     mkdir $down_dir
fi

#下载程序包
cd $down_dir
wget http://nginx.org/download/nginx-1.15.5.tar.gz

#添加程序运行用户
groupadd www
useradd -s /sbin/nologin -g www www

#源码编译
tar -zxvf nginx-1.15.5.tar.gz
cd  nginx-1.15.5
./configure --user=www --group=www --prefix=$nginx_dir --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module
check

make && make install

#环境变量
ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

#拷贝主配置文件
mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.$(date +%F)
wget https://raw.githubusercontent.com/ouguangyao/script/master/AppConf/nginx.conf -O /usr/local/nginx/conf/nginx.conf
wget https://raw.githubusercontent.com/ouguangyao/script/master/AppConf/nginx -O /etc/init.d/nginx 

#添加到系统服务开机自启
chmod +x /etc/init.d/nginx
chkconfig nginx on

#创建日志、虚拟机目录
mkdir /data/logs/nginx -p
mkdir /usr/local/nginx/conf/vhost

echo "\n========Nginx 安装完成========"
echo "安装目录: $nginx_dir"
echo "虚拟主机目录：/usr/local/nginx/conf/vhost"
echo "日志存放目录：/data/logs/nginx"
echo "================================"

#启动服务
/etc/init.d/nginx start

#查看nginx版本
/usr/local/nginx/sbin/nginx -v
