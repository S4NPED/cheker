#!/bin/bash

# Copyright (c) 2025 zalisfer <egorovartemx@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# Этот файл распространяется под GNU General Public License v3 (GPLv3).
# Полный текст лицензии — в файле LICENSE в корне репозитория.

echo ""
echo "=== ПРОВЕРКА ЗАДАНИЙ НА HQ-RTR ==="
echo ""
echo "По гайду какого году была выполнена работа? (2025 или 2026):"
read -r YEAR

if [ "$YEAR" == "2025" ]; then
    echo "Выбран год: $YEAR"
    echo "Задание 1: Проверка имени хоста и сетевых интерфейсов"
    echo "Проверка имени хоста:"
    if [ "$(hostname)" == "hq-rtr.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'hq-rtr.au-team.irpo', сейчас: $(hostname)"
    fi
    echo ""
    echo "Проверка сетевых интерфейсов:"
    echo "Интерфейс ens3 (к ISP):"
    ip -4 addr show ens3 | grep inet
    echo "VLAN100 (к HQ-SRV):"
    ip -4 addr show vlan100 | grep inet
    echo "VLAN200 (к HQ-CLI):"
    ip -4 addr show vlan200 | grep inet
    echo "VLAN999 (управление):"
    ip -4 addr show vlan999 | grep inet
    if ip -4 addr show ens3 | grep -q "172.16.4.2/28" && \
    ip -4 addr show vlan100 | grep -q "192.168.100.1/26" && \
    ip -4 addr show vlan200 | grep -q "192.168.100.65/28" && \
    ip -4 addr show vlan999 | grep -q "192.168.100.81/29"; then
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
    echo "Задание 4: Проверка VLAN (OpenvSwitch)"
    if ovs-vsctl show | grep -q "hq-sw"; then
        echo "✓ Мост hq-sw создан"
        echo "Порты на мосту:"
        ovs-vsctl list-ports hq-sw
    else
        echo "✗ Ошибка: мост hq-sw не найден"
    fi
    echo ""
    echo "Задание 6: Проверка GRE-туннеля"
    # Проверка существования интерфейса gre0
    if ip link show gre0 2>/dev/null | grep -q "gre0"; then
        echo "✓ Интерфейс gre0 существует"
        
        # Проверка IP-адреса на gre0
        if ip -4 addr show tun1 2>/dev/null | grep -q "10.10.0.1/30"; then
            echo "✓ Интерфейс tun1 имеет правильный IP: 10.10.0.1/30"
            
            # Проверка состояния интерфейса
            GRE_STATE=$(ip -o link show gre0 2>/dev/null | awk '{print $9}')
            if [ "$GRE_STATE" = "UP" ] || [ "$GRE_STATE" = "UNKNOWN" ]; then
                echo "✓ Интерфейс gre0 находится в состоянии: $GRE_STATE"
                
                # Проверка ping до удаленного конца туннеля
                echo "  Проверка связи с BR-RTR через GRE туннель..."
                if ping -c 3 -W 2 10.10.0.2 2>/dev/null | grep -q "bytes from"; then
                    echo "✓ Ping успешен: GRE туннель работает"
                    echo "  Статистика ping:"
                    ping -c 2 -W 2 10.10.0.2 | tail -3
                else
                    echo "✗ Ошибка: не удается выполнить ping до 10.10.0.2 (BR-RTR)"
                fi
            else
                echo "✗ Ошибка: интерфейс gre0 не поднят, состояние: $GRE_STATE"
            fi
        else
            echo "✗ Ошибка: интерфейс tun1 должен иметь IP 10.10.0.1/30"
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
    echo "Задание 9: Проверка DHCP"
    if systemctl is-active isc-dhcp-server > /dev/null; then
        echo "✓ DHCP-сервер работает" 
        if [ -f "/etc/default/isc-dhcp-server" ]; then
            echo "✓ Файл /etc/default/isc-dhcp-server существует"    
            # Проверка, что в INTERFACESv4 указан vlan200
            if grep -q '^INTERFACESv4="vlan200"' /etc/default/isc-dhcp-server || \
            grep -q '^INTERFACESv4=vlan200' /etc/default/isc-dhcp-server; then
                echo "✓ INTERFACESv4 правильно настроен на vlan200"
            else
                echo "✗ Ошибка: INTERFACESv4 не настроен на vlan200"
                echo "  Содержимое INTERFACESv4:"
                grep -i "INTERFACESv4" /etc/default/isc-dhcp-server || echo "  Не найдено"
            fi
        else
            echo "✗ Ошибка: файл /etc/default/isc-dhcp-server не существует"
        fi
        # Проверка DNS
        if grep -q "option domain-name-servers 192.168.100.2" /etc/dhcp/dhcpd.conf; then
            echo "✓ DNS-сервер настроен правильно"
        else
            echo "✗ Ошибка: DNS-сервер не настроен"
        fi
        
        # Проверка доменного суффикса
        if grep -q "option domain-name \"au-team.irpo\"" /etc/dhcp/dhcpd.conf; then
            echo "✓ Доменный суффикс настроен правильно"
        else
            echo "✗ Ошибка: доменный суффикс не настроен"
        fi
        echo "Конфигурация подсети VLAN200:"
        if grep -q "subnet 192.168.100.64"  /etc/dhcp/dhcpd.conf; then
            echo "✓ Подсеть 192.168.100.64 настроена"
            grep -A5 "subnet 192.168.100.64" /etc/dhcp/dhcpd.conf
        else
            echo "✗ Ошибка: подсеть 192.168.100.64 не настроена"
        fi
    else
        echo "✗ Ошибка: DHCP-сервер не запущен"
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
    if [ "$(hostname)" == "hq-rtr.au-team.irpo" ]; then
        echo "✓ Имя хоста корректно: $(hostname)"
    else
        echo "✗ Ошибка: имя хоста должно быть 'hq-rtr.au-team.irpo', сейчас: $(hostname)"
    fi
    echo ""
    echo "Проверка сетевых интерфейсов:"
    echo "Интерфейс ens3 (к ISP):"
    ip -4 addr show ens3 | grep inet
    echo "VLAN100 (к HQ-SRV):"
    ip -4 addr show vlan100 | grep inet
    echo "VLAN200 (к HQ-CLI):"
    ip -4 addr show vlan200 | grep inet
    echo "VLAN999 (управление):"
    ip -4 addr show vlan999 | grep inet
    if ip -4 addr show ens3 | grep -q "172.16.1.2/28" && \
    ip -4 addr show vlan100 | grep -q "192.168.100.1/27" && \
    ip -4 addr show vlan200 | grep -q "192.168.100.33/28" && \
    ip -4 addr show vlan999 | grep -q "192.168.100.49/29"; then
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
    echo "Задание 4: Проверка VLAN (OpenvSwitch)"
    if ovs-vsctl show | grep -q "hq-sw"; then
        echo "✓ Мост hq-sw создан"
        echo "Порты на мосту:"
        ovs-vsctl list-ports hq-sw
    else
        echo "✗ Ошибка: мост hq-sw не найден"
    fi
    echo ""
    echo "Задание 6: Проверка GRE-туннеля"
    # Проверка существования интерфейса gre0
    if ip link show gre0 2>/dev/null | grep -q "gre0"; then
        echo "✓ Интерфейс gre0 существует"
        
        # Проверка IP-адреса на gre0
        if ip -4 addr show tun1 2>/dev/null | grep -q "10.10.0.1/30"; then
            echo "✓ Интерфейс tun1 имеет правильный IP: 10.10.0.1/30"
            
            # Проверка состояния интерфейса
            GRE_STATE=$(ip -o link show gre0 2>/dev/null | awk '{print $9}')
            if [ "$GRE_STATE" = "UP" ] || [ "$GRE_STATE" = "UNKNOWN" ]; then
                echo "✓ Интерфейс gre0 находится в состоянии: $GRE_STATE"
                
                # Проверка ping до удаленного конца туннеля
                echo "  Проверка связи с BR-RTR через GRE туннель..."
                if ping -c 3 -W 2 10.10.0.2 2>/dev/null | grep -q "bytes from"; then
                    echo "✓ Ping успешен: GRE туннель работает"
                    echo "  Статистика ping:"
                    ping -c 2 -W 2 10.10.0.2 | tail -3
                else
                    echo "✗ Ошибка: не удается выполнить ping до 10.10.0.2 (BR-RTR)"
                fi
            else
                echo "✗ Ошибка: интерфейс gre0 не поднят, состояние: $GRE_STATE"
            fi
        else
            echo "✗ Ошибка: интерфейс tun1 должен иметь IP 10.10.0.1/30"
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
    echo "Задание 9: Проверка DHCP"
    if systemctl is-active isc-dhcp-server > /dev/null; then
        echo "✓ DHCP-сервер работает" 
        if [ -f "/etc/default/isc-dhcp-server" ]; then
            echo "✓ Файл /etc/default/isc-dhcp-server существует"    
            # Проверка, что в INTERFACESv4 указан vlan200
            if grep -q '^INTERFACESv4="vlan200"' /etc/default/isc-dhcp-server || \
            grep -q '^INTERFACESv4=vlan200' /etc/default/isc-dhcp-server; then
                echo "✓ INTERFACESv4 правильно настроен на vlan200"
            else
                echo "✗ Ошибка: INTERFACESv4 не настроен на vlan200"
                echo "  Содержимое INTERFACESv4:"
                grep -i "INTERFACESv4" /etc/default/isc-dhcp-server || echo "  Не найдено"
            fi
        else
            echo "✗ Ошибка: файл /etc/default/isc-dhcp-server не существует"
        fi
        # Проверка DNS
        if grep -q "option domain-name-servers 192.168.100.2" /etc/dhcp/dhcpd.conf; then
            echo "✓ DNS-сервер настроен правильно"
        else
            echo "✗ Ошибка: DNS-сервер не настроен"
        fi
        
        # Проверка доменного суффикса
        if grep -q "option domain-name \"au-team.irpo\"" /etc/dhcp/dhcpd.conf; then
            echo "✓ Доменный суффикс настроен правильно"
        else
            echo "✗ Ошибка: доменный суффикс не настроен"
        fi
        echo "Конфигурация подсети VLAN200:"
        if grep -q "subnet 192.168.100.32" /etc/dhcp/dhcpd.conf; then
            echo "✓ Подсеть 192.168.100.32 настроена"
            grep -A5 "subnet 192.168.100.32" /etc/dhcp/dhcpd.conf
        else
            echo "✗ Ошибка: подсеть 192.168.100.32 не настроена"
        fi
    else
        echo "✗ Ошибка: DHCP-сервер не запущен"
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

