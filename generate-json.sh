#!/bin/bash

[ ! -d ./lists ] && { echo "Cannot generate lists.json: lists folder not found."; exit 1; }

folderjson=()

for folder in ./lists/*/; do
  folder=${folder%*/}
  foldername=${folder##*/}
  filejson=()

  for file in ${folder}/*; do
    filename=$(echo ${file##*/} | cut -d. -f1)
    fileurl=$(head -5 ${file} | sed -n 's/^.*File: //p')
    entries=$(head -5 ${file} | sed -n 's/^.*Entries: //p')
    filesize=$(stat -c '%s' ${file} | numfmt --to iec)
    filedate=$(head -5 ${file} | sed -n 's/^.*Updated: //p')
    filehash=$(sha256sum ${file} | head -c 64)
    filejson+=("\"${filename}\":{\"file\":\"${fileurl}\",\"entries\":\"${entries}\",\"size\":\"${filesize}\",\"updated\":\"${filedate}\",\"hash\":\"${filehash}\"}")
  done

  folderjson+=("\"${foldername}\":{$(IFS=,; echo "${filejson[*]}")}")
done

printf "{$(IFS=,; echo "${folderjson[*]}")}" > ./lists/lists.json

echo "Finished generating lists.json."
exit 0
