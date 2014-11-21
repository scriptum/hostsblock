#!/bin/bash

script_path=$0
what_todo=$1
param2=$2

VER="1.2"
DESC="blocking manager"

HOSTS_ORIG=/etc/hosts.orig
HOSTS=/etc/hosts
HOSTS_SAVED=/etc/hosts.save
SCRIPTNAME=hostsblock
BIN_SCRIPT=/usr/bin/$SCRIPTNAME
CRON_DIR=/etc/cron.weekly
UPDATER=$CRON_DIR/$SCRIPTNAME
BLOCKLIST=/etc/hosts.blocklist

if [ "$EDITOR" = "" ]; then
  EDITOR="vim"
fi

reset_blocklist() {
echo "
http://winhelp2002.mvps.org/hosts.txt
https://jansal.googlecode.com/svn/trunk/adblock/hosts
http://hosts-file.net/.%5Cad_servers.txt
http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
" > $BLOCKLIST
sed -i "/^$/d" $BLOCKLIST
}

remove() {
  echo "Removing $SCRIPTNAME ..."
  rm -f $UPDATER &> /dev/null
  rm -f $BIN_SCRIPT &> /dev/null
  rm -f $BLOCKLIST &> /dev/null
  if [ -f "$HOSTS_ORIG" ]; then
    mv $HOSTS_ORIG $HOSTS
    sed -i "/$SCRIPTNAME/d" $HOSTS
  fi
}

update_blocklist() {
  echo "Updating the blocked list..."
  echo "### DO NOT EDIT THIS FILE! INSTEAD RUN \"sudo $SCRIPTNAME\" ###" > $HOSTS
  cat $HOSTS_ORIG | grep -v $SCRIPTNAME >> $HOSTS

  # - load all lists
  # - remove localhost and broadcasthost strings
  # - keep only IP
  # - remove IP and comments (extract hosts only)
  # - remove whitespaces, one host per line
  # - sort, remove duplicates
  # - awk magic - optimize hosts size using aliases (max len = 160, max aliases = 9)
  cat $BLOCKLIST | while read line; do
    curl -s $line | grep -vw localhost\|broadcasthost | grep ^[01] | sed -e 's/^[0127]*.0.0.[01]\s//' -e 's/#.*//' | tr -d '\r' | tr ' \t' '\n' | grep -v ^$ | sort -u | awk 'BEGIN{z=s="0.0.0.0"}{if(length(s)+length($1)>(160-1)||cnt>=9){print s;cnt=1;s=z " " $1}else{s=s " " $1;cnt++}}END{print s}' >> $HOSTS
  done
}

on() {
  echo "Turning on..."
  mv $HOSTS $HOSTS_ORIG
  sed -i "1s/^/### DO NOT EDIT THIS FILE! INSTEAD RUN \"sudo $SCRIPTNAME\" ###\n/" $HOSTS_ORIG
  update_blocklist
}

off() {
  echo "Turning off..."
  mv $HOSTS $HOSTS_SAVED
  mv $HOSTS_ORIG $HOSTS 
  sed -i "/$SCRIPTNAME/d" $HOSTS
  sed -i '/^$/d' $HOSTS
}

install() {
  echo "Installing $SCRIPTNAME ..."

  echo "Removing old version..."
  remove

  cp -f  $script_path $BIN_SCRIPT
  chmod +x $BIN_SCRIPT

  reset_blocklist
  on

  echo "Creating a script for auto-updating the list of blocked hosts..."
  echo "
  #!/bin/bash
  $SCRIPTNAME update " > $UPDATER
  chmod +x $UPDATER
}

status() {
  if [ -f $HOSTS_ORIG ]; then
    return 1
  else
    return 0
  fi
}

version() {
  grep -m 1 'VER' $BIN_SCRIPT | sed "s/^.*\=//" | sed "s/\"//g"
}

check() {
  if [ $(whoami) != "root" ]; then
    echo "You should be root to perform this command."
    echo -e "Run: \"sudo $script_path \" \n"
    exit -1
  fi

  if [ ! -f $BIN_SCRIPT ]; then 
    printf "$SCRIPTNAME is not installed. Do you want to install it? (y/n) "
    read answer
    if [[ "$answer" != "y" && "$answer" != "yes" ]]; then
      exit 1
    else
      # for updating from v. 1.0
      if [ -f /usr/bin/hostsblock-update ]; then
        rm -f /etc/cron.weekly/hostsblock-update
        rm -f /usr/bin/hostsblock-update
        if [ -f /etc/hosts.orig ]; then
          sed -i "/hostsblock-update/d" /etc/hosts.orig
          mv /etc/hosts.orig /etc/hosts
        fi
      fi

      install
    fi
  else
    VER_installed=`version`
    if [[ "$VER_installed" != "$VER" ]]; then

      if [[ "$VER_installed" > "$VER" ]]; then
        echo -e "Error: You have $SCRIPTNAME v.$VER_installed . Version of the started instance is $VER"
        echo -e "If you want to do smth run \"sudo $SCRIPTNAME\""
        exit 1
      else
        printf "Do you want to update? V.$VER_installed --> v.$VER (y/n) "
        read answer
        if [[ $answer != "y" && $answer != "yes" ]]; then
          exit 1
        fi
      fi
      install
    fi
  fi

}

check

case $what_todo in
  remove)
    remove
    ;;
  update)
    status
    if [ $? = "1" ]; then
      update_blocklist
    else  
      echo "Error: $SCRIPTNAME has to be turned on before updating the blocklist"
      exit 1
    fi
    ;;
	on | start)
    status
    if [ $? = "0" ]; then
      on	
    fi
		;;
	off | stop)
    status
    if [ $? = "1" ]; then
      off
    fi
		;;
	status)
    status
    if [ $? = "1" ]; then
      echo "$SCRIPTNAME is turned on"
    else
      echo "$SCRIPTNAME is turned off"
    fi
		;;
  edit)
    status
    if [ $? = "1" ]; then
      off
      $EDITOR $HOSTS
      on
    else
      $EDITOR $HOSTS
    fi
    ;;
  version | -v | --version)
    echo "Current installed version is:" `version`
    ;;
	help | --help | h | -h)
		echo -e "
$SCRIPTNAME --sites $DESC
\ton\t--turn on $DESC
\toff\t--turn off $DESC
\tupdate\t--update the list of blocked hosts
\tstatus\t--find out the current status
\tremove\t--remove
\tedit\t--edit /etc/hosts
\tversion\t--find out version
"
		;;
	*)
		echo "Usage: $script_path { on | off | update | status | remove | edit | version | help }"
		exit 1
		;;
esac



