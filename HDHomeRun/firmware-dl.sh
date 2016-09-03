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
# http://download.silicondust.com/hdhomerun/hdhomerun3_cablecard_firmware_20160630atest2.bin
#	20160901beta3
#TODO:
#  How to determine latest version to download
#  Get firmware version on HDHomeRun Prime
#  Upgrade HDHomeRun if got newer version and HDHomeRun is idle
#  Upgrade all HDHomeRun devices
#  Notify user of upgrade
#
#Notes:
#  Via Web
#    Get devices and IPs in json:
#      http://my.hdhomerun.com/devices
#      Fields: device_id, local_ip
#    Get firmware version
#      http://<local ip>/discover.json
#      get fields: FirmwareName, FirmwareVersion
#      Filename: ${FirmwareName}_firmware_${FirmwareVersion}.bin
#  Via CLI: hdhomerun_config
#    Get devices:
#      hdhomerun_config discover
#    Get firmware version:
#      hdhomerun_config <device ID> get /sys/version
#    Check if device is idle
#    Upgrade firmware:
#      hdhomerun_config <device ID> upgrade <firmware file>

FirmwareCurrent=20160902beta3
# Synology with VideoStation installed
hdhomerun_config=/volume1/@appstore/VideoStation/bin/hdhomerun_config
DirArchive=/volume1/software/Apps-Installed/HTPC/HDHomeRun/Firmware
DirTmp=/tmp
Log=hdhomerun_dl.log
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
