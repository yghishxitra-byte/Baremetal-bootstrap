#!/usr/bin/env bash

set -euo pipefail

echo "=== NRI-AI: SSH & Fail2Ban setup ==="

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

echo "[1/7] Устанавливаем OpenSSH Server и Fail2Ban..."
sudo apt-get update
sudo apt-get install -y openssh-server fail2ban

echo "[2/7] Создаём директорию SSH..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "[3/7] Проверяем SSH-ключ..."

if [ ! -f "$SSH_KEY" ]; then
    echo "SSH-ключ не найден. Создаём новый ed25519 ключ..."
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N ""
else
    echo "SSH-ключ уже существует, используем его."
fi

echo "[4/7] Настраиваем authorized_keys..."

touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

if ! grep -qxF "$(cat "$SSH_KEY.pub")" "$AUTHORIZED_KEYS"; then
    cat "$SSH_KEY.pub" >> "$AUTHORIZED_KEYS"
    echo "Публичный ключ добавлен в authorized_keys."
else
    echo "Публичный ключ уже находится в authorized_keys."
fi

echo "[5/7] Настраиваем SSH server..."

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

echo "[6/7] Настраиваем базовую защиту Fail2Ban для SSH..."

# Создаем файл локальной конфигурации (jail.local), чтобы не затереть дефолтные настройки
JAIL_LOCAL="/etc/fail2ban/jail.local"

sudo bash -c "cat << 'EOF' > $JAIL_LOCAL
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
backend = %(sshd_backend)s
# Бан на 1 час (3600 секунд) за 5 неудачных попыток в течение 10 минут
bantime = 3600
findtime = 600
maxretry = 5
EOF"

echo "Конфигурация jail.local успешно создана."

echo "[7/7] Проверяем конфигурацию SSH..."

sudo sshd -t

echo
echo "Конфигурация SSH корректна."
echo

if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    echo "Запускаем службы через systemd..."
    sudo systemctl enable ssh fail2ban
    sudo systemctl restart ssh fail2ban
else
    echo "systemd не используется. Запускаем службы вручную..."
    sudo service ssh restart
    sudo service fail2ban restart
fi

echo
echo "=== Готово ==="
echo
echo "Проверить статус Fail2Ban можно командой:"
echo "  sudo fail2ban-client status sshd"
echo
echo "Проверить статус служб:"
echo "  sudo service ssh status"
echo "  sudo service fail2ban status"
