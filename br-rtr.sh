#!/bin/bash

# Copyright (c) 2025 zalisfer <egorovartemx@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# Этот файл распространяется под GNU General Public License v3 (GPLv3).
# Полный текст лицензии — в файле LICENSE в корне репозитория.

echo ""
echo "=== ПРОВЕРКА ЗАДАНИЙ НА BR-RTR ==="
echo ""
echo "По гайду какого году была выполнена работа? (2025 или 2026):"
read -r YEAR

if [ "$YEAR" == "2025" ]; then
    echo "Выбран год: $YEAR"
    echo "Задание 1: Проверка имени хоста и сетевых интерфейсов"
    echo "Проверка имени хоста:"
    if [ "$(hostname)" == "br-rtr.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'br-rtr.au-team.irpo', сейчас: $(hostname)"
    fi

    echo ""
    echo "Проверка сетевых интерфейсов"
    echo "Интерфейс ens3 (к ISP):"
    ip -4 addr show ens3 | grep inet || echo "  IP не назначен"
    echo "Интерфейс ens4 (к BR-SRV):"
    ip -4 addr show ens4 | grep inet || echo "  IP не назначен"

    if ip -4 addr show ens3 | grep -q "172.16.5.2/28" && ip -4 addr show ens4 | grep -q "192.168.200.1/27"; then
        echo "✓ Настройка сетевых интерфейсов выполнена успешно"
    else
        echo "✗ Неправильные IP-адреса на интерфейсах"
    fi

    echo ""
    echo "Задание 3: Проверка пользователя net_admin"
    if id net_admin &>/dev/null; then
        echo "✓ Пользователь net_admin существует"

        # Проверка UID и группы
        echo "  UID пользователя: $(id -u net_admin)"
        echo "  Основная группа: $(id -gn net_admin)"
        
        # Проверка пароля (что он установлен, не заблокирован)
        if sudo passwd -S net_admin 2>/dev/null | grep -q " P "; then
            echo "✓ Пароль установлен"
        else
            echo "✗ Ошибка: пароль не установлен или учетная запись заблокирована"
        fi
        
        # Проверка членства в группе sudo
        if groups net_admin | grep -q '\bsudo\b'; then
            echo "✓ Пользователь входит в группу sudo"
        else
            echo "✗ Ошибка: пользователь не входит в группу sudo"
        fi
        
        # Проверка записи в sudoers для NOPASSWD
        if sudo grep -r "net_admin.*NOPASSWD" /etc/sudoers* 2>/dev/null | grep -q "net_admin"; then
            echo "✓ Найдена запись NOPASSWD для net_admin в sudoers"
            sudo grep -r "net_admin.*NOPASSWD" /etc/sudoers* 2>/dev/null | head -1
        else
            echo "✗ Ошибка: запись NOPASSWD для net_admin не найдена в sudoers"
        fi
    fi

    echo ""
    echo "Задание 6: Проверка GRE-туннеля"
    # Проверка существования интерфейса gre0
    if ip link show gre0 2>/dev/null | grep -q "gre0"; then
        echo "✓ Интерфейс gre0 существует"
        
        # Проверка IP-адреса на gre0
        if ip -4 addr show tun1 2>/dev/null | grep -q "10.10.0.2/30"; then
            echo "✓ Интерфейс tun1 имеет правильный IP: 10.10.0.2/30"
            
            # Проверка состояния интерфейса
            GRE_STATE=$(ip -o link show gre0 2>/dev/null | awk '{print $9}')
            if [ "$GRE_STATE" = "UP" ] || [ "$GRE_STATE" = "UNKNOWN" ]; then
                echo "✓ Интерфейс gre0 находится в состоянии: $GRE_STATE"
                
                # Проверка ping до удаленного конца туннеля
                echo "  Проверка связи с HQ-RTR через GRE туннель..."
                if ping -c 3 -W 2 10.10.0.1 2>/dev/null | grep -q "bytes from"; then
                    echo "✓ Ping успешен: GRE туннель работает"
                    echo "  Статистика ping:"
                    ping -c 2 -W 2 10.10.0.1 | tail -3
                else
                    echo "✗ Ошибка: не удается выполнить ping до 10.10.0.1 (HQ-RTR)"
                fi
            else
                echo "✗ Ошибка: интерфейс gre0 не поднят, состояние: $GRE_STATE"
            fi
        else
            echo "✗ Ошибка: интерфейс tun1 должен иметь IP 10.10.0.2/30"
            echo "  Текущие IP на tun1:"
            ip -4 addr show tun1 2>/dev/null | grep inet || echo "  IP не назначен"
        fi
    else
        echo "✗ Ошибка: интерфейс gre0 не существует"
        echo "  Возможно, GRE туннель не был создан"
    fi


    echo ""
    echo "Задание 7: Проверка OSPF (FRR)"
    if systemctl is-active frr > /dev/null; then
        echo "✓ FRR работает"
        echo "Соседство OSPF:"
        if vtysh -c "show ip ospf neighbor" 2>/dev/null | grep -q "Full"; then
            echo "✓ Соседство установлено"
            vtysh -c "show ip ospf neighbor"
        else
            echo "✗ Ошибка: соседство OSPF не установлено"
        fi
    else
        echo "✗ Ошибка: FRR не запущен"
    fi

    echo ""
    echo "Задание 8: Проверка NAT (nftables) и IP forwarding"
    echo "Проверка правил NAT"
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
    echo "Проверка IP forwarding:"
    if sysctl net.ipv4.ip_forward | grep -q "net.ipv4.ip_forward = 1"; then
        echo "✓ IP forwarding включен"
        sysctl net.ipv4.ip_forward
    else
        echo "✗ Ошибка: IP forwarding не включен или значение не равно 1"
        echo "  Текущее значение: $(sysctl net.ipv4.ip_forward)"
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
    echo "Задание 1: Проверка имени хоста и сетевых интерфейсов"
    echo "Проверка имени хоста:"
    if [ "$(hostname)" == "br-rtr.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'br-rtr.au-team.irpo', сейчас: $(hostname)"
    fi

    echo ""
    echo "Проверка сетевых интерфейсов"
    echo "Интерфейс ens3 (к ISP):"
    ip -4 addr show ens3 | grep inet || echo "  IP не назначен"
    echo "Интерфейс ens4 (к BR-SRV):"
    ip -4 addr show ens4 | grep inet || echo "  IP не назначен"

    if ip -4 addr show ens3 | grep -q "172.16.2.2/28" && ip -4 addr show ens4 | grep -q "192.168.200.1/28"; then
        echo "✓ Настройка сетевых интерфейсов выполнена успешно"
    else
        echo "✗ Неправильные IP-адреса на интерфейсах"
    fi

    echo ""
    echo "Задание 3: Проверка пользователя net_admin"
    if id net_admin &>/dev/null; then
        echo "✓ Пользователь net_admin существует"

        # Проверка UID и группы
        echo "  UID пользователя: $(id -u net_admin)"
        echo "  Основная группа: $(id -gn net_admin)"
        
        # Проверка пароля (что он установлен, не заблокирован)
        if sudo passwd -S net_admin 2>/dev/null | grep -q " P "; then
            echo "✓ Пароль установлен"
        else
            echo "✗ Ошибка: пароль не установлен или учетная запись заблокирована"
        fi
        
        # Проверка членства в группе sudo
        if groups net_admin | grep -q '\bsudo\b'; then
            echo "✓ Пользователь входит в группу sudo"
        else
            echo "✗ Ошибка: пользователь не входит в группу sudo"
        fi
        
        # Проверка записи в sudoers для NOPASSWD
        if sudo grep -r "net_admin.*NOPASSWD" /etc/sudoers* 2>/dev/null | grep -q "net_admin"; then
            echo "✓ Найдена запись NOPASSWD для net_admin в sudoers"
            sudo grep -r "net_admin.*NOPASSWD" /etc/sudoers* 2>/dev/null | head -1
        else
            echo "✗ Ошибка: запись NOPASSWD для net_admin не найдена в sudoers"
        fi
    fi

    echo ""
    echo "Задание 6: Проверка GRE-туннеля"
    # Проверка существования интерфейса gre0
    if ip link show gre0 2>/dev/null | grep -q "gre0"; then
        echo "✓ Интерфейс gre0 существует"
        
        # Проверка IP-адреса на gre0
        if ip -4 addr show tun1 2>/dev/null | grep -q "10.10.0.2/30"; then
            echo "✓ Интерфейс tun1 имеет правильный IP: 10.10.0.2/30"
            
            # Проверка состояния интерфейса
            GRE_STATE=$(ip -o link show gre0 2>/dev/null | awk '{print $9}')
            if [ "$GRE_STATE" = "UP" ] || [ "$GRE_STATE" = "UNKNOWN" ]; then
                echo "✓ Интерфейс gre0 находится в состоянии: $GRE_STATE"
                
                # Проверка ping до удаленного конца туннеля
                echo "  Проверка связи с HQ-RTR через GRE туннель..."
                if ping -c 3 -W 2 10.10.0.1 2>/dev/null | grep -q "bytes from"; then
                    echo "✓ Ping успешен: GRE туннель работает"
                    echo "  Статистика ping:"
                    ping -c 2 -W 2 10.10.0.1 | tail -3
                else
                    echo "✗ Ошибка: не удается выполнить ping до 10.10.0.1 (HQ-RTR)"
                fi
            else
                echo "✗ Ошибка: интерфейс gre0 не поднят, состояние: $GRE_STATE"
            fi
        else
            echo "✗ Ошибка: интерфейс tun1 должен иметь IP 10.10.0.2/30"
            echo "  Текущие IP на tun1:"
            ip -4 addr show tun1 2>/dev/null | grep inet || echo "  IP не назначен"
        fi
    else
        echo "✗ Ошибка: интерфейс gre0 не существует"
        echo "  Возможно, GRE туннель не был создан"
    fi


    echo ""
    echo "Задание 7: Проверка OSPF (FRR)"
    if systemctl is-active frr > /dev/null; then
        echo "✓ FRR работает"
        echo "Соседство OSPF:"
        if vtysh -c "show ip ospf neighbor" 2>/dev/null | grep -q "Full"; then
            echo "✓ Соседство установлено"
            vtysh -c "show ip ospf neighbor"
        else
            echo "✗ Ошибка: соседство OSPF не установлено"
        fi
    else
        echo "✗ Ошибка: FRR не запущен"
    fi

    echo ""
    echo "Задание 8: Проверка NAT (nftables) и IP forwarding"
    echo "Проверка правил NAT:"
    if nft list ruleset | grep -q "masquerade"; then
        echo "✓ Правило masquerade найдено"
        nft list ruleset | grep -A5 "table ip nat"
    else
        echo "✗ Ошибка: правило masquerade не найдено"
    fi

    echo ""
    echo "Проверка IP forwarding:"
    if sysctl net.ipv4.ip_forward | grep -q "net.ipv4.ip_forward = 1"; then
        echo "✓ IP forwarding включен"
        sysctl net.ipv4.ip_forward
    else
        echo "✗ Ошибка: IP forwarding не включен или значение не равно 1"
        echo "  Текущее значение: $(sysctl net.ipv4.ip_forward)"
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