#!/bin/sh
#
# Download HDHomeRun Prime firmware
#
# http://download.silicondust.com/hdhomerun/hdhomerun3_cablecard_firmware_20160630atest2.bin
#
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
