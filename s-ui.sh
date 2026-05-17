#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

function LOGD() {
    echo -e "${yellow}[DEBUG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERROR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INFO] $* ${plain}"
}

[[ $EUID -ne 0 ]] && LOGE "Error: Must run this script as root!\n" && exit 1

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to detect system, please contact the author!" >&2
    exit 1
fi

echo "Current system distribution is: $release"

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [Default $2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Restart ${1} service" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press Enter to return to main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/admin8800/s-ui/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "This function will force reinstall the latest version, data will not be lost. Continue?" "n"
    if [[ $? != 0 ]]; then
        LOGE "Cancelled"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/admin8800/s-ui/main/install.sh)
    if [[ $? == 0 ]]; then
        LOGI "Update complete, panel has been automatically restarted"
        exit 0
    fi
}

custom_version() {
    echo "Please enter panel version (e.g., v1.4.1):"
    read panel_version

    if [ -z "$panel_version" ]; then
        echo "Panel version cannot be empty. Exiting."
    exit 1
    fi

    [[ "${panel_version}" != v* ]] && panel_version="v${panel_version}"

    download_link="https://raw.githubusercontent.com/admin8800/s-ui/main/install.sh"

    install_command="bash <(curl -Ls $download_link) $panel_version"

    echo "Downloading and installing panel version $panel_version..."
    eval $install_command
}

uninstall() {
    confirm "Are you sure you want to uninstall the panel?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop s-ui
    systemctl disable s-ui
    rm /etc/systemd/system/s-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/s-ui/ -rf
    rm /usr/local/s-ui/ -rf

    echo ""
    echo -e "Uninstall successful. To remove this script, run ${green}rm /usr/local/s-ui -f${plain} after exiting."
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_admin() {
    echo "It is not recommended to set admin credentials to default values!"
    confirm "Are you sure you want to reset admin credentials to default?" "n"
    if [[ $? == 0 ]]; then
        /usr/local/s-ui/sui admin -reset
    fi
    before_show_menu
}

set_admin() {
    echo "It is not recommended to set admin credentials to overly complex text."
    read -p "Set username: " config_account
    read -p "Set password: " config_password
    /usr/local/s-ui/sui admin -username ${config_account} -password ${config_password}
    before_show_menu
}

view_admin() {
    /usr/local/s-ui/sui admin -show
    before_show_menu
}

reset_setting() {
    confirm "Are you sure you want to reset settings to default?" "n"
    if [[ $? == 0 ]]; then
        /usr/local/s-ui/sui setting -reset
    fi
    before_show_menu
}

set_setting() {
    echo -e "Please enter ${yellow}Panel Port${plain} (leave blank to use current/default):"
    read config_port
    echo -e "Please enter ${yellow}Panel Path${plain} (leave blank to use current/default):"
    read config_path

    echo -e "Please enter ${yellow}Subscription Port${plain} (leave blank to use current/default):"
    read config_subPort
    echo -e "Please enter ${yellow}Subscription Path${plain} (leave blank to use current/default):"
    read config_subPath

    echo -e "${yellow}Initializing, please wait...${plain}"
    params=""
    [ -z "$config_port" ] || params="$params -port $config_port"
    [ -z "$config_path" ] || params="$params -path $config_path"
    [ -z "$config_subPort" ] || params="$params -subPort $config_subPort"
    [ -z "$config_subPath" ] || params="$params -subPath $config_subPath"
    /usr/local/s-ui/sui setting ${params}
    before_show_menu
}

view_setting() {
    /usr/local/s-ui/sui setting -show
    view_uri
    before_show_menu
}

view_uri() {
    info=$(/usr/local/s-ui/sui uri)
    if [[ $? != 0 ]]; then
        LOGE "Failed to get current URI"
        before_show_menu
    fi
    LOGI "You can access the panel via the following URL:"
    echo -e "${green}${info}${plain}"
}

start() {
    check_status $1
    if [[ $? == 0 ]]; then
        echo ""
        LOGI -e "${1} is running, no need to start again; if you need to restart, please choose restart"
    else
        systemctl start $1
        sleep 2
        check_status $1
        if [[ $? == 0 ]]; then
            LOGI "${1} started successfully"
        else
            LOGE "Failed to start ${1}, possibly took longer than 2 seconds, please check logs"
        fi
    fi

    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status $1
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "${1} is already stopped, no need to stop again!"
    else
        systemctl stop $1
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "${1} stopped successfully"
        else
            LOGE "Failed to stop ${1}, possibly took longer than 2 seconds, please check logs"
        fi
    fi

    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart $1
    sleep 2
    check_status $1
    if [[ $? == 0 ]]; then
        LOGI "${1} restarted successfully"
    else
        LOGE "Failed to restart ${1}, possibly took longer than 2 seconds, please check logs"
    fi
    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status s-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable $1
    if [[ $? == 0 ]]; then
        LOGI "Successfully set ${1} to start on boot"
    else
        LOGE "Failed to set ${1} to start on boot"
    fi

    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable $1
    if [[ $? == 0 ]]; then
        LOGI "Successfully disabled ${1} from starting on boot"
    else
        LOGE "Failed to disable ${1} from starting on boot"
    fi

    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u $1.service -e --no-pager -f
    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

update_shell() {
    wget -O /usr/bin/s-ui -N --no-check-certificate https://github.com/admin8800/s-ui/raw/main/s-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "Failed to download script, please check if machine can connect to Github"
        before_show_menu
    else
        chmod +x /usr/bin/s-ui
        LOGI "Script updated successfully, please run it again" && exit 0
    fi
}

check_status() {
    if [[ ! -f "/etc/systemd/system/$1.service" ]]; then
        return 2
    fi
    temp=$(systemctl status "$1" | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled $1)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status s-ui
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "Panel is already installed, do not reinstall"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status s-ui
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "Please install the panel first"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status $1
    case $? in
    0)
        echo -e "${1} Status: ${green}Running${plain}"
        show_enable_status $1
        ;;
    1)
        echo -e "${1} Status: ${yellow}Not Running${plain}"
        show_enable_status $1
        ;;
    2)
        echo -e "${1} Status: ${red}Not Installed${plain}"
        ;;
    esac
}

show_enable_status() {
    check_enabled $1
    if [[ $? == 0 ]]; then
        echo -e "${1} Start on Boot: ${green}Yes${plain}"
    else
        echo -e "${1} Start on Boot: ${red}No${plain}"
    fi
}

check_s-ui_status() {
    count=$(ps -ef | grep "sui" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_s-ui_status() {
    check_s-ui_status
    if [[ $? == 0 ]]; then
        echo -e "s-ui Status: ${green}Running${plain}"
    else
        echo -e "s-ui Status: ${red}Not Running${plain}"
    fi
}

bbr_menu() {
    echo -e "${green}\t1.${plain} Enable BBR"
    echo -e "${green}\t2.${plain} Disable BBR"
    echo -e "${green}\t0.${plain} Return to main menu"
    read -p "Please select an option: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        enable_bbr
        ;;
    2)
        disable_bbr
        ;;
    *) echo "Invalid selection" ;;
    esac
}

disable_bbr() {
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${yellow}BBR is not currently enabled.${plain}"
        exit 0
    fi
    sed -i 's/net.core.default_qdisc=fq/net.core.default_qdisc=pfifo_fast/' /etc/sysctl.conf
    sed -i 's/net.ipv4.tcp_congestion_control=bbr/net.ipv4.tcp_congestion_control=cubic/' /etc/sysctl.conf
    sysctl -p
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "cubic" ]]; then
        echo -e "${green}Successfully replaced BBR with CUBIC.${plain}"
    else
        echo -e "${red}Failed to replace BBR with CUBIC. Please check system config.${plain}"
    fi
}

enable_bbr() {
    if grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf && grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo -e "${green}BBR is already enabled!${plain}"
        exit 0
    fi
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -yqq --no-install-recommends ca-certificates
        ;;
    centos | almalinux | rocky | oracle)
        yum -y update && yum -y install ca-certificates
        ;;
    fedora)
        dnf -y update && dnf -y install ca-certificates
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm ca-certificates
        ;;
    *)
        echo -e "${red}Unsupported OS. Please check the script and manually install necessary packages.${plain}\n"
        exit 1
        ;;
    esac
    echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf
    sysctl -p
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "bbr" ]]; then
        echo -e "${green}BBR enabled successfully.${plain}"
    else
        echo -e "${red}Failed to enable BBR. Please check system config.${plain}"
    fi
}

install_acme() {
    cd ~
    LOGI "Installing acme..."
    curl https://get.acme.sh | sh
    if [ $? -ne 0 ]; then
        LOGE "Failed to install acme"
        return 1
    else
        LOGI "Acme installed successfully"
    fi
    return 0
}

ssl_cert_issue_main() {
    echo -e "${green}\t1.${plain} Get SSL"
    echo -e "${green}\t2.${plain} Revoke Certificate"
    echo -e "${green}\t3.${plain} Force Renewal"
    echo -e "${green}\t4.${plain} Self-signed Certificate"
    read -p "Please select an option: " choice
    case "$choice" in
        1) ssl_cert_issue ;;
        2)
            local domain=""
            read -p "Enter the domain to revoke certificate: " domain
            ~/.acme.sh/acme.sh --revoke -d ${domain}
            LOGI "Certificate revoked"
            ;;
        3)
            local domain=""
            read -p "Enter the domain to force renew SSL certificate: " domain
            ~/.acme.sh/acme.sh --renew -d ${domain} --force
            ;;
        4)
            generate_self_signed_cert
            ;;
        *) echo "Invalid selection" ;;
    esac
}

ssl_cert_issue() {
    if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
        echo "acme.sh not found, installing..."
        install_acme
        if [ $? -ne 0 ]; then
            LOGE "Failed to install acme, please check logs"
            exit 1
        fi
    fi
    case "${release}" in
    ubuntu | debian | armbian)
        apt update && apt install socat -y
        ;;
    centos | almalinux | rocky | oracle)
        yum -y update && yum -y install socat
        ;;
    fedora)
        dnf -y update && dnf -y install socat
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm socat
        ;;
    *)
        echo -e "${red}Unsupported OS. Please check script and manually install necessary packages.${plain}\n"
        exit 1
        ;;
    esac
    if [ $? -ne 0 ]; then
        LOGE "Failed to install socat, please check logs"
        exit 1
    else
        LOGI "Socat installed successfully..."
    fi

    local domain=""
    read -p "Please enter your domain: " domain
    LOGD "Your domain is: ${domain}, checking..."
    local currentCert=$(~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}')

    if [ ${currentCert} == ${domain} ]; then
        local certInfo=$(~/.acme.sh/acme.sh --list)
        LOGE "Certificate already exists in the system, cannot issue again. Current details:"
        LOGI "$certInfo"
        exit 1
    else
        LOGI "Your domain is ready for certificate issuance..."
    fi

    certPath="/root/cert/${domain}"
    if [ ! -d "$certPath" ]; then
        mkdir -p "$certPath"
    else
        rm -rf "$certPath"
        mkdir -p "$certPath"
    fi

    local WebPort=80
    read -p "Please select port, default is 80: " WebPort
    if [[ ${WebPort} -gt 65535 || ${WebPort} -lt 1 ]]; then
        LOGE "Invalid port ${WebPort}, using default port"
    fi
    LOGI "Using port ${WebPort} for certificate issuance, ensure it is open..."
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d ${domain} --standalone --httpport ${WebPort}
    if [ $? -ne 0 ]; then
        LOGE "Failed to issue certificate, please check logs"
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGE "Certificate issued successfully, installing..."
    fi
    ~/.acme.sh/acme.sh --installcert -d ${domain} \
        --key-file /root/cert/${domain}/privkey.pem \
        --fullchain-file /root/cert/${domain}/fullchain.pem

    if [ $? -ne 0 ]; then
        LOGE "Failed to install certificate, exiting"
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGI "Certificate installed successfully, enabling auto-renewal..."
    fi

    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    if [ $? -ne 0 ]; then
        LOGE "Auto-renewal setup failed, certificate details:"
        ls -lah cert/*
        chmod 755 $certPath/*
        exit 1
    else
        LOGI "Auto-renewal enabled successfully, certificate details:"
        ls -lah cert/*
        chmod 755 $certPath/*
    fi
}

ssl_cert_issue_CF() {
    echo -E ""
    LOGD "****** Instructions ******"
    echo "1) Apply for new certificate from Cloudflare"
    echo "2) Force renew existing certificate"
    echo "3) Return to menu"
    read -p "Please enter your choice [1-3]: " choice

    certPath="/root/cert-CF"

    case $choice in
        1|2)
            force_flag=""
            if [ "$choice" -eq 2 ]; then
                force_flag="--force"
                echo "Force re-issuing SSL certificate..."
            else
                echo "Starting SSL certificate issuance..."
            fi

            LOGD "****** Instructions ******"
            LOGI "This Acme script needs the following data:"
            LOGI "1. Cloudflare registration email"
            LOGI "2. Cloudflare Global API Key"
            LOGI "3. Domain with DNS already pointed to this server via Cloudflare"
            LOGI "4. Script will apply for certificate, default install path is /root/cert"
            confirm "Confirm? [y/n]" "y"
            if [ $? -eq 0 ]; then
                if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
                    echo "acme.sh not found. Installing..."
                    install_acme
                    if [ $? -ne 0 ]; then
                        LOGE "Failed to install acme, please check logs"
                        exit 1
                    fi
                fi

                CF_Domain=""
                if [ ! -d "$certPath" ]; then
                    mkdir -p $certPath
                else
                    rm -rf $certPath
                    mkdir -p $certPath
                fi

                LOGD "Set domain:"
                read -p "Enter domain here: " CF_Domain
                LOGD "Your domain is set to: ${CF_Domain}"

                CF_GlobalKey=""
                CF_AccountEmail=""
                LOGD "Set API key:"
                read -p "Enter key here: " CF_GlobalKey
                LOGD "Your API key is: ${CF_GlobalKey}"

                LOGD "Set registration email:"
                read -p "Enter email here: " CF_AccountEmail
                LOGD "Your registration email is: ${CF_AccountEmail}"

                ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
                if [ $? -ne 0 ]; then
                    LOGE "Failed to set default CA Let's Encrypt, exiting..."
                    exit 1
                fi

                export CF_Key="${CF_GlobalKey}"
                export CF_Email="${CF_AccountEmail}"

                ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} $force_flag --log
                if [ $? -ne 0 ]; then
                    LOGE "Certificate issuance failed, exiting..."
                    exit 1
                else
                    LOGI "Certificate issued successfully, installing..."
                fi

                mkdir -p ${certPath}/${CF_Domain}
                if [ $? -ne 0 ]; then
                    LOGE "Failed to create directory: ${certPath}/${CF_Domain}"
                    exit 1
                fi

                ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} \
                    --fullchain-file ${certPath}/${CF_Domain}/fullchain.pem \
                    --key-file ${certPath}/${CF_Domain}/privkey.pem

                if [ $? -ne 0 ]; then
                    LOGE "Certificate installation failed, exiting..."
                    exit 1
                else
                    LOGI "Certificate installed successfully, enabling auto-update..."
                fi

                ~/.acme.sh/acme.sh --upgrade --auto-upgrade
                if [ $? -ne 0 ]; then
                    LOGE "Auto-update setup failed, exiting..."
                    exit 1
                else
                    LOGI "Certificate installed and auto-renewal enabled."
                    ls -lah ${certPath}/${CF_Domain}
                    chmod 755 ${certPath}/${CF_Domain}
                fi
            fi
            show_menu
            ;;
        3)
            echo "Exiting..."
            show_menu
            ;;
        *)
            echo "Invalid choice, please select again."
            show_menu
            ;;
    esac
}

generate_self_signed_cert() {
    cert_dir="/etc/sing-box"
    mkdir -p "$cert_dir"
    LOGI "Please select certificate type:"
    echo -e "${green}\t1.${plain} Ed25519 (Recommended)"
    echo -e "${green}\t2.${plain} RSA 2048"
    echo -e "${green}\t3.${plain} RSA 4096"
    echo -e "${green}\t4.${plain} ECDSA prime256v1"
    echo -e "${green}\t5.${plain} ECDSA secp384r1"
    read -p "Please enter your choice [1-5, Default 1]: " cert_type
    cert_type=${cert_type:-1}

    case "$cert_type" in
        1)
            algo="ed25519"
            key_opt="-newkey ed25519"
            ;;
        2)
            algo="rsa"
            key_opt="-newkey rsa:2048"
            ;;
        3)
            algo="rsa"
            key_opt="-newkey rsa:4096"
            ;;
        4)
            algo="ecdsa"
            key_opt="-newkey ec -pkeyopt ec_paramgen_curve:prime256v1"
            ;;
        5)
            algo="ecdsa"
            key_opt="-newkey ec -pkeyopt ec_paramgen_curve:secp384r1"
            ;;
        *)
            algo="ed25519"
            key_opt="-newkey ed25519"
            ;;
    esac

    LOGI "Generating self-signed certificate ($algo)..."
    sudo openssl req -x509 -nodes -days 3650 $key_opt \
        -keyout "${cert_dir}/self.key" \
        -out "${cert_dir}/self.crt" \
        -subj "/CN=myserver"
    if [[ $? -eq 0 ]]; then
        sudo chmod 600 "${cert_dir}/self."*
        LOGI "Self-signed certificate generated successfully!"
        LOGI "Certificate path: ${cert_dir}/self.crt"
        LOGI "Key path: ${cert_dir}/self.key"
    else
        LOGE "Failed to generate self-signed certificate."
    fi
    before_show_menu
}

show_usage() {
    echo -e "S-UI Control Menu Usage"
    echo -e "------------------------------------------"
    echo -e "Subcommands:"
    echo -e "s-ui              - Admin management script"
    echo -e "s-ui start        - Start s-ui"
    echo -e "s-ui stop         - Stop s-ui"
    echo -e "s-ui restart      - Restart s-ui"
    echo -e "s-ui status       - View s-ui status"
    echo -e "s-ui enable       - Enable start on boot"
    echo -e "s-ui disable      - Disable start on boot"
    echo -e "s-ui log          - View s-ui logs"
    echo -e "s-ui update       - Update"
    echo -e "s-ui install      - Install"
    echo -e "s-ui uninstall    - Uninstall"
    echo -e "s-ui help         - Control menu usage"
    echo -e "------------------------------------------"
}

show_menu() {
  echo -e "
  ${green}S-UI Management Script ${plain}
---------------------------------------------------------------
  ${green}0.${plain} Exit
---------------------------------------------------------------
  ${green}1.${plain} Install
  ${green}2.${plain} Update
  ${green}3.${plain} Custom Version
  ${green}4.${plain} Uninstall
---------------------------------------------------------------
  ${green}5.${plain} Reset admin credentials to default
  ${green}6.${plain} Set admin credentials
  ${green}7.${plain} View admin credentials
---------------------------------------------------------------
  ${green}8.${plain} Reset panel settings
  ${green}9.${plain} Configure panel settings
  ${green}10.${plain} View panel settings
---------------------------------------------------------------
  ${green}11.${plain} Start S-UI
  ${green}12.${plain} Stop S-UI
  ${green}13.${plain} Restart S-UI
  ${green}14.${plain} View S-UI Status
  ${green}15.${plain} View S-UI Logs
  ${green}16.${plain} Enable S-UI Start on Boot
  ${green}17.${plain} Disable S-UI Start on Boot
---------------------------------------------------------------
  ${green}18.${plain} Enable or Disable BBR
  ${green}19.${plain} SSL Certificate Management
  ${green}20.${plain} Cloudflare SSL Certificate
---------------------------------------------------------------
 "
    show_status s-ui
    echo && read -p "Please enter your choice [0-20]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install
        ;;
    2)
        check_install && update
        ;;
    3)
        check_install && custom_version
        ;;
    4)
        check_install && uninstall
        ;;
    5)
        check_install && reset_admin
        ;;
    6)
        check_install && set_admin
        ;;
    7)
        check_install && view_admin
        ;;
    8)
        check_install && reset_setting
        ;;
    9)
        check_install && set_setting
        ;;
    10)
        check_install && view_setting
        ;;
    11)
        check_install && start s-ui
        ;;
    12)
        check_install && stop s-ui
        ;;
    13)
        check_install && restart s-ui
        ;;
    14)
        check_install && status s-ui
        ;;
    15)
        check_install && show_log s-ui
        ;;
    16)
        check_install && enable s-ui
        ;;
    17)
        check_install && disable s-ui
        ;;
    18)
        bbr_menu
        ;;
    19)
        ssl_cert_issue_main
        ;;
    20)
        ssl_cert_issue_CF
        ;;
    *)
        LOGE "Please enter a correct number [0-20]"
        ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
    "start")
        check_install 0 && start s-ui 0
        ;;
    "stop")
        check_install 0 && stop s-ui 0
        ;;
    "restart")
        check_install 0 && restart s-ui 0
        ;;
    "status")
        check_install 0 && status 0
        ;;
    "enable")
        check_install 0 && enable s-ui 0
        ;;
    "disable")
        check_install 0 && disable s-ui 0
        ;;
    "log")
        check_install 0 && show_log s-ui 0
        ;;
    "update")
        check_install 0 && update 0
        ;;
    "install")
        check_uninstall 0 && install 0
        ;;
    "uninstall")
        check_install 0 && uninstall 0
        ;;
    *) show_usage ;;
    esac
else
    show_menu
fi
