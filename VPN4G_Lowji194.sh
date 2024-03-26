#!/bin/bash

# Định nghĩa các màu cho in ra
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Kiểm tra xem người dùng có phải là root hay không
if [[ $EUID -ne 0 ]]; then
    echo -e "${red}Nhận dạng:${plain} Tập lệnh này phải được chạy với quyền root!\n" 
    exit 1
fi

# Kiểm tra phiên bản và hệ điều hành
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    release=$ID
    os_version=$VERSION_ID
else
    echo -e "${red}Phiên bản hệ thống không được phát hiện. Liên hệ với tác giả kịch bản!${plain}\n" 
    exit 1
fi

# Kiểm tra kiến trúc hệ thống
arch=$(arch)
case $arch in
    x86_64|x64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) echo -e "${yellow}Không phát hiện được kiến trúc, sử dụng mặc định: ${arch}${plain}" ;;
esac

# In ra thông tin kiến trúc
echo "Ngành kiến trúc: ${arch}"

# Kiểm tra hệ thống có hỗ trợ 64-bit hay không
if [[ $(getconf WORD_BIT) != '32' ]] && [[ $(getconf LONG_BIT) != '64' ]]; then
    echo "Phần mềm này không hỗ trợ hệ thống 32-bit (x86), vui lòng sử dụng hệ thống 64-bit (x86_64), liên hệ với tác giả nếu cần trợ giúp."
    exit -1
fi

# Kiểm tra và cài đặt các gói cơ bản
install_base() {
    if [[ $release == "centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

# Cài đặt x-ui
install_x-ui() {
    systemctl stop firewalld ufw
    systemctl disable firewalld ufw
    systemctl stop x-ui
    cd /usr/local/
	
    wget -N --no-check-certificate -O /usr/local/x-ui-linux.tar.gz "https://github.com/Nolimit-key/x-ui/releases/download/0.1-beta/x-ui-linux.tar.gz"

    if [[ -d /usr/local/x-ui/ ]]; then
        rm -rf /usr/local/x-ui/
    fi

    tar zxvf x-ui-linux.tar.gz
    rm -f x-ui-linux.tar.gz
    cd x-ui
    chmod +x bin/xray-linux-"$arch"
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui
    cp -f /usr/local/x-ui/x-ui.service /etc/systemd/system/
    cp -f /usr/local/x-ui/x-ui.sh /usr/bin/x-ui
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
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
    echo -e "               [\033[1;36m•\033[1;31m] \033[1;37m\033[1;33mĐã cài đặt xong x-ui version ${last_version}${plain}\033[1;31m
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
