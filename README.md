# Blocklists

### EdgeRouter Update Script

```sh
#!/bin/vbash

function getJsonVal() {
  python3 -c "import json,sys;sys.stdout.write(json.dumps(json.load(sys.stdin)$1))";
}

JSON=$(curl -s -X GET https://raw.githubusercontent.com/groveld/blocklists/lists/lists.json)
NEWFILE=$(echo $JSON | getJsonVal "['ads']['dnsmasq']['file']" | tr -d \")
NEWHASH=$(echo $JSON | getJsonVal "['ads']['dnsmasq']['hash']" | tr -d \")
OLDFILE=$(readlink -f /etc/dnsmasq.d/dnsmasq-ads.conf)
OLDHASH=$(echo $OLDFILE | cut -d'-' -f2 | cut -d'.' -f1)

[ $NEWHASH == $OLDHASH ] && echo "New list is the same as current list."; exit 0

curl -s -o /config/user-data/ads-$NEWHASH.conf $NEWFILE

ln -sfn /config/user-data/ads-${NEWHASH}.conf /etc/dnsmasq.d/dnsmasq-ads.conf

/etc/init.d/dnsmasq force-reload

rm -rf $OLDFILE

exit 0
```
