# HDHomeRun APIs
---
### my.hdhomerun.com API
#### Discovery
- Get HDHomeRun devices and URLs. Has all "devices" data, but different field names
- http://my.hdhomerun.com/discover
- Issue: should have DVR engine urls? Upgrade engine and test
- Returns:
```
[
    {
        "DeviceID": "FFFFFFFF",
        "LocalIP": "192.168.1.182",
        "ConditionalAccess": 1,
        "BaseURL": "http://192.168.1.182",
        "DiscoverURL": "http://192.168.1.182/discover.json",
        "LineupURL": "http://192.168.1.182/lineup.json"
    },
    {
        "DeviceID": "FFFFFFFF",
        "LocalIP": "192.168.1.107",
        "ConditionalAccess": 1,
        "BaseURL": "http://192.168.1.107",
        "DiscoverURL": "http://192.168.1.107/discover.json",
        "LineupURL": "http://192.168.1.107/lineup.json"
    }
]
```

#### Get HDHomeRun devices
- Get JSON array of HDHomeRun devices
- http://my.hdhomerun.com/devices
- Returns:
```
[{"device_id":"FFFFFFFF","local_ip":"192.168.1.182"},{"device_id":"FFFFFFFF","local_ip":"192.168.1.107"}]
```

#### Get DVR recording rules
http://my.hdhomerun.com/api/recording_rules?DeviceAuth={auth code from discover}

#### Other commands
- /api/episodes?DeviceAuth=
- /api/guide.php?DeviceAuth=
- /dvr/
 - fixup
 - register

---
### DVR Engine API
#### Discovery
- {engine URL}/discover.json
- Example: ```http://192.168.1.174:34182/discover.json```
- How to find the port?
- Returns:
```
{"FriendlyName":"HDHomeRun RECORD","Version":"20160321atest1","BaseURL":"http://192.168.1.174:34182","StorageURL":"http://192.168.1.174:34182/recorded_files.json","FreeSpace":645576847360}
```

---
### Device API
#### Discovery
- http://{device ip}/discover.json
- Returns:
```
{"FriendlyName":"HDHomeRun PRIME","ModelNumber":"HDHR3-CC","FirmwareName":"hdhomerun3_cablecard","FirmwareVersion":"20160630atest2","DeviceID":"FFFFFFFF","DeviceAuth":"FFFFFFFF","TunerCount":3,"ConditionalAccess":1,"BaseURL":"http://192.168.1.182:80","LineupURL":"http://192.168.1.182:80/lineup.json"}
```

#### Channel Lineup
- http://{device ip}/lineup.json
- http://{device ip}/lineup.xml

#### Record (Download stream)
- wget http://{device ip}:5004/auto/v<channel number>?duration=14400
- Duration is seconds

#### Web Pages
- Home Page: http://{device ip}/
- CableCard Menu: http://{device ip}/cc.html
- Channel Lineup: http://{device ip}/lineup.html
- Tuner Resolver Menu: http://{device ip}/tr.html
- Tuner Status Summary: http://{device ip}/tuners.html
- Tuner 0 Status: http://{device ip}/tuners.html?page=tuner0
- System Status: http://{device ip}/system.html
- System Log: http://{device ip}/log.html


---
## References:
- https://github.com/Silicondust/documentation/wiki
- http://www.silicondust.com/hdhomerun/hdhomerun_http_development.pdf
- https://www.silicondust.com/hdhomerun/hdhomerun_development.pdf
