#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

echo "===== 1. 更新系统 & 安装依赖 ====="
apt update
apt upgrade -y

apt install -y curl vim openssl ca-certificates

echo "===== 1.1 安装时间同步工具 ====="
if apt-cache show ntpsec-ntpdate >/dev/null 2>&1; then
    apt install -y ntpsec-ntpdate
elif apt-cache show ntpdate >/dev/null 2>&1; then
    apt install -y ntpdate
else
    echo "未找到 ntpsec-ntpdate 或 ntpdate，尝试安装 systemd-timesyncd"
    apt install -y systemd-timesyncd
fi

echo "===== 2. 安装 Xray ====="
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"

echo "===== 3. 时间同步 ====="
if command -v ntpdate >/dev/null 2>&1; then
    ntpdate -u time.cloudflare.com || ntpdate -u pool.ntp.org || true
else
    timedatectl set-ntp true || true
fi

echo "===== 4. 生成 UUID ====="
UUID=$(xray uuid)

echo "===== 5. 生成 Reality 密钥 ====="
KEYS=$(xray x25519)

REALITY_PRIVATE_KEY=$(echo "$KEYS" | awk -F': *' '/^PrivateKey:/ {print $2; exit}')
REALITY_PUBLIC_KEY=$(echo "$KEYS" | awk -F': *' '/^(Password|PublicKey|Password \(PublicKey\)):/ {print $2; exit}')
REALITY_HASH32=$(echo "$KEYS" | awk -F': *' '/^Hash32:/ {print $2; exit}')

if [ -z "$REALITY_PRIVATE_KEY" ] || [ -z "$REALITY_PUBLIC_KEY" ]; then
    echo "❌ Reality 密钥解析失败，xray x25519 原始输出如下："
    echo "$KEYS"
    exit 1
fi

if [ -z "$REALITY_HASH32" ]; then
    REALITY_HASH32="-"
fi

echo "===== 6. 生成 Short ID ====="
SHORT_ID=$(openssl rand -hex 8)

echo "===== 7. 获取公网 IP ====="
SERVER_IP=$(curl -s https://api.ipify.org || true)

if [ -z "$SERVER_IP" ]; then
    SERVER_IP="获取失败，请手动填写"
fi

echo
echo "======================================"
echo "✅ 生成完成（未写入任何配置文件）"
echo
echo "服务器 IP:              $SERVER_IP"
echo "UUID:                   $UUID"
echo "Reality PrivateKey:     $REALITY_PRIVATE_KEY"
echo "Reality PublicKey:      $REALITY_PUBLIC_KEY"
echo "Reality Hash32:         $REALITY_HASH32"
echo "Short ID:               $SHORT_ID"
echo "======================================"
echo
