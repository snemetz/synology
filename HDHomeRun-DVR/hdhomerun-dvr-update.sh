#!/bin/sh
#
# Update HDHomeRun DVR engine beta to current version
#
#Issues:
#- how to test for required config file changes?
#- notify user of update
#- Add script and schedule task
#

DirHDHomeRun=/volume1/HDHomeRun
DirBin=${DirHDHomeRun}/bin
DirEtc=${DirHDHomeRun}/etc
DirArchive=${DirBin}/archive
EXE=./hdhomerun_record
TMP="_test"
EXETMP=$EXE$TMP
LOG=hdhomerun_dl.log
FilenameBase=hdhomerun_record_linux
DLPATH=http://download.silicondust.com/hdhomerun/${FilenameBase}
ConfigFile=${DirEtc}/hdhomerun.conf

mkdir -p ${DirArchive}
cd ${DirBin}
wget $DLPATH -o $LOG -O $EXETMP
FileNew=$(cat hdhomerun_dl.log | grep Location: | sed 's/Location: http:\/\/download.silicondust.com\/hdhomerun\///' | sed 's/\s*\[following\].*$//')
VersionNew="${FileNew##${FilenameBase}_}"
if [ -e "${EXE}" ]; then
  VersionCurrent=$(${EXE} version | head -n 1 | sed 's/^.*version\s*//')
else
  VersionCurrent=""
fi
FileCurrent="${FilenameBase}_${VersionCurrent}"
if [ "${VersionNew}" = "${VersionCurrent}" ]; then
  echo "The downloaded version ($VersionNew) is the same as the existing (${VersionCurrent}). No action taken."
  rm -f $EXETMP
else
  echo "Existing version (${VersionCurrent}) will be upgraded to the downloaded version ($VersionNew)"
  # $EXE stop --conf ${ConfigFile}
  mv $EXETMP $EXE
  chmod +rx $EXE
  cp $EXE ${DirArchive}/${FileNew}
  # $EXE start --conf ${ConfigFile}
fi
rm -f $LOG

