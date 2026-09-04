#!/usr/bin/env bash

set -euo pipefail

echo "=== NRI-AI: SSH setup ==="

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

echo "[1/6] Устанавливаем OpenSSH Server..."
sudo apt-get update
sudo apt-get install -y openssh-server

echo "[2/6] Создаём директорию SSH..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "[3/6] Проверяем SSH-ключ..."

if [ ! -f "$SSH_KEY" ]; then
    echo "SSH-ключ не найден. Создаём новый ed25519 ключ..."
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N ""
else
    echo "SSH-ключ уже существует, используем его."
fi

echo "[4/6] Настраиваем authorized_keys..."

touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

if ! grep -qxF "$(cat "$SSH_KEY.pub")" "$AUTHORIZED_KEYS"; then
    cat "$SSH_KEY.pub" >> "$AUTHORIZED_KEYS"
    echo "Публичный ключ добавлен в authorized_keys."
else
    echo "Публичный ключ уже находится в authorized_keys."
fi

echo "[5/6] Настраиваем SSH server..."

SSHD_CONFIG="/etc/ssh/sshd_config"

sudo cp "$SSHD_CONFIG" "${SSHD_CONFIG}.backup"

sudo sed -i \
    -E 's/^[#[:space:]]*PubkeyAuthentication[[:space:]].*/PubkeyAuthentication yes/' \
    "$SSHD_CONFIG"

sudo sed -i \
    -E 's/^[#[:space:]]*PasswordAuthentication[[:space:]].*/PasswordAuthentication yes/' \
    "$SSHD_CONFIG"

sudo sed -i \
    -E 's/^[#[:space:]]*PermitRootLogin[[:space:]].*/PermitRootLogin no/' \
    "$SSHD_CONFIG"

echo "[6/6] Проверяем конфигурацию SSH..."

sudo sshd -t

echo
echo "Конфигурация SSH корректна."
echo

if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    echo "Запускаем SSH через systemd..."
    sudo systemctl enable ssh
    sudo systemctl restart ssh
else
    echo "systemd не используется. Запускаем SSH вручную..."
    sudo service ssh restart
fi

echo
echo "=== Готово ==="
echo
echo "Проверить SSH можно командой:"
echo "  ssh localhost"
echo
echo "Проверить статус:"
echo "  sudo service ssh status"