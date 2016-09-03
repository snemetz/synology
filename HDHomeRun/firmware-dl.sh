#!/bin/sh
#
# Download and upgrade HDHomeRun firmware
#
# Tested on Prime but should work on any HDHomeRun devices
#
# Dependencies:
#   hdhomerun_config
#   jq  https://stedolan.github.io/jq/
#
# Author: Steven Nemetz
#
#TODO:
#  How to determine latest version to download
#  Notify user of upgrade
#

FirmwareCurrent=20160902beta3
# Synology with VideoStation installed
hdhomerun_config=/volume1/@appstore/VideoStation/bin/hdhomerun_config
# Path to archive directory of firmware files
DirArchive=/volume1/software/Apps-Installed/HTPC/HDHomeRun/Firmware
DirTmp=/tmp
Log=${DirTmp}/hdhomerun_firmware_dl.log
DL_URLBase=http://download.silicondust.com/hdhomerun
FileDevicesDiscover=${DirTmp}/discover_devices.json
FileDeviceDiscover=${DirTmp}/discover_device.json

wget http://my.hdhomerun.com/discover -O ${FileDevicesDiscover}
### Process HDHomeRun Devices
# If device is idle and older version, upgrade
index=-1
for Device in $(jq 'map(has("DeviceID"))' ${FileDevicesDiscover} | grep -Ev '\]|\[' | sed 's/^\s*//;s/\s*$//;s/,//'); do
  index=$((index + 1))
  if [ $Device == 'false' ]; then continue; fi
  # Verify it has an older firmware
  URLDeviceDiscover=$(jq ".[$index].DiscoverURL" ${FileDevicesDiscover} -r)
  wget ${URLDeviceDiscover} -O ${FileDeviceDiscover}
  # Can change this to a single array assignment
  DeviceID=$(jq ".DeviceID" ${FileDeviceDiscover} -r)
  DeviceName=$(jq ".FriendlyName" ${FileDeviceDiscover} -r)
  FirmwareName=$(jq ".FirmwareName" ${FileDeviceDiscover} -r)
  FirmwareVersion=$(jq ".FirmwareVersion" ${FileDeviceDiscover} -r)
  ModelNumber=$(jq ".ModelNumber" ${FileDeviceDiscover} -r)
  TunerCount=$(jq ".TunerCount" ${FileDeviceDiscover} -r)
  if [ "${FirmwareVersion}" = "${FirmwareCurrent}" ]; then
    continue
  fi
  # Check if new firmware on disk - download if not
  FileFirmware=${FirmwareName}_firmware_${FirmwareCurrent}.bin
  if [ ! -f ${DirArchive}/${FileFirmware} ]; then
    wget ${DL_URLBase}/${FileFirmware} -o $Log -O ${DirArchive}/${FileFirmware}
  fi
  # Check it is idle
  URLDeviceBase=$(jq ".[$index].BaseURL" ${FileDevicesDiscover} -r)
  TunersURL="$URLDeviceBase/tuners.html"
  Tuners=$(curl $TunersURL 2>/dev/null | grep -E 'Tuner.*Channel' | wc -l)
  if [ $TunerCount -ne $Tuners ]; then
    echo "ERROR: ${DeviceID} mismatch of number of tuners on device"
    continue
  fi
  TunersIdle=$(curl $TunersURL 2>/dev/null | grep -E 'Tuner.*Channel.*>none<' | wc -l)
  echo "URL=$URLDeviceBase, TunerCount=$TunerCount, Tuners=$Tuners, Idle=$TunersIdle"
  if [ $Tuners -ne $TunersIdle ]; then
    echo "ERROR: ${DeviceID} tuners are not idle for upgrade"
    continue
  fi
  # Upgrade
  echo "OK to upgrade ${DeviceID} from ${FirmwareVersion} to ${FirmwareCurrent}"
  ${hdhomerun_config} ${DeviceID} upgrade ${DirArchive}/${FileFirmware}
done
