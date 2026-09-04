#!/usr/bin/env bash

set -euo pipefail

echo "=== NRI-AI: WSL bootstrap setup ==="

echo "[1/4] Обновляем список пакетов..."
sudo apt-get update

echo "[2/4] Устанавливаем базовые инструменты..."
sudo apt-get install -y \
    git \
    curl \
    wget \
    htop \
    tree \
    jq \
    unzip \
    zip \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    pipx

echo "[3/4] Настраиваем pipx..."
pipx ensurepath

echo "[4/4] Устанавливаем Ansible..."
pipx install ansible

echo
echo "=== Готово ==="
echo
echo "Проверка:"
echo "  git --version"
echo "  python3 --version"
echo "  ansible --version"
echo
echo "Если команда 'ansible' пока не найдена,"
echo "перезапустите терминал WSL или выполните:"
echo "  source ~/.bashrc"