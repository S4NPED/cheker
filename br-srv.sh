#!/bin/bash

# Copyright (c) 2025 zalisfer <egorovartemx@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# Этот файл распространяется под GNU General Public License v3 (GPLv3).
# Полный текст лицензии — в файле LICENSE в корне репозитория.

echo ""
echo "=== ПРОВЕРКА ЗАДАНИЙ НА BR-SRV ==="
echo ""
echo "По гайду какого году была выполнена работа? (2025 или 2026):"
read -r YEAR

if [ "$YEAR" == "2025" ]; then
    echo "Выбран год: $YEAR"
    echo "Задание 1: Проверка имени хоста и сетевого интерфейсов"
    if [ "$(hostname)" == "br-srv.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'br-srv.au-team.irpo', сейчас: $(hostname)"
    fi

    echo ""
    echo "Проверка сетевого интерфейса"
    if ip -4 addr show ens3 | grep -q "192.168.200.2/27"; then
        echo "✓ IP-адрес корректный: 192.168.200.2/27"
    else
        echo "✗ Ошибка: неправильный IP-адрес на ens3"
    fi

    echo ""
    echo "Задание 3: Проверка пользователя sshuser"
    if id sshuser &>/dev/null; then
        echo "✓ Пользователь sshuser существует"
        
        # Проверка UID
        if [ "$(id -u sshuser)" -eq 1010 ]; then
            echo "✓ UID пользователя корректный: 1010"
        else
            echo "✗ Ошибка: UID пользователя должен быть 1010, сейчас: $(id -u sshuser)"
        fi
        
        # Проверка пароля
        if sudo passwd -S sshuser 2>/dev/null | grep -q " P "; then
            echo "✓ Пароль установлен"
        else
            echo "✗ Ошибка: пароль не установлен или учетная запись заблокирована"
        fi
        
        # Проверка членства в группе sudo
        if groups sshuser | grep -q '\bsudo\b'; then
            echo "✓ Пользователь входит в группу sudo"
        else
            echo "✗ Ошибка: пользователь не входит в группу sudo"
        fi
        
        # Проверка записи в sudoers для NOPASSWD
        if sudo grep -r "sshuser.*NOPASSWD" /etc/sudoers* 2>/dev/null | grep -q "sshuser"; then
            echo "✓ Найдена запись NOPASSWD для sshuser в sudoers"
            sudo grep -r "sshuser.*NOPASSWD" /etc/sudoers* 2>/dev/null | head -1
        else
            echo "✗ Ошибка: запись NOPASSWD для sshuser не найдена в sudoers"
        fi
    else
        echo "✗ Ошибка: пользователь sshuser не найден"
    fi

    echo ""
    echo "Задание 5: Проверка SSH"
    if systemctl is-active ssh > /dev/null; then
        echo "✓ SSH-сервер работает"
        
        # Проверка порта
        if grep -q "^Port 2024" /etc/ssh/sshd_config; then
            echo "✓ SSH настроен на порт 2024"
        else
            echo "✗ Ошибка: SSH не настроен на порт 2024"
            echo "  Текущий порт: $(grep -E '^Port|^#Port' /etc/ssh/sshd_config | tail -1)"
        fi
        
        # Проверка разрешенных пользователей
        if grep -q "^AllowUsers sshuser" /etc/ssh/sshd_config; then
            echo "✓ Доступ SSH разрешен только для sshuser"
        else
            echo "✗ Ошибка: в SSH не настроен AllowUsers sshuser"
        fi
        
        # Проверка MaxAuthTries
        if grep -q "^MaxAuthTries 2" /etc/ssh/sshd_config; then
            echo "✓ Максимальное количество попыток входа: 2"
        else
            echo "✗ Ошибка: MaxAuthTries не установлен в 2"
        fi
        
        # Проверка баннера
        if grep -q "^Banner /etc/ssh-banner" /etc/ssh/sshd_config && [ -f "/etc/ssh-banner" ]; then
            echo "✓ Баннер настроен и файл существует"
            echo "  Содержимое баннера:"
            head -5 /etc/ssh-banner
        else
            echo "✗ Ошибка: баннер не настроен или файл не существует"
        fi
    else
        echo "✗ Ошибка: SSH не запущен"
    fi

    echo ""
    echo "Задание 11: Проверка часового пояса"
    if timedatectl | grep -q "Asia/Krasnoyarsk"; then
        echo "✓ Часовой пояс корректно установлен: Asia/Krasnoyarsk"
    else
        echo "✗ Ошибка: неверный часовой пояс"
        echo "  Текущий часовой пояс:"
        timedatectl | grep "Time zone"
    fi

elif [ "$YEAR" == "2026" ]; then
    echo "Выбран год: $YEAR"
    echo "Задание 1: Проверка имени хоста и сетевого интерфейсов"
    if [ "$(hostname)" == "br-srv.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'br-srv.au-team.irpo', сейчас: $(hostname)"
    fi

    echo ""
    echo "Проверка сетевого интерфейса"
    if ip -4 addr show ens3 | grep -q "192.168.200.2/28"; then
        echo "✓ IP-адрес корректный: 192.168.200.2/28"
    else
        echo "✗ Ошибка: неправильный IP-адрес на ens3"
    fi

    echo ""
    echo "Задание 3: Проверка пользователя sshuser"
    if id sshuser &>/dev/null; then
        echo "✓ Пользователь sshuser существует"
        
        # Проверка UID
        if [ "$(id -u sshuser)" -eq 2026 ]; then
            echo "✓ UID пользователя корректный: 2026"
        else
            echo "✗ Ошибка: UID пользователя должен быть 2026, сейчас: $(id -u sshuser)"
        fi
        
        # Проверка пароля
        if sudo passwd -S sshuser 2>/dev/null | grep -q " P "; then
            echo "✓ Пароль установлен"
        else
            echo "✗ Ошибка: пароль не установлен или учетная запись заблокирована"
        fi
        
        # Проверка членства в группе sudo
        if groups sshuser | grep -q '\bsudo\b'; then
            echo "✓ Пользователь входит в группу sudo"
        else
            echo "✗ Ошибка: пользователь не входит в группу sudo"
        fi
        
        # Проверка записи в sudoers для NOPASSWD
        if sudo grep -r "sshuser.*NOPASSWD" /etc/sudoers* 2>/dev/null | grep -q "sshuser"; then
            echo "✓ Найдена запись NOPASSWD для sshuser в sudoers"
            sudo grep -r "sshuser.*NOPASSWD" /etc/sudoers* 2>/dev/null | head -1
        else
            echo "✗ Ошибка: запись NOPASSWD для sshuser не найдена в sudoers"
        fi
    else
        echo "✗ Ошибка: пользователь sshuser не найден"
    fi

    echo ""
    echo "Задание 5: Проверка SSH"
    if systemctl is-active ssh > /dev/null; then
        echo "✓ SSH-сервер работает"
        
        # Проверка порта
        if grep -q "^Port 2026" /etc/ssh/sshd_config; then
            echo "✓ SSH настроен на порт 2026"
        else
            echo "✗ Ошибка: SSH не настроен на порт 2026"
            echo "  Текущий порт: $(grep -E '^Port|^#Port' /etc/ssh/sshd_config | tail -1)"
        fi
        
        # Проверка разрешенных пользователей
        if grep -q "^AllowUsers sshuser" /etc/ssh/sshd_config; then
            echo "✓ Доступ SSH разрешен только для sshuser"
        else
            echo "✗ Ошибка: в SSH не настроен AllowUsers sshuser"
        fi
        
        # Проверка MaxAuthTries
        if grep -q "^MaxAuthTries 2" /etc/ssh/sshd_config; then
            echo "✓ Максимальное количество попыток входа: 2"
        else
            echo "✗ Ошибка: MaxAuthTries не установлен в 2"
        fi
        
        # Проверка баннера
        if grep -q "^Banner /etc/ssh_banner" /etc/ssh/sshd_config && [ -f "/etc/ssh_banner" ]; then
            echo "✓ Баннер настроен и файл существует"
            echo "  Содержимое баннера:"
            head -5 /etc/ssh_banner
        else
            echo "✗ Ошибка: баннер не настроен или файл не существует"
        fi
    else
        echo "✗ Ошибка: SSH не запущен"
    fi

    echo ""
    echo "Задание 11: Проверка часового пояса"
    if timedatectl | grep -q "Asia/Krasnoyarsk"; then
        echo "✓ Часовой пояс корректно установлен: Asia/Krasnoyarsk"
    else
        echo "✗ Ошибка: неверный часовой пояс"
        echo "  Текущий часовой пояс:"
        timedatectl | grep "Time zone"
    fi
else
    echo "✗ Ошибка: значение может быть только 2025 или 2026"
fi

