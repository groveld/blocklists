#!/bin/bash

[ ! -d ./lists ] && { echo "Cannot generate README.md: lists folder not found."; exit 1; }

printf "# blocklists\n\n" > ./lists/README.md

# printf "## Syntax\n\n" >> ./lists/README.md
# printf "**adblocker.txt**\n\n" >> ./lists/README.md
# printf "**dnsmasq.txt**\n\n" >> ./lists/README.md
# printf "**domains.txt**\n\n" >> ./lists/README.md
# printf "**hosts.txt**\n\n" >> ./lists/README.md
# printf "**pac.txt**\n\n" >> ./lists/README.md

printf "## Lists\n" >> ./lists/README.md

for folder in ./lists/*/; do
  folder=${folder%*/}
  listname=${folder##*/}
  printf "\n### ${listname}\n\n" >> ./lists/README.md
  printf "|File|Entries|Size|Updated|Hash|\n" >> ./lists/README.md
  printf "|-|-|-|-|-|\n" >> ./lists/README.md

  for file in ${folder}/*; do
    filename=${file##*/}
    fileurl=$(head -5 ${file} | sed -n 's/^.*File: //p')
    entries=$(head -5 ${file} | sed -n 's/^.*Entries: //p')
    filesize=$(stat -c '%s' ${file} | numfmt --to iec)
    filedate=$(head -5 ${file} | sed -n 's/^.*Updated: //p')
    filehash=$(sha1sum ${file} | cut -d' ' -f1)
    printf "|[${filename}](${fileurl})|${entries}|${filesize}|${filedate}|${filehash}|\n" >> ./lists/README.md
  done

done

echo "Finished generating README.md."
exit 0
