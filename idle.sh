#!/bin/bash

pre_sleep () {
  ssh -q 192.168.0.18 "iptables -A FORWARD -p udp -d 192.168.0.32 --dport 43971 -j DROP"
}

post_sleep () {
  ssh -q 192.168.0.18 "iptables -D FORWARD -p udp -d 192.168.0.32 --dport 43971 -j DROP"
}

# collect data on system activity
NUM_USERS_LOGGED_IN=$(who -q | tail -n1 | grep -o "[0-9]*")
NUM_ACTIVE_CONNECTIONS=$(netstat -np --inet | tail -n +3 | grep -v "127\.0\.0\.1\|transmission-d$" | wc -l)

if [[ "$NUM_ACTIVE_CONNECTIONS" == "0" ]]; then
  pre_sleep
  /usr/sbin/pm-suspend
  post_sleep
else
  echo "$(date) -- $NUM_ACTIVE_CONNECTIONS active connections" >> /root/idler/idler.log
fi
