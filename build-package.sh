
CTNAME=Slackware
ARCHS=${ARCHS:-"x86 x86_64"}
RELEASE=${RELEASE:-"13.37 14.0 14.1 14.2"}
LXCPATH=/var/lib/lxc/slack-it/slackbuilds


function ver { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

function slackit_build(){
  echo "Starting $CTNAME$SLACKNAME-$rv";
  lxc-start -P $LXCPATH -n $1; sleep 10
#  lxc-attach -P $LXCPATH -n $1 -- slackpkg update
#  lxc-attach -P $LXCPATH -n $1 -- slackpkg upgrade-all
  lxc-attach -P $LXCPATH -n $1 --set-var ARCH=$ARCH --set-var SBo_OUTPUT=/tmp --set-var AUTO=y --  slackbuild-management.sh ${@:2}
  lxc-attach -P $LXCPATH -n $1 slackpkg clean-system
  echo "Stoping $CTNAME$SLACKNAME-$rv";
  lxc-stop -P $LXCPATH -n $1
}

function ctmanage(){
for rv in $RELEASE; do
  for arch in $ARCHS; do
    case "$arch" in
      x86)
      if [ $(ver $rv) -lt $(ver 14.2) ]; then
         ARCH=i486; SLACKNAME="" 
      else
         ARCH=i586; SLACKNAME="" 
      fi
       ;;
      x86_64) ARCH=x86_64; SLACKNAME="64" ;;
       *) echo "Unkown arch"; exit;;
    esac    
    echo "slackbuild-management.sh $@ at $CTNAME$SLACKNAME-$rv"; sleep 2
    slackit_build $CTNAME$SLACKNAME-$rv $@
   done
  done
}

ctmanage $@


