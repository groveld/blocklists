#!/bin/bash

[ ! -d ./lists ] && { echo "Cannot generate lists.json: lists folder not found."; exit 1; }

printf "{" > ./lists/lists.json

for folder in ./lists/*/; do
  folder=${folder%*/}
  foldername=${folder##*/}

  printf "\"${foldername}\":{" >> ./lists/lists.json

  for file in ${folder}/*; do
    filename=${file##*/}
    fileurl=$(head -5 ${file} | sed -n 's/^.*File: //p')
    entries=$(head -5 ${file} | sed -n 's/^.*Entries: //p')
    filesize=$(stat -c '%s' ${file} | numfmt --to iec)
    filedate=$(head -5 ${file} | sed -n 's/^.*Updated: //p')
    filehash=$(sha1sum ${file} | cut -d' ' -f1)
    printf "\"${filename}\":{\"file\":\"${fileurl}\",\"entries\":\"${entries}\",\"size\":\"${filesize}\",\"updated\":\"${filedate}\",\"hash\":\"${filehash}\"}," >> ./lists/lists.json
  done

  printf "}," >> ./lists/lists.json

done

printf "}" >> ./lists/lists.json

echo "Finished generating lists.json."
exit 0
