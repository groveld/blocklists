#!/bin/bash

export LC_ALL=C

[ -d ./temp ] && rm -rf ./temp
[ -d ./lists ] && rm -rf ./lists

function parseFile() {
  cat $1 | sed 's/[[:space:]]*#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//; s/.*[[:blank:]]//; /^[[:space:]]*$/d' | sort | uniq
}

function jsonMeta() {
  FILESIZE=$(stat -c '%s' ./lists/${LIST}/${TYPE}.txt)
  FILEHASH=$(sha1sum ./lists/${LIST}/${TYPE}.txt | cut -d' ' -f1)
  echo "\"file\":\"${LISTURL}/${TYPE}.txt\",\"entries\":\"${ENTRIES}\",\"size\":\"${FILESIZE}\",\"date\":\"${UPDATED}\",\"hash\":\"${FILEHASH}\""
}

JSON=()

for DIR in ./data/*; do
  LIST=${DIR##*/}
  LISTURL="https://raw.githubusercontent.com/groveld/blocklists/lists/${LIST}"
  TYPEJSON=()

  [ ! -d ./temp/${LIST} ] && mkdir -p ./temp/${LIST}

  wget -i ${DIR}/source.list -O ./temp/${LIST}/dirty.source.list
  parseFile ./temp/${LIST}/dirty.source.list > ./temp/${LIST}/clean.source.list

  cat ./data/global.black.list ${DIR}/black.list > ./temp/${LIST}/dirty.black.list
  parseFile ./temp/${LIST}/dirty.black.list > ./temp/${LIST}/clean.black.list

  cat ./data/global.white.list ${DIR}/white.list > ./temp/${LIST}/dirty.white.list
  parseFile ./temp/${LIST}/dirty.white.list > ./temp/${LIST}/clean.white.list

  sort -u ./temp/${LIST}/clean.source.list ./temp/${LIST}/clean.black.list | grep -Fxv -f ./temp/${LIST}/clean.white.list > ./temp/${LIST}/${LIST}.list

  UPDATED=$(stat -c '%y' ./temp/${LIST}/${LIST}.list)
  ENTRIES=$(wc -l < ./temp/${LIST}/${LIST}.list | tr -d '[:space:]')

  [ ! -d ./lists/${LIST} ] && mkdir -p ./lists/${LIST}

  # GENERATE DOMAINS LIST
  TYPE="domains"
  printf "# LISTURL: ${LISTURL}/${TYPE}.txt\n" > ./lists/${LIST}/${TYPE}.txt
  printf "# UPDATED: ${UPDATED}\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "# ENTRIES: ${ENTRIES}\n\n" >> ./lists/${LIST}/${TYPE}.txt
  cat ./temp/${LIST}/${LIST}.list >> ./lists/${LIST}/${TYPE}.txt
  TYPEJSON+=(\"${TYPE}\":{$(jsonMeta)})

  # GENERATE WILDCARD DOMAINS LIST
  TYPE="wildcard"
  printf "# LISTURL: ${LISTURL}/${TYPE}.txt\n" > ./lists/${LIST}/${TYPE}.txt
  printf "# UPDATED: ${UPDATED}\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "# ENTRIES: ${ENTRIES}\n\n" >> ./lists/${LIST}/${TYPE}.txt
  sed 's/^/\*./' ./temp/${LIST}/${LIST}.list >> ./lists/${LIST}/${TYPE}.txt
  TYPEJSON+=(\"${TYPE}\":{$(jsonMeta)})

  # GENERATE ADBLOCKER-SYNTAX DOMAINS LIST
  TYPE="adblocker"
  printf "# LISTURL: ${LISTURL}/${TYPE}.txt\n" > ./lists/${LIST}/${TYPE}.txt
  printf "# UPDATED: ${UPDATED}\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "# ENTRIES: ${ENTRIES}\n\n" >> ./lists/${LIST}/${TYPE}.txt
  sed 's/^/||/; s/$/\^/' ./temp/${LIST}/${LIST}.list >> ./lists/${LIST}/${TYPE}.txt
  TYPEJSON+=(\"${TYPE}\":{$(jsonMeta)})

  # GENERATE HOSTS LIST
  TYPE="hosts"
  printf "# LISTURL: ${LISTURL}/${TYPE}.txt\n" > ./lists/${LIST}/${TYPE}.txt
  printf "# UPDATED: ${UPDATED}\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "# ENTRIES: ${ENTRIES}\n\n" >> ./lists/${LIST}/${TYPE}.txt
  sed 's/^/0.0.0.0 /' ./temp/${LIST}/${LIST}.list >> ./lists/${LIST}/${TYPE}.txt
  TYPEJSON+=(\"${TYPE}\":{$(jsonMeta)})

  # GENERATE DNSMASQ LIST
  TYPE="dnsmasq"
  printf "# LISTURL: ${LISTURL}/${TYPE}.txt\n" > ./lists/${LIST}/${TYPE}.txt
  printf "# UPDATED: ${UPDATED}\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "# ENTRIES: ${ENTRIES}\n\n" >> ./lists/${LIST}/${TYPE}.txt
  sed 's/^/address=\//; s/$/\/0.0.0.0/' ./temp/${LIST}/${LIST}.list >> ./lists/${LIST}/${TYPE}.txt
  TYPEJSON+=(\"${TYPE}\":{$(jsonMeta)})

  # GENERATE PAC (PROXY AUTO-CONFIGURATION) LIST
  TYPE="pac"
  printf "# LISTURL: ${LISTURL}/${TYPE}.txt\n" > ./lists/${LIST}/${TYPE}.txt
  printf "# UPDATED: ${UPDATED}\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "# ENTRIES: ${ENTRIES}\n\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "var BLOCKLIST = {\n" >> ./lists/${LIST}/${TYPE}.txt
  sed 's/^/\"/; s/$/\":null,/' ./temp/${LIST}/${LIST}.list >> ./lists/${LIST}/${TYPE}.txt
  printf "};\n\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "function FindProxyForURL(url, host) {\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "  var h = host.toLowerCase();\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "  while(1) {\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "    var n = h.indexOf(".");\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "    if (n == -1) break;\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "    var h = h.substr(n+1);\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "    if (h in BLOCKLIST) return "PROXY 127.0.0.1:8021";\n" >> ./lists/${LIST}/${TYPE}.txt
  printf " }\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "  return "DIRECT";\n" >> ./lists/${LIST}/${TYPE}.txt
  printf "}\n" >> ./lists/${LIST}/${TYPE}.txt
  TYPEJSON+=(\"${TYPE}\":{$(jsonMeta)})

  JSON+=($(echo \"${LIST}\":{${TYPEJSON[@]}} | sed 's/ /,/g'))
  [ -d ./temp/${LIST} ] && rm -rf ./temp/${LIST}
done

# GENERATING JSON FILE WITH LIST INFORMATION
printf $(echo {${JSON[@]}} | sed 's/ /,/g') > ./lists/lists.json

# CLEANING TEMPORARY FILES AND EXIT
[ -d ./temp ] && rm -rf ./temp
echo "Finished building nopelists."
exit 0
