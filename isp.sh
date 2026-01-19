#!/bin/bash

# Copyright (c) 2025 zalisfer <egorovartemx@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# Этот файл распространяется под GNU General Public License v3 (GPLv3).
# Полный текст лицензии — в файле LICENSE в корне репозитория.

echo ""
echo "=== ПРОВЕРКА ЗАДАНИЙ НА ISP ==="
echo ""
echo "По гайду какого году была выполнена работа? (2025 или 2026):"
read -r YEAR

if [ "$YEAR" == "2025" ]; then
    echo "Выбран год: $YEAR"
    echo "Задание 1: Проверка имени хоста"
    if [ "$(hostname)" == "isp.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'isp.au-team.irpo', сейчас: $(hostname)"
    fi
    echo ""
    echo "Задание 2: Проверка сетевых интерфейсов и динамической транляции портов"
    echo "Интерфейс ens3 (DHCP от провайдера):"
    ip -4 addr show ens3 | grep inet
    echo "Интерфейс ens4 (к HQ-RTR):"
    ip -4 addr show ens4 | grep inet
    echo "Интерфейс ens5 (к BR-RTR):"
    ip -4 addr show ens5 | grep inet
    if ip -4 addr show ens4 | grep -q "172.16.4.1/28" && ip -4 addr show ens5 | grep -q "172.16.5.1/28"; then
        echo "✓ Сетевые интерфейсы настроены правильно"
    else
        echo "✗ Неправильные IP-адреса на интерфейсах"
    fi
    echo ""
    echo "Проверка IP forwarding"
    if sysctl net.ipv4.ip_forward | grep -q "net.ipv4.ip_forward = 1"; then
        echo "✓ IP forwarding включен"
        sysctl net.ipv4.ip_forward
    else
        echo "✗ Ошибка: IP forwarding не включен или значение не равно 1"
        echo "  Текущее значение: $(sysctl net.ipv4.ip_forward)"
    fi
    echo ""
    echo "Проверка NAT"
    if iptables -t nat -L POSTROUTING -v 2>/dev/null | grep -q "MASQUERADE"; then
        echo "✓ Правило MASQUERADE найдено в iptables"
        echo "  Вывод правила:"
        iptables -t nat -L POSTROUTING -v | grep "MASQUERADE"
    else
        echo "✗ Ошибка: правило MASQUERADE не найдено в iptables"
        echo "  Текущие правила NAT:"
        iptables -t nat -L POSTROUTING -v 2>/dev/null || echo "  iptables не доступен"
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
    if [ "$(hostname)" == "isp.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'isp.au-team.irpo', сейчас: $(hostname)"
    fi
    echo ""
    echo "Задание 2: Проверка сетевых интерфейсов и динамической транляции портов"
    echo "Интерфейс ens3 (DHCP от провайдера):"
    ip -4 addr show ens3 | grep inet
    echo "Интерфейс ens4 (к HQ-RTR):"
    ip -4 addr show ens4 | grep inet
    echo "Интерфейс ens5 (к BR-RTR):"
    ip -4 addr show ens5 | grep inet
    if ip -4 addr show ens4 | grep -q "172.16.1.1/28" && ip -4 addr show ens5 | grep -q "172.16.2.1/28"; then
        echo "✓ Сетевые интерфейсы настроены правильно"
    else
        echo "✗ Неправильные IP-адреса на интерфейсах"
    fi
    echo ""
    echo "Проверка IP forwarding"
    if sysctl net.ipv4.ip_forward | grep -q "net.ipv4.ip_forward = 1"; then
        echo "✓ IP forwarding включен"
        sysctl net.ipv4.ip_forward
    else
        echo "✗ Ошибка: IP forwarding не включен или значение не равно 1"
        echo "  Текущее значение: $(sysctl net.ipv4.ip_forward)"
    fi
    echo ""
    echo "Проверка NAT"
    if nft list ruleset | grep -q "masquerade"; then
        echo "✓ Правило masquerade найдено"
        nft list ruleset | grep -A5 "table ip nat"
    else
        echo "✗ Ошибка: правило masquerade не найдено"
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

