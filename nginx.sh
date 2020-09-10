#!/bin/bash
sudo yum install -y gcc gcc-c++ make libtool zlib zlib-devel pcre pcre-devel openssl openssl-devel wget vim unzip git lrzsz
sudo wget http://nginx.org/download/nginx-1.17.3.tar.gz
sudo wget https://github.com/maxmind/libmaxminddb/releases/download/1.3.2/libmaxminddb-1.3.2.tar.gz
sudo tar -zxvf nginx-1.17.3.tar.gz
sudo tar -xvf libmaxminddb-1.3.2.tar.gz
sudo cd /libmaxminddb-1.3.2
sudo ./configure
sudo make    
sudo make install 
sudo ldconfig
sudo sh -c "echo /usr/local/lib  >> /etc/ld.so.conf.d/local.conf"
sudo cd /
sudo git clone https://github.com/mack078/ngx_http_geoip2_module
sudo mv ngx_http_geoip2_module /usr/local/src/
sudo cd /
sudo cd /nginx-1.17.3
sudo ./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_realip_module  --with-http_stub_status_module  --add-module=/usr/local/src/ngx_http_geoip2_module/
sudo make
sudo make install
echo "worker_processes  auto;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  logs/access.log  main;

    sendfile        on;
    tcp_nopush     on;

    keepalive_timeout  65;

    gzip  on;
   	geoip2 /usr/local/Geoip2/GeoLite2-Country.mmdb {
    auto_reload 60m;
    $geoip2_metadata_country_build metadata build_epoch;
    $geoip2_data_country_code country iso_code;
    $geoip2_data_country_name country names en;
    }

    geoip2 /usr/local/Geoip2/GeoLite2-City.mmdb {
    auto_reload 60m;
    $geoip2_metadata_city_build metadata build_epoch;
    $geoip2_data_city_name city names en;
    }

    geo $remote_addr  $ip_whitelist {
     default 0;
     1.1.1.1  1;
    }
    map $geoip2_data_country_code $allowed_country {
    default yes;
    PH no;
    TW no;
    }
    include /usr/local/nginx/vhosts/*.conf;
}"  > /usr/local/nginx/conf/nginx.conf
sudo cd /
wget https://github.com/mack078/nginx.conf/blob/master/GeoLite2-City.mmdb
wget https://github.com/mack078/nginx.conf/blob/master/GeoLite2-Country.mmdb
sudo mkdir /usr/local/Geoip2/
sudo mv Geo* /usr/local/Geoip2/
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux && cat /etc/sysconfig/selinux
sudo mkdir /usr/local/nginx/ssl
sudo mkdir /usr/local/nginx/vhosts
sudo chkconfig /usr/local/nginx/sbin/nginx
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --add-rich-rule="rule family="ipv4" source address="61.220.250.0/24" service name="ssh" accept" --permanent
sudo systemctl restart firewalld
sudo ln /usr/local/nginx/sbin/nginx /usr/local/bin/nginx

