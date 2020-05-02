#!/bin/bash

export LC_ALL=C

[ -d ./build ] && rm -rf ./build
[ -d ./temp ] && rm -rf ./temp

function parseFile() {
  cat $1 | sed 's/[[:space:]]*#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//; s/.*[[:blank:]]//; /^[[:space:]]*$/d' | sort | uniq
}

function jsonFileHash() {
  echo "\"file\":\"$1\",\"hash\":\"$(sha1sum $2 | cut -d' ' -f1)\""
}\

JSON=()

for dir in ./data/*/; do
  dir=${dir%*/} # remove trailing slash
  LIST=${dir##*/}
  jsonList=()

  [ ! -d ./temp/${LIST} ] && mkdir -p ./temp/${LIST}

  wget -i ./data/${LIST}/url.list -O ./temp/${LIST}/dl.dirty.list
  parseFile ./temp/${LIST}/dl.dirty.list > ./temp/${LIST}/dl.clean.list

  cat ./data/white.list ./data/${LIST}/white.list > ./temp/${LIST}/white.dirty.list
  parseFile ./temp/${LIST}/white.dirty.list > ./temp/${LIST}/white.clean.list

  cat ./data/black.list ./data/${LIST}/black.list > ./temp/${LIST}/black.dirty.list
  parseFile ./temp/${LIST}/black.dirty.list > ./temp/${LIST}/black.clean.list

  sort -u ./temp/${LIST}/dl.clean.list ./temp/${LIST}/black.clean.list | grep -Fxv -f ./temp/${LIST}/white.clean.list > ./temp/${LIST}/${LIST}.list

  URL="https://raw.githubusercontent.com/groveld/blocklists/master"
  DATETIME=$(date -u +"%Y-%m-%d @ %T (UTC)")
  ENTRIES=$(wc -l < ./temp/${LIST}/${LIST}.list | tr -d '[:space:]')

  [ ! -d ./build/${LIST} ] && mkdir -p ./build/${LIST}

  # GENERATE DOMAIN ONLY FILE
  printf "# LISTURL: ${URL}/${LIST}/domains.txt\n" > ./build/${LIST}/domains.txt
  printf "# UPDATED: ${DATETIME}\n" >> ./build/${LIST}/domains.txt
  printf "# ENTRIES: ${ENTRIES}\n\n" >> ./build/${LIST}/domains.txt
  cat ./temp/${LIST}/${LIST}.list >> ./build/${LIST}/domains.txt
  jsonList+=(\"domains\":{$(jsonFileHash ${URL}/${LIST}/domains.txt ./build/${LIST}/domains.txt)})

  # GENERATE WINDOWS HOSTS FILE
  printf "# LISTURL: ${URL}/${LIST}/hosts.txt\n" > ./build/${LIST}/hosts.txt
  printf "# UPDATED: ${DATETIME}\n" >> ./build/${LIST}/hosts.txt
  printf "# ENTRIES: ${ENTRIES}\n\n" >> ./build/${LIST}/hosts.txt
  printf "127.0.0.1 localhost\n" >> ./build/${LIST}/hosts.txt
  printf "127.0.0.1 local\n" >> ./build/${LIST}/hosts.txt
  printf "127.0.0.1 loopback\n" >> ./build/${LIST}/hosts.txt
  printf "127.0.0.1 localhost.localdomain\n" >> ./build/${LIST}/hosts.txt
  printf "255.255.255.255 broadcasthost\n" >> ./build/${LIST}/hosts.txt
  printf "::1 localhost\n" >> ./build/${LIST}/hosts.txt
  printf "0.0.0.0 0.0.0.0\n\n" >> ./build/${LIST}/hosts.txt
  sed 's/^/0.0.0.0 /' ./temp/${LIST}/${LIST}.list >> ./build/${LIST}/hosts.txt
  jsonList+=(\"hosts\":{$(jsonFileHash ${URL}/${LIST}/hosts.txt ./build/${LIST}/hosts.txt)})

  # GENERATE DNSMASQ CONFIG
  printf "# LISTURL: ${URL}/${LIST}/dnsmasq.txt\n" > ./build/${LIST}/dnsmasq.txt
  printf "# UPDATED: ${DATETIME}\n" >> ./build/${LIST}/dnsmasq.txt
  printf "# ENTRIES: ${ENTRIES}\n\n" >> ./build/${LIST}/dnsmasq.txt
  sed 's/^/address=\//; s/$/\/0.0.0.0/' ./temp/${LIST}/${LIST}.list >> ./build/${LIST}/dnsmasq.txt
  jsonList+=(\"dnsmasq\":{$(jsonFileHash ${URL}/${LIST}/dnsmasq.txt ./build/${LIST}/dnsmasq.txt)})

  JSON+=($(echo \"${LIST}\":{${jsonList[@]}} | sed 's/ /,/g'))
  [ -d ./temp/${LIST} ] && rm -rf ./temp/${LIST}
done

printf $(echo {${JSON[@]}} | sed 's/ /,/g') > ./build/lists.json

[ -d ./temp ] && rm -rf ./temp
echo "Finished building blocklists."
exit 0
