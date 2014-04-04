#!/bin/bash

TIMEOUT=300

pre_sleep () {
  ssh -q 192.168.0.18 "iptables -A FORWARD -p udp -d 192.168.0.32 --dport 43971 -j DROP"
}

post_sleep () {
  ssh -q 192.168.0.18 "iptables -D FORWARD -p udp -d 192.168.0.32 --dport 43971 -j DROP"
}

# collect data on system activity
NUM_USERS_LOGGED_IN=$(who -q | tail -n1 | grep -o "[0-9]*")
NUM_ACTIVE_CONNECTIONS=$(netstat -np --inet | tail -n +3 | grep -v "127\.0\.0\.1\|transmission-d$" | wc -l)

# utility functions to make the logic easier to read
no_activity() {
  [[ "$NUM_ACTIVE_CONNECTIONS" == "0" ]]
}

reset_timer() {
  date +%s > /root/idler/timestamp
}

timed_out() {
  current=$(date +%s)
  last=$(cat /root/idler/timestamp)
  [[ "$((current-last))" -gt "$TIMEOUT" ]]
}

log_connections() {
  echo "$(date) -- $NUM_ACTIVE_CONNECTIONS active connections" >> /root/idler/idler.log
}

# main program logic
if no_activity; then
  if timed_out; then
    pre_sleep
    /usr/sbin/pm-suspend
    post_sleep
  fi
else
  reset_timer
  log_connections
fi
