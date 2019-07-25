export RELEASE="13.37 14.0 14.1 14.2" 

BASEPKGLIST="libvirt texlive"
AUDIOPKGLIST="audacity"
CADPKGLIST="FreeCAD"
EADPKGLIST="gnucap ngspice gspiceui kicad"
DESKTOPPKGLIST="openbox wmctrl screenfetch conky conkyforecast xplanet"
XFCEPKGLIST="xfce4-notes-plugin xfce4-genmon-plugin"
SERVERPKGLIST="squid freeswitch"
STREAMPKGLIST="icecast minidlna"

PKGLIST="$XFCEPKGLIST $SERVERPKGLIST $STREAMPKGLIST"

for pkg in $PKGLIST;do
  sh build-package.sh pack $pkg
done


