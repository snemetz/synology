#!/bin/sh
#
# Init script for HDHomeRun DVR engine
#
# Script goes in: /usr/local/etc/rc.d
# Share is: HDHomeRun on volume1
#

DirHDHomeRun=/volume1/HDHomeRun
DirBin=${DirHDHomeRun}/bin
DirEtc=${DirHDHomeRun}/etc
ConfigFile=${DirEtc}/hdhomerun.conf
EXE=${DirBin}/hdhomerun_record

#cd ${DirBin}
echo "$1 HDHomeRun DVR ..."
$EXE $1 --conf ${ConfigFile}

