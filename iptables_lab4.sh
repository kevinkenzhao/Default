iptables -A FORWARD –s 10.20.111.0/24 -i eth0 -d 10.10.111.0/24 –j ACCEPT

#0) Enable iptables logging of all traffic between the networks 10.10.111.0/24 and 10.20.111.0/24, and to/from the internal-router.
iptables -A FORWARD -s 10.20.111.0/24 -d 10.10.111.0/24 -j LOG --log-level 4
iptables -A FORWARD -s 10.10.111.0/24 -d 10.20.111.0/24 -j LOG --log-level 4
iptables -A INPUT -s 10.10.111.0/24 -d 10.20.111.1 -m state --state NEW,ESTABLISHED,RELATED -j LOG --log-level 4
iptables -A OUTPUT -s 10.20.111.1 -d 10.10.111.0/24 -m state --state NEW,ESTABLISHED,RELATED -j LOG --log-level 4

#1) [10 pts] The internal machine (10.20.111.2) should respond to a ping from 10.10.111.0/24.



#SSH rules
iptables -A INPUT -p tcp -s 10.10.111.0/24 -sport 1024:65635 -d 0/0 -dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p tcp -sport 22 -d 10.10.111.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
#SMTP rules
iptables -A OUTPUT -p tcp --sport 25 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 587 -j ACCEPT
iptables -A INPUT -p tcp --dport 25 -j ACCEPT
iptables -A INPUT -p tcp --dport 587 -j ACCEPT

#ICMP rules for standard request and echo reply (other message types like destination unreachable and time exceeded are filtered)
iptables -A INPUT -p icmp --icmp-type 8 -s 0/0 -d 10.10.111.0/24 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type 0 -s 10.10.111.0/24 -d 0/0 -m state --state ESTABLISHED,RELATED -j ACCEPT

#4) [30 pts] The internal router should accept pings from the Kali machine only. Note: The internal router has two IP addresses. Use the IP on the 10.10.111.x network. As the internalrouter uses DHCP, obtain the IP address for the rule dynamically.
iptables -A INPUT -p icmp --icmp-type 8 -s 10.10.111.100 -d $(/sbin/ifconfig eth0 | grep -P '(10.10.111.\d{3})' | cut -c 14-26) -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type 0 -s $(/sbin/ifconfig eth0 | grep -P '(10.10.111.\d{3})' | cut -c 14-26) -d 10.10.111.100 -m state --state ESTABLISHED,RELATED -j ACCEPT

