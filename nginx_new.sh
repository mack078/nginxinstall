#!/bin/bash



# 获取 Nginx 最新版本
latest_version=nginx-1.26.0.tar.gz

# 下载最新的 Nginx
wget -q http://nginx.org/download/nginx-${latest_version}.tar.gz
wget -q https://github.com/maxmind/libmaxminddb/releases/download/1.3.2/libmaxminddb-1.3.2.tar.gz

# 解压 tar 文件
tar -zxf nginx-${latest_version}.tar.gz
tar -xf libmaxminddb-1.3.2.tar.gz

# 安装 libmaxminddb
pushd libmaxminddb-1.3.2
./configure
make
make install
echo "/usr/local/lib" | tee -a /etc/ld.so.conf.d/local.conf
popd

# 克隆 ngx_http_geoip2_module
git clone https://github.com/leev/ngx_http_geoip2_module.git /usr/local/src/ngx_http_geoip2_module

# 配置 Nginx
mkdir -p /usr/local/Geoip2/
pushd nginx-${latest_version}
./configure \
  --prefix=/usr/local/nginx \
  --with-http_ssl_module \
  --with-http_realip_module \
  --with-http_stub_status_module \
  --with-stream \
  --add-module=/usr/local/src/ngx_http_geoip2_module/
make
make install
popd

# 复制配置文件
git clone https://github.com/mack078/nginx.conf.git
mv nginx.conf/nginx.conf /usr/local/nginx/conf/
mv nginx.conf/Geo* /usr/local/Geoip2/

# 禁用 SELinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux

# 创建目录
mkdir -p /usr/local/nginx/ssl
mkdir -p /usr/local/nginx/vhosts

# 配置防火墙
systemctl restart firewalld
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --add-rich-rule="rule family='ipv4' source address='61.219.218.0/24' service name='ssh' accept" --permanent

# 创建软链接
ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx

# 更新动态链接库缓存
/sbin/ldconfig
