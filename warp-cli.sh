#!/bin/bash
#MmD
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
GOLD=$(tput setaf 3)
CYAN=$(tput setaf 6)
NC=$(tput sgr0)

root_check() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as ${RED}root!${NC}"
    exit 1
  fi
}

check_host() {
    if command -v apt &> /dev/null; then
        apt_based
    elif command -v yum &> /dev/null; then
        yum_based
    else
        echo "${RED}Package manager not supported${NC}"
    fi
}

apt_based() {
    apt update
    apt install -y curl gpg lsb-release apt-transport-https ca-certificates sudo
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
    apt update
    apt -y install cloudflare-warp
}

yum_based() {
    curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo
    yum check-update
    yum install -y curl sudo coreutils
    yum check-update
    yum install -y cloudflare-warp
}

warp_setup() {
    if command -v warp-cli &> /dev/null; then
        echo "${GREEN}WARP-CLI installed successfully!${NC}"
        yes | warp-cli registration new
        warp-cli mode proxy
        warp-cli proxy port 10808
        warp-cli connect
        echo ""
        echo "${CYAN}WARP is ready! ${GOLD}SOCKS5 port: 10808${NC}"
        echo ""
    else
        echo "${RED}WARP-CLI not installed!${NC}"
        exit
    fi
}

root_check
if command -v warp-cli &> /dev/null && warp-cli --version &> /dev/null; then
    echo "${CYAN}WARP-CLI is already installed!${NC}"
else
    check_host
    warp_setup
    exit
fi
