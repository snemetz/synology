#!/bin/sh
# Synology uses ash NOT bash
#
# Update HDHomeRun DVR engine beta to current version
#
# Dependencies:
#   jq  https://stedolan.github.io/jq/
#
# Author: Steven Nemetz
#
#Issues:
#- how to test for required config file changes?
#- notify user of update
#- Add script and schedule task

DirHDHomeRun=/volume1/HDHomeRun
DirBin=${DirHDHomeRun}/bin
DirEtc=${DirHDHomeRun}/etc
DirTmp=/tmp
DirArchive=${DirBin}/archive
EXE=${DirBin}/hdhomerun_record
TMP="_test"
EXETMP=$EXE$TMP
LOG=hdhomerun_dl.log
FilenameBase=hdhomerun_record_linux
DLPATH=http://download.silicondust.com/hdhomerun/${FilenameBase}
ConfigFile=${DirEtc}/hdhomerun.conf
FileDeviceDiscover=${DirTmp}/discover.json

mkdir -p ${DirArchive}
cd ${DirBin}
wget $DLPATH -o $LOG -O $EXETMP
FileNew=$(cat hdhomerun_dl.log | grep Location: | sed 's/Location: http:\/\/download.silicondust.com\/hdhomerun\///' | sed 's/\s*\[following\].*$//')
VersionNew="${FileNew##${FilenameBase}_}"
if [ -e "${EXE}" ]; then
  VersionCurrent=$(${EXE} version | head -n 1 | sed 's/^.*version\s*//')
else
  VersionCurrent=""
  # No existing DVR engine. So OK to upgrade or install
  UpgradeOK=0
fi
FileCurrent="${FilenameBase}_${VersionCurrent}"
if [ "${VersionNew}" = "${VersionCurrent}" ]; then
  echo "The downloaded version ($VersionNew) is the same as the existing (${VersionCurrent}). No action taken."
  rm -f $EXETMP
else
  # TODO: Check that DVR or all turners are idle first
  # if no EXE upgrade: VersionCurrent = ''
  if [ "$UpgradeOK" -ne 0 ]; then
    # Is DVR running?
    ${EXE} status | grep -q 'not running'
    if [ $? -eq 0 ]; then
      UpgradeOK=0
    fi
  fi
  if [ "$UpgradeOK" -ne 0 ]; then
    # Are all tuners idle?
    wget http://my.hdhomerun.com/discover -O ${FileDeviceDiscover}
    ### Process HDHomeRun Devices
    # Test that all tuners are idle
    index=-1
    for Device in $(jq 'map(has("DeviceID"))' ${FileDeviceDiscover} | grep -Ev '\]|\[' | sed 's/^\s*//;s/\s*$//;s/,//'); do
      index=$((index + 1))
      if [ $Device == 'false' ]; then continue; fi
      for URL in $(jq ".[$index].BaseURL" ${FileDeviceDiscover} -r); do
        TunersURL="$URL/tuners.html"
        Tuners=$(curl $TunersURL 2>/dev/null | grep -E 'Tuner.*Channel' | wc -l)
        TunersIdle=$(curl $TunersURL 2>/dev/null | grep -E 'Tuner.*Channel.*>none<' | wc -l)
        echo "URL=$URL, Tuners=$Tuners, Idle=$TunersIdle"
        if [ $Tuners -ne $TunersIdle ]; then
          # All tuners NOT idle
          UpgradeOK=1
        fi
        # schedule between 1/2 show start times instead. Ideal :05-10 or :35-40
        # Test no recording starting in X minutes
        #DiscoverURL=$(jq ".[$index].DiscoverURL" ${FileDeviceDiscover} -r)
        #DeviceAuth=$(curl $DiscoverURL | jq '.DeviceAuth' -r)
        # Rules but NOT next event
        # http://my.hdhomerun.com/api/recording_rules?DeviceAuth=<auth code from discover>
        # Look at DVR UI Upcoming
        # /api/episodes
      done
    done
  fi
  ### Process HDHomeRun DVR Engines
  #index=-1
  #for DVR in $(jq 'map(has("StorageID"))' discover.json | grep -Ev '\]|\[' | sed 's/^\s*//;s/\s*$//;s/,//'); do
  #  index=$((index + 1))
  #  if [ $DVR == 'false' ]; then continue; fi
  #  jq ".[$index].DiscoverURL" discover.json
  #done
  # Is DVR going to start recording in less than X minutes?
  if [ "$UpgradeOK" -ne 1 ]; then
    echo "Existing version (${VersionCurrent}) will be upgraded to the downloaded version ($VersionNew)"
    $EXE stop --conf ${ConfigFile}
    mv $EXETMP $EXE
    chmod +rx $EXE
    $EXE start --conf ${ConfigFile}
    cp $EXE ${DirArchive}/${FileNew}
    $EXE version
  else
    echo "Existing version (${VersionCurrent}) should get upgraded to the downloaded version ($VersionNew)"
    echo "System NOT ready for upgrade! Not upgrading"
  fi
fi
#rm -f $LOG
