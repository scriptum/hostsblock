# Ad block using hosts file

## Installing

```
wget https://raw.githubusercontent.com/scriptum/hostsblock/master/hostsblock.sh
sudo ./hostsblock.sh install
```

This is suitable only for Unix-like systems.

## About

Alternative way to remove ads from websites. Of course you may use Add blocker
plugin for your web browser but there are disadvantages:

1. Ads blocking extensions consumes **much** CPU and RAM due to compilation of huge CSS table. Using `/etc/hosts` does not consumes your RAM because this is just plain text file.
2. `/etc/hosts` works system-wide including messengers, mail/rss clients.
3. Ads blocking extensions doesn't prevent loading ads content. `/etc/hosts` blocks entire domain and saves your traffic.

Unfortunately `/etc/hosts` cannot block content by id, path or tag name like CSS filter does. I recommend combine this script with extensions that block cross-domain JavaScript. Examples: NoScript, uMatrix. After that you will block 99% of annoying advertisements.

## More information

`sudo hostsblock help`

## How it works

This is a script designed to be as simple as possible that does following:

1. Makes backup of your original `/etc/hosts` to `/etc/hosts.bak` because original hosts will be modified. Don't worry, this script carefully handles all your manual hosts records.
1. Installs `/usr/bin/hostsblock` script to manage and update hosts file.
3. Creates updater script in `/etc/cron.weekly` that updates ads list and generate new `/etc/hosts`. It also checks this github page and updates script automatically, if new version is available.

### How does /etc/hosts works

Most magic is done by glibc. If some application (web browser etc) wants to download web page it checks DNS record first using glibc call `gethostbyname`. Before sending DNS request, glibc parses `/etc/hosts` and tries to find given host name. If record exists in `/etc/hosts`, it will overwrite DNS record of your ISP. If you add invalid IP address for some domain, e.g. like this:

```
0.0.0.0 an.yandex.ru
```

you will never get content from this domain. Glibc parses `/etc/hosts` every time someone calls `gethostbyname`, so it's important to keep `/etc/hosts` as small as possible for faster lookups. It doesn't waste system memory because of reading information from file, but waste CPU time, so using huge `/etc/hosts` list isn't good idea. Latest glibc versions parse hosts in optimized way.
