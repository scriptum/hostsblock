TL;DR: download and run `hostsblock-setup.sh` as root.

Alternative way to remove ads from websites. Of course you may use AdBlock or something but:

1. AdBlock consumes MUCH memory (at least 50 Mb per tab (!) with Firefox) due to compiling huge CSS table. /etc/hosts does no damage for your system.
2. AdBlock works with only few popular web-browsers, /etc/hosts works system-wide.
3. AdBlock doesn't prevent loading ads content. /etc/hosts blocks entire domain 
   and saves your traffic.

This is a very simple script that does following:

1. Makes copy of your original /etc/hosts as /etc/hosts.orig. Now you should
   edit /etc/hosts.orig instead of /etc/hosts.
2. Installs /usr/bin/hostsblock-update script that allows you to keep your hosts
   up to date.
3. Creates cron job that updates ads list from winhelp2002.mvps.org/hosts.txt
   weekly (see /etc/cron.weekly).

Note: after editing /etc/hosts.orig you should run `hostsblock-update`.
