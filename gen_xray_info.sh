#!/bin/bash

set -e

echo "===== 1. 更新系统 & 安装依赖 ====="
apt update && apt upgrade -y
apt install -y curl vim ntpdate openssl

echo "===== 2. 安装 Xray ====="
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"

echo "===== 3. 时间同步 ====="
ntpdate time.cloudflare.com

echo "===== 4. 生成 UUID ====="
UUID=$(xray uuid)

echo "===== 5. 生成 Reality 密钥 ====="
KEYS=$(xray x25519)

REALITY_PRIVATE_KEY=$(echo "$KEYS" | grep "^PrivateKey:" | awk -F': ' '{print $2}')
REALITY_PASSWORD=$(echo "$KEYS" | grep "^Password:"   | awk -F': ' '{print $2}')
REALITY_HASH32=$(echo "$KEYS" | grep "^Hash32:"     | awk -F': ' '{print $2}')

echo "===== 6. 生成 Short ID ====="
SHORT_ID=$(openssl rand -hex 8)

echo "===== 7. 获取公网 IP ====="
SERVER_IP=$(curl -s https://api.ipify.org)

echo
echo "======================================"
echo "✅ 生成完成（未写入任何配置文件）"
echo
echo "服务器 IP:          $SERVER_IP"
echo "UUID:               $UUID"
echo "Reality PrivateKey: $REALITY_PRIVATE_KEY"
echo "Reality Password:   $REALITY_PASSWORD"
echo "Reality Hash32:     $REALITY_HASH32"
echo "Short ID:           $SHORT_ID"
echo "======================================"
echo
echo "��� 直接复制以上内容，粘给 AI 或自己写 config.json"

