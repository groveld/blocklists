#!/bin/bash

export LC_ALL=C

[ -d ./temp ] && rm -rf ./temp
[ -d ./lists ] && rm -rf ./lists

function parseFile() {
  cat $1 | sed 's/[[:space:]]*#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//; s/.*[[:blank:]]//; /^[[:space:]]*$/d' | sort | uniq
}

[ ! -d ./lists ] && mkdir -p ./lists

for folder in ./data/*/; do
  folder=${folder%*/}
  listname=${folder##*/}

  [ ! -d ./temp/${listname} ] && mkdir -p ./temp/${listname}

  wget -i ./data/${listname}/source.list -O ./temp/${listname}/dirty.source.list
  parseFile ./temp/${listname}/dirty.source.list > ./temp/${listname}/clean.source.list

  cat ./data/global.black.list ./data/${listname}/black.list > ./temp/${listname}/dirty.black.list
  parseFile ./temp/${listname}/dirty.black.list > ./temp/${listname}/clean.black.list

  cat ./data/global.white.list ./data/${listname}/white.list > ./temp/${listname}/dirty.white.list
  parseFile ./temp/${listname}/dirty.white.list > ./temp/${listname}/clean.white.list

  sort -u ./temp/${listname}/clean.source.list ./temp/${listname}/clean.black.list | grep -Fxv -f ./temp/${listname}/clean.white.list > ./temp/${listname}/${listname}.list

  [ ! -d ./lists/${listname} ] && mkdir -p ./lists/${listname}

  listurl="https://raw.githubusercontent.com/groveld/blocklists/lists/${listname}"
  entries=$(wc -l < ./temp/${listname}/${listname}.list | tr -d '[:space:]')
  updated=$(date -d "$(stat -c '%y' ./temp/${listname}/${listname}.list)" -u +"%F %T UTC")
  website="https://www.groveld.com/blocklists"
  issues="https://github.com/groveld/blocklists/issues"

  # GENERATE DOMAINS LIST
  filename="domains.txt"
  printf "# File: ${listurl}/${filename}\n" > ./lists/${listname}/${filename}
  printf "# Entries: ${entries}\n" >> ./lists/${listname}/${filename}
  printf "# Updated: ${updated}\n" >> ./lists/${listname}/${filename}
  printf "# Website: ${website}\n" >> ./lists/${listname}/${filename}
  printf "# Issues: ${issues}\n\n" >> ./lists/${listname}/${filename}
  cat ./temp/${listname}/${listname}.list >> ./lists/${listname}/${filename}

  # GENERATE ADBLOCKER-SYNTAX DOMAINS LIST
  filename="adblocker.txt"
  printf "! File: ${listurl}/${filename}\n" > ./lists/${listname}/${filename}
  printf "! Entries: ${entries}\n" >> ./lists/${listname}/${filename}
  printf "! Updated: ${updated}\n" >> ./lists/${listname}/${filename}
  printf "! Website: ${website}\n" >> ./lists/${listname}/${filename}
  printf "! Issues: ${issues}\n\n" >> ./lists/${listname}/${filename}
  sed 's/^/||/; s/$/\^/' ./temp/${listname}/${listname}.list >> ./lists/${listname}/${filename}

  # GENERATE HOSTS LIST
  filename="hosts.txt"
  printf "# File: ${listurl}/${filename}\n" > ./lists/${listname}/${filename}
  printf "# Entries: ${entries}\n" >> ./lists/${listname}/${filename}
  printf "# Updated: ${updated}\n" >> ./lists/${listname}/${filename}
  printf "# Website: ${website}\n" >> ./lists/${listname}/${filename}
  printf "# Issues: ${issues}\n\n" >> ./lists/${listname}/${filename}
  sed 's/^/0.0.0.0 /' ./temp/${listname}/${listname}.list >> ./lists/${listname}/${filename}

  # GENERATE DNSMASQ LIST
  filename="dnsmasq.txt"
  printf "# File: ${listurl}/${filename}\n" > ./lists/${listname}/${filename}
  printf "# Entries: ${entries}\n" >> ./lists/${listname}/${filename}
  printf "# Updated: ${updated}\n" >> ./lists/${listname}/${filename}
  printf "# Website: ${website}\n" >> ./lists/${listname}/${filename}
  printf "# Issues: ${issues}\n\n" >> ./lists/${listname}/${filename}
  sed 's/^/address=\//; s/$/\/0.0.0.0/' ./temp/${listname}/${listname}.list >> ./lists/${listname}/${filename}

  # GENERATE PAC (PROXY AUTO-CONFIGURATION) LIST
  filename="pac.txt"
  printf "// File: ${listurl}/${filename}\n" > ./lists/${listname}/${filename}
  printf "// Entries: ${entries}\n" >> ./lists/${listname}/${filename}
  printf "// Updated: ${updated}\n" >> ./lists/${listname}/${filename}
  printf "// Website: ${website}\n" >> ./lists/${listname}/${filename}
  printf "// Issues: ${issues}\n\n" >> ./lists/${listname}/${filename}
  printf "var BLOCKLIST = {\n" >> ./lists/${listname}/${filename}
  sed 's/^/\"/; s/$/\":null,/' ./temp/${listname}/${listname}.list >> ./lists/${listname}/${filename}
  printf "};\n\n" >> ./lists/${listname}/${filename}
  printf "function FindProxyForURL(url, host) {\n" >> ./lists/${listname}/${filename}
  printf "  var h = host.toLowerCase();\n" >> ./lists/${listname}/${filename}
  printf "  while(1) {\n" >> ./lists/${listname}/${filename}
  printf "    var n = h.indexOf(\".\");\n" >> ./lists/${listname}/${filename}
  printf "    if (n == -1) break;\n" >> ./lists/${listname}/${filename}
  printf "    var h = h.substr(n+1);\n" >> ./lists/${listname}/${filename}
  printf "    if (h in BLOCKLIST) return \"PROXY 127.0.0.1:8021\";\n" >> ./lists/${listname}/${filename}
  printf " }\n" >> ./lists/${listname}/${filename}
  printf "  return \"DIRECT\";\n" >> ./lists/${listname}/${filename}
  printf "}\n" >> ./lists/${listname}/${filename}

  [ -d ./temp/${listname} ] && rm -rf ./temp/${listname}
done

# CLEANING TEMPORARY FILES AND EXIT
[ -d ./temp ] && rm -rf ./temp
echo "Finished generating lists."
exit 0
