# Blocklists

### EdgeRouter Update Script

```sh
#!/bin/vbash

function getJsonVal() {
  python -c "import json,sys;sys.stdout.write(json.dumps(json.load(sys.stdin)$1))";
}

JSON=$(curl -s -X GET https://raw.githubusercontent.com/groveld/blocklists/lists/lists.json)
NEWFILE=$(echo $JSON | getJsonVal "['ads']['dnsmasq']['file']" | tr -d \")
NEWHASH=$(echo $JSON | getJsonVal "['ads']['dnsmasq']['hash']" | tr -d \")
OLDFILE=$(readlink -f /etc/dnsmasq.d/dnsmasq-block-ads.conf)
OLDHASH=$(basename $OLDFILE .conf | cut -d'-' -f3)

if [ "$NEWHASH" == "$OLDHASH" ]; then
  echo "You already have the latest ads list"
  exit 0
else
  curl -s -o /config/user-data/block-ads-$NEWHASH.conf $NEWFILE
  ln -sfn /config/user-data/block-ads-$NEWHASH.conf /etc/dnsmasq.d/dnsmasq-block-ads.conf
  /etc/init.d/dnsmasq force-reload
  rm -rf $OLDFILE
  echo "Finished updating ads list"
  exit 0
fi
```
