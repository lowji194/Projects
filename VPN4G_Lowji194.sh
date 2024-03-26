#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Nhận dạng：${plain} Tập lệnh này phải được chạy với tư cách người dùng gốc！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Phiên bản hệ thống không được phát hiện, vui lòng liên hệ với tác giả kịch bản！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
else
  arch="amd64"
  echo -e "${red}Không phát hiện được kiến ​​trúc, hãy sử dụng kiến ​​trúc mặc định: ${arch}${plain}"
fi

echo "Ngành kiến ​​trúc: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ] ; then
    echo "Phần mềm này không hỗ trợ hệ thống 32-bit (x86), vui lòng sử dụng hệ thống 64-bit (x86_64), nếu phát hiện sai, vui lòng liên hệ với tác giả"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui lòng sử dụng CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_x-ui() {
    systemctl stop firewalld
    systemctl stop ufw
    systemctl disable firewalld
    systemctl disable ufw    
    systemctl stop x-ui
    cd /usr/local/

    wget -N --no-check-certificate -O /usr/local/x-ui-linux.tar.gz https://github.com/Nolimit-key/x-ui/releases/download/0.1-beta/x-ui-linux.tar.gz


    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux.tar.gz
    rm x-ui-linux.tar.gz -f
    cd x-ui
    chmod +x bin/xray-linux-amd64
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui
    cp -f /usr/local/x-ui/x-ui.service /etc/systemd/system/
    cp -f /usr/local/x-ui/x-ui.sh /usr/bin/x-ui
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    clear
}
# Thêm vào tệp rc.local để khởi động x-ui tự động
startup_rclocal() {
    command_line='# Kiểm tra trạng thái của dịch vụ x-ui\nstatus=$(systemctl is-active x-ui)\n\n# Nếu dịch vụ không hoạt động, thực hiện bật nó\nif [ "$status" != "active" ]; then\n    systemctl enable x-ui\n    systemctl start x-ui\nfi'

    if [ -f /etc/rc.local ]; then
        grep -qF "status=\$(systemctl is-active x-ui)" /etc/rc.local
        if [ $? -ne 0 ]; then
            sudo sed -i "\$a$command_line" /etc/rc.local
        fi
    fi
}
logsuccess() {
clear
    echo -e "               [\033[1;36m•\033[1;31m] \033[1;37m\033[1;33mĐã cài đặt xong VPN4G_Lợi Nguyễn${plain}\033[1;31m
               [\033[1;36m•\033[1;31m] \033[1;37m\033[1;33mTruy cập địa chỉ: ${green}`hostname -I | cut -d' ' -f1`:54321${plain}\033[1;31m
               [\033[1;36m•\033[1;31m] \033[1;37m\033[1;33mTên tài khoản và mật khẩu  mặc định là ${green}admin${plain} \033[1;31m
               [\033[1;36m•\033[1;31m] \033[1;37m\033[1;33mBấm lệnh x-ui để hiện menu \033[1;31m"
}
clear
echo -e "${green}Bắt đầu cài đặt${plain}"
sleep 4

# Thực thi các hàm
install_base
install_x-ui $1
startup_rclocal
logsuccess
