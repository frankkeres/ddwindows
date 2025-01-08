#!/bin/sh

if [[ $EUID -ne 0 ]]; then
    clear
    echo "Error: This script must be run as root!" 1>&2
    exit 1
fi

function CopyRight() {
  clear
  echo "########################################################"
  echo "########################################################"
  echo -e "\n"
}

function isValidIp() {
  local ip=$1
  local ret=1
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    ip=(${ip//\./ })
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    ret=$?
  fi
  return $ret
}

function ipCheck() {
  isLegal=0
  for add in $MAINIP $GATEWAYIP $NETMASK; do
    isValidIp $add
    if [ $? -eq 1 ]; then
      isLegal=1
    fi
  done
  return $isLegal
}

function GetIp() {
  MAINIP=$(ip route get 1 | awk -F 'src ' '{print $2}' | awk '{print $1}')
  GATEWAYIP=$(ip route | grep default | awk '{print $3}' | head -1)
  SUBNET=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}' | head -1 | awk -F '/' '{print $2}')
  value=$(( 0xffffffff ^ ((1 << (32 - $SUBNET)) - 1) ))
  NETMASK="$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"
}


while [[ $# -gt 0 ]]; do
  case $1 in
    --dd)
      dd=$2
      shift 2
      ;;
    --help)
      echo "Usage: $0 --name <name> --age <age>"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

GetIp
echo "IP: $MAINIP"
echo "Gateway: $GATEWAYIP"
echo "Netmask: $NETMASK"
echo "DD: $dd"

# 如果没有 --dd 参数，提示输入并退出
if [[ -z "$dd" ]]; then
  echo "错误: 缺少dd 参数 --dd"
  echo "例如: bash $0 --dd 'https://oss.sunpma.com/Windows/Win_Server2022_64_Administrator_nat.ee.gz'"
  exit 1
fi

wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/frankkeres/ddwindows/refs/heads/main/InstallNET.sh' && bash InstallNET.sh --ip-addr $MAINIP --ip-gate  $GATEWAYIP --ip-mask $NETMASK  -dd $dd