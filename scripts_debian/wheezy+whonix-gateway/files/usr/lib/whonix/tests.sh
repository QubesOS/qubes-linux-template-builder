#!/bin/bash

. /usr/lib/whonix/utility_functions

#sed -i 's/^DisableNetwork 0/#DisableNetwork 0/g' "/etc/tor/torrc"
#disable_sysv tor
#disable_sysv sdwdate

iptables -F
iptables -t nat -F

LOG_IP4=1
LOG_IP6=0

# for IPv4
if [ "$LOG_IP4" == "1" ]; then
    iptables -t raw -A OUTPUT -p icmp -j TRACE
    iptables -t raw -A PREROUTING -p icmp -j TRACE
    modprobe ipt_LOG
fi

# for IPv6
if [ "$LOG_IP6" == "1" ]; then
    ip6tables -t raw -A OUTPUT -p icmpv6 --icmpv6-type echo-request -j TRACE
    ip6tables -t raw -A OUTPUT -p icmpv6 --icmpv6-type echo-reply -j TRACE
    ip6tables -t raw -A PREROUTING -p icmpv6 --icmpv6-type echo-request -j TRACE
    ip6tables -t raw -A PREROUTING -p icmpv6 --icmpv6-type echo-reply -j TRACE
    modprobe ip6t_LOG
fi

sysctl -w net.ipv4.ip_forward=1

iptables -A FORWARD -i eth0 -j ACCEPT
iptables -A FORWARD -o eth0 -j ACCEPT
iptables -A FORWARD -i lo -j ACCEPT
iptables -A FORWARD -o lo -j ACCEPT

#iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#iptables -t nat -A OUTPUT -p tcp -j DNAT --to-destination 10.137.255.254:8082
#iptables -t nat -A OUTPUT -p tcp -s 10.137.255.254 --sport 8082 -j DNAT --to-destination 127.0.0.1:9105
#iptables -t nat -A OUTPUT -p tcp -s 10.137.2.1 --sport 9105 -j DNAT --to-destination 10.137.255.254:8082
#iptables -t nat -A OUTPUT -p tcp -d 10.137.2.1 --dport 9105 -j DNAT --to-destination 10.137.255.254:8082
#iptables -t nat -A OUTPUT -p tcp --dport 9105 -j DNAT --to-destination 10.137.255.254:8082
#iptables -t nat -A OUTPUT -p tcp --sport 9105 -j DNAT --to-destination 10.137.255.254:8082
#iptables -t nat -A OUTPUT -p tcp  -j DNAT --to-destination 10.137.255.254:8082


#iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 9105 -j DNAT --to 10.137.255.254:8082
#iptables -t nat -A PREROUTING -i lo -p tcp --dport 9105 -j DNAT --to 10.137.255.254:8082

#iptables -t nat -A INPUT -i vif+ -p tcp --dport 8082 -j ACCEPT"
#iptables -t nat -A PR-QBS-SERVICES -i vif+ -d 10.137.255.254 -p tcp --dport 8082 -j REDIRECT"

#iptables -t nat -A OUTPUT -o eth0 -p tcp --dport 9105 -j ACCEPT
#iptables -t nat -A OUTPUT -o lo -p tcp --dport 9105 -j ACCEPT
#iptables -t nat -A PREROUTING -i lo -d 10.137.255.254 -p tcp --dport 8082 -j REDIRECT
#iptables -t nat -A PREROUTING -i eth0 -d 10.137.255.254 -p tcp --dport 8082 -j REDIRECT
#iptables -t nat -A PREROUTING -i lo -p tcp --dport 9105 -j REDIRECT --to-destination 10.137.255.254:8082
#iptables -t nat -A PREROUTING -p tcp --dport 8082 -i eth0 -j DNAT --to 10.137.255.254:8082
#iptables -t nat -A PREROUTING -p tcp -i eth0 -j DNAT --to 10.137.255.254:8082
#iptables -t nat -A PREROUTING -p tcp -i lo -j DNAT --to 10.137.255.254:8082

#iptables -t nat -A OUTPUT -p tcp -s 10.137.2.1 --sport 9105 -j DNAT --to-destination 10.137.255.254:8082
#iptables -t nat -A PREROUTING -p tcp -d 127.0.0.1 --dport 8082 -j DNAT --to-destination 10.137.255.254:8082

#iptables -t nat -A PREROUTING -p tcp -d 127.0.0.1 --dport 8082 -j DNAT --to-destination 10.137.255.254
#iptables -t nat -A PREROUTING -p tcp -d 10.137.2.21 --dport 8082 -j DNAT --to-destination 10.137.255.254
#iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 --dport 8082 -j DNAT --to-destination 10.137.255.254
#iptables -t nat -A OUTPUT -p tcp -d 10.137.2.21 --dport 8082 -j DNAT --to-destination 10.137.255.254

# Works
# localhost/loopback maps localhost port 8082 to localhost port 8888
#iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 8082 -j REDIRECT --to-ports 8888

# iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 8082 -j DNAT --to-destination 10.137.255.254:8082
#iptables -t nat -A PREROUTING --dst 127.0.0.1 -p tcp --dport 8082 -j DNAT --to-destination 10.137.255.254:8082 
#iptables -t nat -A PREROUTING --dst 10.137.2.1 -p udp --dport 53 -j DNAT --to-destination 10.137.255.254:8082 
#iptables -t nat -A OUTPUT -p udp -d 10.137.2.1 --dport 52 -j DNAT --to-destination 10.137.255.254:8082

# Remap ALL traffic
#iptables -t nat -A OUTPUT -p tcp -j DNAT --to-destination 10.137.255.254:8082
#iptables -t nat -A OUTPUT -p udp -j DNAT --to-destination 10.137.255.254:8082
    

#iptables -t nat -A PREROUTING --dst 10.137.2.1 -p udp --dport 53 -j REDIRECT --to-port 9105
#iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 53 -j REDIRECT --to-ports 9105
#iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 53 -j REDIRECT --to-ports 9105

#iptables -v -L
#iptables -v -t nat -L
#telnet 127.0.0.1 9105
#telnet 10.137.2.1 8082
#telnet 127.0.0.1 8082
#tail -100 /var/log/kern.log
