#!/usr/bin/env bash
#=================================================
#	System Required: Debian/Ubuntu
#	Description: Install Nginx with Rtmp module
#	Version: Test v0.1
#	Author: APTX
#=================================================
sh_ver="0.1"
nginx_ver="1.18.0"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif grep -q -E -i "debian" /etc/issue; then
    release="debian"
  elif grep -q -E -i "ubuntu" /etc/issue; then
    release="ubuntu"
  elif grep -q -E -i "centos|red hat|redhat" /etc/issue; then
    release="centos"
  elif grep -q -E -i "debian" /proc/version; then
    release="debian"
  elif grep -q -E -i "ubuntu" /proc/version; then
    release="ubuntu"
  elif grep -q -E -i "centos|red hat|redhat" /proc/version; then
    release="centos"
  fi
  bit=$(uname -m)
}
install_nginx() {
  cd /tmp || mkdir /tmp
  apt update && apt install wget curl build-essential git -y
  wget "http://nginx.org/download/nginx-${nginx_ver}.tar.gz" -O "nginx.tar.gz"
  tar -xzf nginx.tar.gz
  cd nginx-${nginx_ver}/ || exit 1
  git clone https://github.com/winshining/nginx-http-flv-module.git
  apt build-dep nginx -y
  ./configure --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-file-aio --with-http_realip_module --add-module=./nginx-http-flv-module
  make && make install
  ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
  cat >"/lib/systemd/system/nginx.service" <<-EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
}
config_nginx() {
  mkdir -p /data/wwwroot/default
  mkdir -p /data/wwwroot/public
  mkdir -p /data/wwwroot/wwwlogs
  cp /usr/local/nginx/html/* /data/wwwroot/default
  mkdir /usr/local/nginx/vhost
  mkdir /usr/local/nginx/ssl
  wget https://raw.githubusercontent.com/CokeMine/Nginx_rtmp_live/main/config/nginx.conf -O /usr/local/nginx/nginx.conf
  wget https://raw.githubusercontent.com/CokeMine/Nginx_rtmp_live/main/config/rtmp.conf -O /usr/local/nginx/rtmp.conf
  wget https://raw.githubusercontent.com/CokeMine/Nginx_rtmp_live/main/config/hls.conf -O /usr/local/nginx/vhost/hls.conf
  wget https://raw.githubusercontent.com/CokeMine/Nginx_rtmp_live/main/public/index.html -P /data/wwwroot/public
  systemctl restart nginx.service
  systemctl daemon-reload
  systemctl start nginx.service
  systemctl enable nginx.service
}

main() {
  echo -e "安装Nginx以及RTMP模块脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}"
  check_sys
  if [[ ${release} == "centos" ]]; then
    echo -e "本脚本只支援Debian/Ubuntu系统!"
    exit 1
  fi
  install_nginx
  if ! nginx -V >/dev/null 2>&1; then
    echo -e "Nginx 安装失败！"
  fi
  config_nginx
  read -rp "Nginx配置完成，请输入你的域名:" domain
  sed -e "s/live.com/${domain}/g" /usr/local/nginx/vhost/hls.conf
  systemctl restart nginx.service
}
main
