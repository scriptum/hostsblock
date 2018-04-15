#!/bin/sh

SCRIPT_PATH=$0
WHAT_TODO=$1

NAME=hostsblock
VER="2.0.0"
DESC="blocking manager"

HOSTS=/etc/hosts
HOSTS_BACKUP=/etc/hosts.bak
BIN_SCRIPT=/usr/bin/$NAME
CRON_DIR=/etc/cron.weekly
UPDATER=$CRON_DIR/$NAME
BLOCKLIST=/etc/hosts.blocklist
WHITELIST=/etc/hosts.whitelist
URL=https://raw.githubusercontent.com/scriptum/hostsblock/master/hostsblock.sh
BEGIN_ANCHOR="# BEGIN ${NAME^^} ANCHOR, DO NOT EDIT THIS!"
END_ANCHOR="# END ${NAME^^} ANCHOR"


[ -z $EDITOR ] && EDITOR="vim"

if tty -s; then
  dbg() {
    echo "$@"
  }
else
  dbg(){
    :
  }
fi

reset_blocklist() {
  cat > $BLOCKLIST <<EOF
http://winhelp2002.mvps.org/hosts.txt
https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt
https://adaway.org/hosts.txt
http://someonewhocares.org/hosts/hosts
https://mirror.cedia.org.ec/malwaredomains/immortal_domains.txt
https://hosts-file.net/ad_servers.txt
https://mirror.cedia.org.ec/malwaredomains/justdomains
https://www.malwaredomainlist.com/hostslist/hosts.txt
http://hosts-file.net/.%5Cad_servers.txt
http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt
EOF
  #put this because yandex maps now works only with yastatic.net
  cat > $WHITELIST <<EOF
yastatic.net
EOF
}

hosts_clean() {
  sed -i "/$BEGIN_ANCHOR/,/$END_ANCHOR/d" $HOSTS
}

hosts_inject() {
  hosts_clean
  {
    echo "$BEGIN_ANCHOR"
    get_blocklist
    echo "$END_ANCHOR"
  } >> $HOSTS
}

remove() {
  check_root
  if [ -f $BIN_SCRIPT ]; then
    if [ -f /etc/hosts.orig ]; then
      mv -f /etc/hosts.orig $HOSTS
    fi
  fi
  rm -f $UPDATER $BIN_SCRIPT $BLOCKLIST 2> /dev/null
}

bug_report() {
  dbg 'Report here if the problem occurs again:' >&2
  dbg 'https://github.com/scriptum/hostsblock/issues' >&2
}

get_blocklist() {
  dbg "Updating the blocked list..." >&2
  TMP=$(mktemp)

  sed "/^$/d" $BLOCKLIST | while read line; do
    dbg "Processing $line..." >&2
    if ! curl -s "$line" >> "$TMP"; then
      dbg "Error while downloading '$line'" >&2
      dbg "Check your connection." >&2
      bug_report
    fi
  done

  # - remove localhost and broadcasthost strings
  grep -vw 'localhost|broadcasthost' "$TMP" | \
  # - keep only IP
  grep '^[01]' | \
  # - remove IP and comments (extract hosts only)
  sed -e 's/^[0127]*.0.0.[01]\s//' -e 's/#.*//' | \
  # - remove whitespaces, one host per line
  tr -d '\r' | tr ' \t' '\n' | \
  # - sort, remove duplicates
  grep -v ^$ | sort -u | grep -Fvxf $WHITELIST | \
  # - awk magic - optimize hosts size using aliases (max len = 160, max aliases = 9)
  awk '
    BEGIN {
      z=s="0.0.0.1"
    }
    {
      if(length(s) + length($1) > (160 - 1) || cnt >= 9) {
        print s;
        cnt=1;
        s=z " " $1
      } else {
        s=s " " $1;
        cnt++
      }
    }
    END {
      print s
    }'
}

on() {
  check_root
  dbg 'Turning on...'
  hosts_inject
}

off() {
  check_root
  dbg 'Turning off...'
  hosts_clean
}

install_updater() {
  cat > $UPDATER <<EOF
#!/bin/sh
if curl -s $URL > $BIN_SCRIPT; then
  $NAME update
fi
EOF
  chmod +x $UPDATER
}

install() {
  check_root
  dbg "Backup of your current hosts saved here: $HOSTS_BACKUP"
  cp -f $HOSTS $HOSTS_BACKUP
  if [ -f $BIN_SCRIPT ]; then
    dbg "Updating $NAME ..."
    dbg 'Removing old version...'
    remove
  else
    dbg "Installing $NAME ..."
  fi

  cp -f "$SCRIPT_PATH" $BIN_SCRIPT
  chmod +x $BIN_SCRIPT

  reset_blocklist
  hosts_inject

  dbg "Creating a script for auto-updating the list of blocked hosts..."
  install_updater
}

update() {
  check_root
  hosts_inject
  install_updater
}

is_enabled() {
  grep -Fxqcm1 "$BEGIN_ANCHOR" $HOSTS
}

version() {
  awk -F'"' '/^VER/{print $2}' $BIN_SCRIPT
}

check_root() {
  if [ "$USER" != "root" ]; then
    echo "You need to be root to perform this command." 1>&2
    echo "Run: \"sudo $SCRIPT_PATH\"" 1>&2
    exit 1
  fi
}

case $WHAT_TODO in
  remove)
    remove
    ;;
  update)
    if is_enabled; then
      update
    else
      echo "Error: $NAME has to be turned on before updating the blocklist" 1>&2
      exit 1
    fi
    ;;
  on | start)
    if is_enabled; then
      echo "Already turned on"
    else
      on
    fi
    ;;
  off | stop)
    if is_enabled; then
      off
    else
      echo "Already turned off"
    fi
    ;;
  status)
    if is_enabled; then
      echo "$NAME is turned on"
    else
      echo "$NAME is turned off"
    fi
    ;;
  edit)
    $EDITOR $HOSTS
    ;;
  whitelist)
    $EDITOR $WHITELIST
    ;;
  install)
    install
    ;;
  version | -v | --version)
    echo "Current installed version is: $(version)"
    ;;
  *)
    cat <<EOF
Usage: $(basename "$SCRIPT_PATH") COMMAND
${DESC^} for removing ads using system hosts file (root required)

Description of COMMANDS:
  install      install $DESC with cron auto-updater
  on | start   turn on $DESC
  off | stop   turn off $DESC
  edit         edit /etc/hosts using \$EDITOR
  remove       uninstall this sctipt
  status       find out the current status
  update       update the list of blocked hosts
  whitelist    edit whitelist (domains you don't want to block)
  version      output version of installed $DESC and exit
  help         display this help and exit
EOF
    ;;
esac
