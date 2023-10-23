#!/bin/bash

# " Date August 2012
# " Author : Guillaume Kaddouch
# " URL : http://networkfilter.blogspot.com
# " Version : Advanced 1.0

echo "Setting up variables"
# VARIABLES TO CUSTOMISE TO MATCH YOUR NETWORK
LAN="eth0"
LAN_SUBNET="192.168.1.0/24"
DHCP_RANGE="192.168.1.10-192.168.1.20"
DNS_SERVER1="8.8.8.8"
DNS_SERVER2="208.67.222.222"
RSS="192.168.1.3"
MODEM_ROUTER="192.168.1.1"
UNPRIV_PORTS="1024:65535"
SSH="15507"
NTP_SERVER="65.55.21.22"

echo "Flushing existing chains and rules..."
# FLUSHING CHAINS & RULES
iptables -t filter -F
iptables -t filter -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

echo "Setting up default policies"
# DEFAULT POLICIES
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# LOOPBACK
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

echo "Creating chains"
# CHAINS
iptables -N FORWARD_OUT
iptables -N FORWARD_IN
iptables -N LAN_IN
iptables -N LAN_BROADCAST
iptables -N GATEWAY_LAN
iptables -N GATEWAY_BROADCAST
iptables -N GATEWAY_INTERNET
iptables -N INTERNET_GATEWAY
iptables -t nat -N NAT_OUT

# CHAIN TO CHECK, LOG, AND OPTIMISE
iptables -N CHECK_TCP_FLAGS
iptables -N LOGDROP_TCP_FLAGS
iptables -N LOGDROP_MALWARE
iptables -N LOGDROP_BADPORT
iptables -t mangle -N FAST_DNS

echo "Loading rules"

#################################
# PROTOCOL CHECK & OPTIMIZATION #
##############################################################################################
iptables -A FORWARD -i $LAN -p tcp --ipv4 -j CHECK_TCP_FLAGS
iptables -A INPUT -i $LAN -p tcp --ipv4 -j CHECK_TCP_FLAGS

iptables -t mangle -A OUTPUT -o $LAN -p tcp --ipv4 -s $RSS -m pkttype --pkt-type unicast --dport domain -m \
state --state NEW,ESTABLISHED,RELATED -j FAST_DNS

iptables -t mangle -A OUTPUT -o $LAN -p udp --ipv4 -s $RSS -m pkttype --pkt-type unicast --dport domain -m \
state --state NEW,ESTABLISHED,RELATED -j FAST_DNS
##############################################################################################

###################
# CHECK_TCP_FLAGS #
##############################################################################################
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags ACK,FIN FIN -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags ACK,PSH PSH -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags ACK,URG URG -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags FIN,RST FIN,RST -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags SYN,FIN SYN,FIN -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags SYN,RST SYN,RST -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags ALL ALL -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags ALL NONE -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags ALL FIN,PSH,URG -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j LOGDROP_TCP_FLAGS
iptables -A CHECK_TCP_FLAGS -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j LOGDROP_TCP_FLAGS

iptables -A LOGDROP_TCP_FLAGS -m limit --limit 1/s -j LOG --log-tcp-options --log-prefix \
"[IPTABLES: BAD TCP FLAGS]"

iptables -A LOGDROP_TCP_FLAGS -j DROP
##############################################################################################

############
# FAST_DNS #
##############################################################################################
iptables -t mangle -A FAST_DNS -p udp -d $DNS_SERVER1 -j TOS --set-tos Minimize-Delay
iptables -t mangle -A FAST_DNS -p udp -d $DNS_SERVER2 -j TOS --set-tos Minimize-Delay
iptables -t mangle -A FAST_DNS -p tcp -d $DNS_SERVER1 -j TOS --set-tos Minimize-Delay
iptables -t mangle -A FAST_DNS -p tcp -d $DNS_SERVER2 -j TOS --set-tos Minimize-Delay
##############################################################################################

# FLOW IDENTIFICATION #
source "/etc/firewall.flows"

############
# NAT_OUT #
##############################################################################################
iptables -t nat -A NAT_OUT -j MASQUERADE --random
##############################################################################################

###############
# FORWARD OUT #
##############################################################################################
# Potential Malware traffic
# If not dropped here, they would have been blocked by the default policy
# However, we take the opportunity to save them in a "bad_traffic" table
# This table enables us to block LAN's hosts trying to access too many malware ports
# Thus being potentially infected (and requiring an antivirus analysis)
#
# As soon as a LAN host has hit 5 times rules below within 2mn, DROP all forward out from that host
iptables -A FORWARD_OUT -p tcp -m recent --name bad_traffic --rcheck --rttl --hitcount 5 --seconds 120 -j \
LOGDROP_MALWARE

iptables -A FORWARD_OUT -p tcp --dport 139 -m recent --name bad_traffic --set -j LOGDROP_BADPORT
iptables -A FORWARD_OUT -p tcp --dport 445 -m recent --name bad_traffic --set -j LOGDROP_BADPORT
iptables -A FORWARD_OUT -p tcp --dport 135 -m recent --name bad_traffic --set -j LOGDROP_BADPORT
iptables -A FORWARD_OUT -p tcp --dport 6667 -m recent --name bad_traffic --set -j LOGDROP_BADPORT
iptables -A FORWARD_OUT -p tcp --dport 1433:1434 -m recent --name bad_traffic --set -j LOGDROP_BADPORT
iptables -A FORWARD_OUT -p udp --dport 1433:1434 -m recent --name bad_traffic --set -j LOGDROP_BADPORT
iptables -A LOGDROP_BADPORT -m limit --limit 1/s -j LOG --log-prefix "[IPTABLES: BAD PORT]"
iptables -A LOGDROP_BADPORT -j DROP
iptables -A LOGDROP_MALWARE -m limit --limit 1/s -j LOG --log-prefix "[IPTABLES: INFECTED HOST]"
iptables -A LOGDROP_MALWARE -j DROP

# Allowed ports
iptables -A FORWARD_OUT -p tcp --sport $UNPRIV_PORTS -m multiport --dports ftp,http,https,8080 -j ACCEPT

# Allow ESTABLISHED and RELATED connections to other ports, required for FTP for instance
iptables -A FORWARD_OUT -p tcp --sport $UNPRIV_PORTS --dport $UNPRIV_PORTS -m state --state \
ESTABLISHED,RELATED -j ACCEPT

# NTP Requests (modify the variable at the begining)
iptables -A FORWARD_OUT -p udp -d $NTP_SERVER --sport ntp --dport ntp -j ACCEPT

# Echo request
iptables -A FORWARD_OUT -p icmp -m icmp --icmp-type echo-request -j ACCEPT

# Reject traffic we do not want, many options below (create the corresponding variables)
# iptables -A FORWARD_OUT -p tcp --dport $port_of_a_host_to_block -j REJECT --reject-with \
# icmp-host-prohibited
# iptables -A FORWARD_OUT -d $subnet_to_block -j REJECT --reject-with icmp-net-prohibited

# Block & Log everything else
iptables -A FORWARD_OUT -m limit --limit 1/s -j LOG --log-prefix "[IPTABLES: FORWARD_OUT]"
iptables -A FORWARD_OUT -j DROP
##############################################################################################

##############
# FORWARD_IN #
##############################################################################################
# Allow forwarding of incoming established or related flows, with a TTL > 10
iptables -A FORWARD_IN -m ttl --ttl-gt 10 -j ACCEPT

# Block & Log everything else
iptables -A FORWARD_IN -m limit --limit 1/s -j LOG --log-prefix "[IPTABLES: FORWARD_IN]"
iptables -A FORWARD_IN -j DROP
##############################################################################################

##########
# LAN_IN #
##############################################################################################
# Allow DHCP broadcasts from the inside
iptables -A LAN_IN -i $LAN -p udp --sport 67:68 --dport 67:68 -j ACCEPT

# Allow DNS queries from the LAN to the Raspberry Security Syste,
iptables -A LAN_IN -i $LAN -p udp --sport $UNPRIV_PORTS --dport 53 -j ACCEPT
iptables -A LAN_IN -i $LAN -p tcp --sport $UNPRIV_PORTS --dport 53 -j ACCEPT

# SSH connections
# (you may add a check for the remote OS)
iptables -A LAN_IN -i $LAN -p tcp --sport $UNPRIV_PORTS --dport $SSH -j ACCEPT

# ICMP LAN (Type 3 = unreachable [destination|port|protocol])
iptables -A LAN_IN -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A LAN_IN -p icmp -m icmp --icmp-type 3 -j ACCEPT

# Block & Log everything else
iptables -A LAN_IN -m limit --limit 1/s -j LOG --log-prefix "[IPTABLES: LAN_IN]"
iptables -A LAN_IN -j DROP
##############################################################################################

##################
# LAN_BROADCAST #
##############################################################################################
# Allow DHCP broadcasts from the inside
iptables -A LAN_BROADCAST -i $LAN -p udp --sport 67:68 --dport 67:68 -j ACCEPT
# Block everything else (do not bother to log broadcast traffic)
iptables -A LAN_BROADCAST -j DROP
##############################################################################################

###########################
# INTERNET_GATEWAY #
##############################################################################################
# Allow already established connections from RSS to Internet to come back to RSS
iptables -A INTERNET_GATEWAY -p all -j ACCEPT
##############################################################################################

########################
# CHAINE GATEWAY_LAN #
##############################################################################################
# Block potential ICMP redirect sent from us (could be caused by a misconfigured sysctl)
iptables -A GATEWAY_LAN -p icmp -m icmp --icmp-type redirect -m limit --limit 1/s -j LOG --log-prefix \
"[IPTABLES: ICMP REDIRECT]"

iptables -A GATEWAY_LAN -p icmp -m icmp --icmp-type redirect -j DROP

# Allow LAN established connections to Raspberry to come back to the LAN
iptables -A GATEWAY_LAN -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A GATEWAY_LAN -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A GATEWAY_LAN -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DHCP related traffic
iptables -A GATEWAY_LAN -p udp --sport 67:68 --dport 67:68 -j ACCEPT

# Allow Raspi to ping the LAN
iptables -A GATEWAY_LAN -p icmp -m icmp --icmp-type echo-request -m state --state NEW -j ACCEPT

# Block & Log everything else
iptables -A GATEWAY_LAN -m limit --limit 1/s -j LOG --log-prefix "[IPTABLES: GATEWAY_LAN]"
iptables -A GATEWAY_LAN -j DROP
##############################################################################################

#####################
# GATEWAY_BROADCAST #
##############################################################################################
# Allow broadcast DHCP replies from RSS
iptables -A GATEWAY_BROADCAST -p udp --sport 67:68 --dport 67:68 -j ACCEPT

# Block & Log everything else
iptables -A GATEWAY_BROADCAST -m limit --limit 1/s -j LOG --log-prefix "[IPTABLES: GATEWAY_BROADCAST]"
iptables -A GATEWAY_BROADCAST -j DROP
##############################################################################################

####################
# GATEWAY_INTERNET #
##############################################################################################
# Allow new connections from Raspberry (necessary for updates, installing packages, etc...)
# I do not run updates the night, consequently there is no need for the rule to be active 24/24
iptables -A GATEWAY_INTERNET -p tcp -m multiport --dports ftp,http,https -m time --timestart 09:00 --timestop \
23:00 -j ACCEPT

# Résolutions DNS
iptables -A GATEWAY_INTERNET -p udp --sport $UNPRIV_PORTS -d $DNS_SERVER1 --dport domain -j ACCEPT
iptables -A GATEWAY_INTERNET -p udp --sport $UNPRIV_PORTS -d $DNS_SERVER2 --dport domain -j ACCEPT
iptables -A GATEWAY_INTERNET -p tcp --sport $UNPRIV_PORTS -d $DNS_SERVER1 --dport domain -j ACCEPT
iptables -A GATEWAY_INTERNET -p tcp --sport $UNPRIV_PORTS -d $DNS_SERVER2 --dport domain -j ACCEPT

# Happens when reloading firewall rules
iptables -A GATEWAY_INTERNET -p icmp -m icmp --icmp-type port-unreachable -d $DNS_SERVER1 -j DROP
iptables -A GATEWAY_INTERNET -p icmp -m icmp --icmp-type port-unreachable -d $DNS_SERVER2 -j DROP

# Allow NTP
iptables -A GATEWAY_INTERNET -p udp --dport ntp -j ACCEPT

# Block & Log everything else
iptables -A GATEWAY_INTERNET -m limit --limit 1/s -j LOG --log-prefix "[IPTABLES: GATEWAY_INTERNET]"
iptables -A GATEWAY_INTERNET -j DROP
##############################################################################################

## RULES END ##
rules_number=`egrep '\-j' /etc/firewall.advanced | wc -l`
flows_number=`egrep '\-j' /etc/firewall.flows | wc -l`
total_rules=$(( rules_number+flows_number ))
echo ""
echo "$total_rules rules loaded."
echo ""