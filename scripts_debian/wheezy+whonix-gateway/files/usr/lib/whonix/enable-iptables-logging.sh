#!/bin/bash

# Check /var/log/kern.log for logging results

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
