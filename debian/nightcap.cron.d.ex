#
# Regular cron jobs for the nightcap package
#
0 4	* * *	root	[ -x /usr/bin/nightcap_maintenance ] && /usr/bin/nightcap_maintenance
