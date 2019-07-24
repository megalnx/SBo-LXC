#!/bin/bash
# 
# Script for creating Slackware containers for building
# SlackBuilds
#
# Copyright 2016-2019 William PC, Seattle, US.
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

CTNAME=Slackware
LOGPATH=~/log/lxc-slack-it
ARCHS="x86 x86_64"
RELEASE="13.37 14.0 14.1 14.2 current"
LXCPATH=/var/lib/lxc/slack-it/slackbuilds
MIRROR=file://mnt/hd/slackware
RPASSWD=""

IFNET=eth0-nat


[ ! -d $LOGPATH ] && mkdir -p $LOGPATH

[ ! -d $LXCPATH/../Downloads ] && mkdir -p $LXCPATH/../Downloads
[ ! -d $LXCPATH/../Public ] && mkdir -p $LXCPATH/../Public
[ ! -d $LXCPATH/../tmp ] && mkdir -p $LXCPATH/../tmp


function ver { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

function deploy(){  
  echo "-> Creating container $1"
  lxc-stop -P $LXCPATH -n $1
  lxc-destroy -P $LXCPATH -n $1
  sleep 2
  MIRROR=$MIRROR arch=$ARCH release=$rv lxc-create -P $LXCPATH -t slackware -n $1 > $LOGPATH/$1/lxc-$(echo $1 | tr [:upper:] [:lower:])\_deploy.log

}

function configure(){
  SLACKPKGCFG=/etc/slackpkg/slackpkg.conf
  macaddr=$(echo $(date)|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
  
  mkdir -p $LXCPATH/$1/rootfs/root/{Downloads,Public}

  grep "lxc.arch" $LXCPATH/$1/config
  if [ $? == "1" ]; then
    echo "lxc.arch = $ARCH" >> $LXCPATH/$1/config
  fi

  sed -i 's/lxc.network.type = empty//' $LXCPATH/$1/config

  grep "lxc.network." $LXCPATH/$1/config
  if [ $? == "1" ]; then
echo "lxc.network.0.type = veth
lxc.network.0.flags = up
lxc.network.0.name = $IFNET
lxc.network.0.link = virbr0
lxc.network.0.hwaddr = $macaddr" >> $LXCPATH/$1/config
  fi
  
  grep "lxc.mount.entry" $LXCPATH/$1/config
  if [ $? == "1" ]; then
    echo "lxc.mount.entry = /var/lib/lxc/slack-it/Downloads  root/Downloads  none rw,bind   0  0" >> $LXCPATH/$1/config
    echo "lxc.mount.entry = /var/lib/lxc/slack-it/Public  root/Public  none rw,bind   0  0" >> $LXCPATH/$1/config
    echo "lxc.mount.entry = /var/lib/lxc/slack-it/tmp  tmp  none rw,bind   0  0" >> $LXCPATH/$1/config
    echo "lxc.mount.entry = /usr/local/mnt/MIRROR/slackware  mnt/hd  none ro,bind   0  0" >> $LXCPATH/$1/config
  fi

  sed -i 's/BATCH=off/BATCH=on/' $LXCPATH/$1/rootfs/$SLACKPKGCFG
  sed -i 's/DEFAULT_ANSWER=n/DEFAULT_ANSWER=y/' $LXCPATH/$1/rootfs/$SLACKPKGCFG

  cp -av /usr/local/sbin/slackbuild-management.sh $LXCPATH/$1/rootfs/usr/local/sbin
  echo "SLACKWARE_VERSION=$rv" > $LXCPATH/$1/rootfs/root/slackbuilds.conf
  
  grep "dhcpcd $IFNET" $LXCPATH/$1/rootfs/etc/rc.d/rc.local
  if [ $? == "1" ]; then
    echo "dhcpcd $IFNET" >> $LXCPATH/$1/rootfs/etc/rc.d/rc.local
  fi
  sleep 1

  echo "root:$RPASSWD" | chroot $LXCPATH/$1/rootfs chpasswd
}

function finstall(){
  LOGFILE=lxc-$(echo $1 | tr [:upper:] [:lower:])
  echo "Starting container $1"
  lxc-start -P $LXCPATH -n $1; sleep 4
#  lxc-attach -P $LXCPATH -n $1 -- dhcpcd eth0-nat
#  lxc-attach -P $LXCPATH -n $1 -- find /mnt/hd/slackware/slackware$SLACKNAME-$rv -iname "*.t?z"
  lxc-attach -P $LXCPATH -n $1 -- slackpkg update > $LOGPATH/$1/$LOGFILE\_update.log; sleep 2
  lxc-attach -P $LXCPATH -n $1 -- slackpkg install slackware$SLACKNAME >> $LOGPATH/$1/$LOGFILE\_install.log; sleep 2
  lxc-attach -P $LXCPATH -n $1 -- slackpkg upgrade-all >> $LOGPATH/$1/$LOGFILE\_upgrade.log; sleep 2
  lxc-stop -P $LXCPATH -n $1; sleep 2
}


function ctmanage(){
for rv in $RELEASE; do
  for arch in $ARCHS; do
    case "$arch" in
      x86) ARCH=i486; SLACKNAME="" ;;
      x86_64) ARCH=x86_64; SLACKNAME="64" ;;
       *) echo "Unkown arch"; exit;;
    esac 
    mkdir -p $LOGPATH/$CTNAME$SLACKNAME-$rv
    $1 $CTNAME$SLACKNAME-$rv
   done
done
sleep 1; lxc-ls -P $LXCPATH -f; sleep 3
}


echo "Deploy Slackware containers"
#ctmanage deploy

echo "Configuring containers"
#ctmanage configure

echo "Install full package series"
ctmanage finstall

