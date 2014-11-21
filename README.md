TL;DR: Download and run `sudo ./hostsblock.sh`.

### What is it?

Alternative way to remove ads from websites. Of course you may use AdBlock
or something but:

1. AdBlock consumes MUCH memory (sometimes up to 50 Mb per tab (!) with Firefox) 
   due to compiling huge CSS table. /etc/hosts does no such damage for your
   system.
2. AdBlock works with only few popular web-browsers. /etc/hosts works
   system-wide including instant messengers, mail/rss clients and so on.
3. AdBlock doesn't prevent loading ads content. /etc/hosts blocks entire domain 
   and saves your traffic.

Unfortunately /etc/hosts cannot block content by id, path or tag name like CSS
does. I recommend to use it with NoScript extension that disables JavaScript
by default. After that you will block 99% of annoying advertisements.

### Installing & Updating

Download latest version and run `sudo ./hostsblock.sh`.

### More infromation in help

`sudo hostsblock help`

### Notes

It will replace /etc/hosts and update it every week. So you haven't edit it by hand. Instead use `hostsblock edit`.

### How it works

This is a script designed to be as simple as possible that does following:

1. Makes copy of your original /etc/hosts as /etc/hosts.orig. Now you should
   edit /etc/hosts with help of command `sudo hostsblock edit`.
2. Installs /usr/bin/hostsblock script with help of which you can manage the hostsblock.
3. Creates cron job that updates ads list and generate new /etc/hosts weekly.

