#!/bin/bash

# Copyright (c) 2025 zalisfer <egorovartemx@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# Этот файл распространяется под GNU General Public License v3 (GPLv3).
# Полный текст лицензии — в файле LICENSE в корне репозитория.

echo ""
echo "=== ПРОВЕРКА ЗАДАНИЙ НА HQ-CLI ==="
echo ""
echo "По гайду какого году была выполнена работа? (2025 или 2026):"
read -r YEAR

if [ "$YEAR" == "2025" ]; then
    echo "Выбран год: $YEAR"
    echo "Задание 1: Проверка имени хоста"
    echo "Проверка имени хоста:"
    if [ "$(hostname)" == "hq-cli.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'hq-cli.au-team.irpo', сейчас: $(hostname)"
    fi
    
    echo ""
    echo "Задание 9: Проверка DHCP-клиента"
    if ip -4 addr show ens3 | grep -q "192.168.100.6[5-9]\|192.168.100.7[0-8]"; then
        echo "✓ IP-адрес получен по DHCP из диапазона 192.168.100.65-78"
        if cat /etc/resolv.conf | grep -q "192.168.100.2"; then
            echo "✓ DNS-сервер указан корректно: 192.168.100.2"
        else
            echo "✗ Ошибка: DNS-сервер не указан или указан неверно"
        fi
    else
        echo "✗ Ошибка: IP-адрес не получен по DHCP или не из правильного диапазона"
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
    echo "Задание 1: Проверка имени хоста"
    echo "Проверка имени хоста:"
    if [ "$(hostname)" == "hq-cli.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'hq-cli.au-team.irpo', сейчас: $(hostname)"
    fi

    echo ""
    echo "Задание 9: Проверка DHCP-клиента"
    if ip -4 addr show ens3 | grep -q "192.168.100.3[4-9]\|192.168.100.4[0-7]"; then
        echo "✓ IP-адрес получен по DHCP из диапазона 192.168.100.34-47"
        if cat /etc/resolv.conf | grep -q "192.168.100.2"; then
            echo "✓ DNS-сервер указан корректно: 192.168.100.2"
        else
            echo "✗ Ошибка: DNS-сервер не указан или указан неверно"
        fi
    else
        echo "✗ Ошибка: IP-адрес не получен по DHCP или не из правильного диапазона"
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


