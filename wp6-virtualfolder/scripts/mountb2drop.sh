#!/usr/bin/env bash
# This scripts mounts {localpath} to {url} of webdav service.
# and configures proxy of http://localhost/{webdavuri} to use encoded auth
# Usage:
# - mountb2drop.sh [add|remove] [url] [localpath] [username] [password] [webdavuri]
# - where [alias] is name of subdirectroy under which the webdav is mounted
# Output:
# - {localpath} b2drop or other webdav is mounted using davfs2
# - {webdavuri} proxy configured to use user credentials passed to webdav server
#
# 24.05.2016 tomas - changed directory structure, all mounts will be subdir of 'work', comment owncloudcmd
# 31.01.2017 tomas - refactor, support multiuser, multiple webdav etc.

HTTPD_CONF="/etc/httpd/conf.d/000-default.conf"
HTTPD_SERVICE="httpd"

#VF_SKIP_APACHE_CONF=1 #will skip to proxy directly to b2drop or webdav - will go via davfs
VF_SKIP_APACHE_CONF=0


function checkproxy {
  if [ $http_proxy ]; then
    echo Checking Davfs2 proxy
    if grep -q "^proxy" /etc/davfs2/davfs2.conf ; then
       echo "proxy already set"
    else
       echo "proxy $http_proxy" | sudo tee -a /etc/davfs2/davfs2.conf > /dev/null
    fi
  fi
}

function checkargs {
  if [[ $1 == http* ]]; then
     echo url ok
  else
     echo url needs to be in form http:// or https://
     echo -$1:$2:$3:***:$5-
     help
     exit
  fi
  if [ -z $2 ]; then
     echo missing localpath needs to be set
     echo -$1:$2:$3:***:$5-
     help
     exit
  fi
  if [ -z $3 ]; then
     echo missing username needs to be set
     echo -$1:$2:$3:***:$5-
     help
     exit
  fi
  if [ -z $4 ]; then
     echo missing password/webdavuri needs to be set
     echo -$1:$2:$3:***:$5-
     help
     exit
  fi
  if [ -z $5 ]; then
     if [ $1 == "add" ];then
       echo missing webdavuri
       help
       exit
     fi
  fi
}
function addfstab {
  echo adding item to fstab [url] [localpath] $1 $2
  LOCALPATH=`readlink -f $2`
  if grep -q "$1 $LOCALPATH" /etc/fstab; then
    echo "already set"
  else
    echo "$1 $LOCALPATH davfs noauto,user,file_mode=666,dir_mode=777 0 0" | sudo tee -a /etc/fstab > /dev/null
  fi
}

function removefstab {
  echo removing [url] [localpath]
  grep -v "$1 $2" /etc/fstab > /tmp/fstab  && sudo mv /tmp/fstab /etc/fstab
}

function addsecrets {
  echo adding to secrets file
  mkdir -p ~/.davfs2
  touch ~/.davfs2/secrets
  if grep -q "$1 $2" ~/.davfs2/secrets; then
    echo "already set"
  else
    echo $1 $2 $3 | tee -a ~/.davfs2/secrets > /dev/null
  fi
  chmod go-rwx ~/.davfs2/secrets
}

function removesecrets {
  echo removing secrets
  grep -v "$1 $2" ~/.davfs2/secrets > /tmp/secrets && sudo mv /tmp/secrets ~/.davfs2/secrets
  chmod go-rwx ~/.davfs2/secrets
}

function addapacheproxy {
  removeapacheproxy $2
  if [ $VF_SKIP_APACHE_CONF == 1 ]; then
    echo Skipping apache proxy configuration - workaround for EUDAT issue 11169
  else
  SFILE2=/tmp/secrets2
  echo -n $3:$4 > $SFILE2
  if [ -e $SFILE2 ]; then
    AUTH="$(base64 -w 0 $SFILE2)"
    rm $SFILE2
    # hostname from the url in argument $1 is ${HOST[2]}, fix bug #24
    IFS="/";
    HOSTURL=( $1 )
    HOST=${HOSTURL[2]}
    echo $HOST
    IFS=" ";
    echo "<Location $2 >" | sudo -E tee -a $HTTPD_CONF
    echo "  RequestHeader set Authorization \"Basic $AUTH\"" | sudo -E tee -a $HTTPD_CONF >/dev/null
    echo "  RequestHeader set Host \"${HOST}\"" | sudo -E tee -a $HTTPD_CONF
    # on localhost, preservehost leads to ssl proxy error
    if [[ $HOSTNAME == localhost* ]]; then
        echo "  #ProxyPreserveHost On" | sudo -E tee -a $HTTPD_CONF
    else
        echo "  ProxyPreserveHost On" | sudo -E tee -a $HTTPD_CONF
    fi
    echo "  ProxyPass \"$1\"" | sudo -E tee -a $HTTPD_CONF
    echo "  ProxyPassReverse \"$1/\"" | sudo -E tee -a $HTTPD_CONF
    echo "</Location>" | sudo -E tee -a $HTTPD_CONF
    sudo service ${HTTPD_SERVICE} reload
  fi
  fi #VF_SKIP_APACHE_CONF
}

function removeapacheproxy {
 echo removing apache proxy
 L1=`grep -n -m 1 "\<Location $1" $HTTPD_CONF | cut -f1 -d:`
 echo from row $L1
 if [ -z $L1 ]; then
   echo is unset
 elif [ "$L1" -gt "0" ]; then
   let L2=$L1+6
   echo to row $L2
   sudo sed -i "$L1,$L2 d" $HTTPD_CONF
 fi
}

function help {
echo Usage:
echo - mountb2drop.sh [add] [url] [localpath] [username] [password] [webdavuri]
echo - mountb2drop.sh remove [url] [localpath] [username] [webdavuri]
echo - add - will add configuration and mount webdav,
echo - remove - will unmount and remove configuration
echo - [localpath] is name of directroy under which the webdav is mounted
echo - [url] is the url of remote webdav server
echo - [username] [password] are credentials needed to access the webdav service
echo - [password] not needed when remove
echo - [webdavuri] url to proxy directly to the webdavprovider
}

checkargs $2 $3 $4 $5 $6
# some paths containing symbolic link are expanded by davfs and then not associated correctly
LOCALPATH=`readlink -f $3`

if [ $1 == 'add' ]; then
  checkproxy
  addfstab $2 $LOCALPATH
  addsecrets $LOCALPATH $4 $5
  addapacheproxy $2 $6 $4 $5
  mkdir -p $3
  if [ ! -d $3 ]; then
    echo "previous mountpoint is corrupted, trying to unmount"
    sudo umount $3
  fi
  #user needs to be member of group davfs2
  mount $LOCALPATH
  echo "mounted $3"
  exit
fi

if [ $1 == 'remove' ]; then
  #workaround, without sudo doesnt work
  LOCALPATH=`readlink -f $3`
  sudo umount $LOCALPATH
  rm -d $3
  removeapacheproxy $5
  removefstab $2 $3
  removesecrets $3 $4
  echo "unmounted $3"
  exit
fi

help
