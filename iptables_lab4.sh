iptables -A FORWARD –s 10.20.111.2 -i eth0 -d 10.10.111.0/24 –j ACCEPT

#0) Enable iptables logging of all traffic between the networks 10.10.111.0/24 and 10.20.111.0/24, and to/from the internal-router.
iptables -A FORWARD -s 10.20.111.0/24 -d 10.10.111.0/24 -j LOG --log-prefix "10.20.111.0 to 10.10.111.0: " --log-level 6
iptables -A FORWARD -s 10.10.111.0/24 -d 10.20.111.0/24 -j LOG --log-prefix "10.10.111.0 to 10.20.111.0: " --log-level 6
iptables -A INPUT -s 10.10.111.0/24 -d 10.10.111.2 -m state --state NEW,ESTABLISHED,RELATED -j LOG --log-prefix "Inbound to internal router: " --log-level 6
iptables -A OUTPUT -s 10.10.111.2 -d 10.10.111.0/24 -m state --state NEW,ESTABLISHED,RELATED -j LOG --log-prefix "Outbound to 10.10.111.0/24: " --log-level 6
# log level 4 is the system default, but we adjust the log level to KERN_INFO so that informational messages that require no action are included in the log at /var/log/kern.log

# 0 (KERN_EMERG) The system is unusable.
# 1 (KERN_ALERT) Actions that must be taken care of immediately.
# 2 (KERN_CRIT) Critical conditions.
# 3 (KERN_ERR) Non-critical error conditions.
# 4 (KERN_WARNING) Warning conditions that should be taken care of.
# 5 (KERN_NOTICE) Normal, but significant events.
# 6 (KERN_INFO) Informational messages that require no action.
# 7 (KERN_DEBUG) Kernel debugging messages, output by the kernel if the developer enabled debugging at compile time.


#1) [10 pts] The internal machine (10.20.111.2) should respond to a ping from 10.10.111.0/24.
#ICMP rules for standard request and echo reply (other message types like destination unreachable and time exceeded are filtered)
iptables -A FORWARD -p icmp --icmp-type 8 -s 10.10.111.0/24 -i eth0 -d 10.20.111.2 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type 0 -s 10.20.111.2 -i eth1 -d 10.10.111.0/24 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

#2) [20 pts] The internal machine (10.20.111.2) should accept all incoming SSH and SMTP (TCP 25) requests from 10.10.111.0/24. Hint: You can test SMTP by using the following netcat command: “nc [IP] 25” then type “HELO”.
#SSH rules
iptables -A FORWARD -p tcp -s 10.10.111.0/24 -sport 1024:65635 -i eth0 -d 10.20.111.2 -dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p tcp -s 10.20.111.2 -sport 22 -d 10.10.111.0/24 -dport 1024:65635 -i eth1 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

#SMTP rules
iptables -A FORWARD -p tcp --sport 25 -d 10.10.111.0/24 -i eth1 -dport 1024:65635 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p tcp -d 10.20.111.2 --dport 25 -s 10.10.111.0/24 -sport 1024:65635 -i eth0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT


#3) [20 pts] The internal machine should be able to perform a nslookup of fakebook.vlab.local
iptables -A FORWARD -p udp -m udp -d 10.20.111.2 --dport 1024:65635 -s 10.13.1.10 --sport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p udp -m udp -s 10.20.111.2 --sport 1024:65635 -d 10.13.1.10 --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT


#4) [30 pts] The internal router should accept pings from the Kali machine only. Note: The internal router has two IP addresses. Use the IP on the 10.10.111.x network. As the internalrouter uses DHCP, obtain the IP address for the rule dynamically.
# Accepts all ICMP echo packets from the Kali machine (10.10.111.100) directed at eth0 on the internal router--the interface attached to the 10.10.111.0/24 segment.
iptables -A INPUT -p icmp --icmp-type 8 -s 10.10.111.100 -d $(/sbin/ifconfig eth0 | grep -P '(10.10.111.\d{3})' | cut -c 14-26) -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type 0 -s $(/sbin/ifconfig eth0 | grep -P '(10.10.111.\d{3})' | cut -c 14-26) -d 10.10.111.100 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

iptables --policy INPUT DROP
iptables --policy OUTPUT DROP
iptables --policy FORWARD DROP