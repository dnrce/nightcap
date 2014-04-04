#!/bin/bash
# nightcap, a utility to put an idle server to sleep
# Copyright (C) 2014 Daniel Rice
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

TIMEOUT=300

pre_sleep () {
  ssh -q 192.168.0.18 "iptables -A FORWARD -p udp -d 192.168.0.32 --dport 43971 -j DROP"
}

post_sleep () {
  ssh -q 192.168.0.18 "iptables -D FORWARD -p udp -d 192.168.0.32 --dport 43971 -j DROP"
}

# utility functions to make the logic easier to read
safe_to_sleep() {
  UNCLEAN_RAID_DEVICES=$(mdadm --detail /dev/md* | grep '^\s*State : ' | grep -v clean | wc -l)
  if [[ "$UNCLEAN_RAID_DEVICES" -gt "0" ]]; then
    log "Unclean RAID device(s)"
    return 1
  fi

  NUM_USERS_LOGGED_IN=$(who -q | tail -n1 | grep -o "[0-9]*")
  if [[ "$NUM_USERS_LOGGED_IN" -gt "0" ]]; then
    log "Active user session(s)"
    return 1
  fi

  NUM_ACTIVE_CONNECTIONS=$(netstat -np --inet | tail -n +3 | grep -v "127\.0\.0\.1\|transmission-d$" | wc -l)
  if [[ "$NUM_ACTIVE_CONNECTIONS" -gt "0" ]]; then
    log "Connections are active"
    return 1
  fi

  return 0
}

log() {
  echo "$(date) $1"
}

reset_timer() {
  date +%s > /root/idler/timestamp
}

timed_out() {
  current=$(date +%s)
  last=$(cat /root/idler/timestamp)
  [[ "$((current-last))" -gt "$TIMEOUT" ]]
}

# main program logic
while true; do
  if safe_to_sleep; then
    if timed_out; then
      log "Sleeping..."
      pre_sleep
      /usr/sbin/pm-suspend
      log "Woke up."
      reset_timer
      post_sleep
    fi
  else
    reset_timer
  fi
  sleep 30s
done
