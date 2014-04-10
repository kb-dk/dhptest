#!/bin/bash
D="$1"
ALTO=ALTO
MODS=MODS
PDF=PDF
XML=XML

rm -f all-altos all-altos-sorted all-pdfs all-pdfs-sorted all-xmls all-xmls-sorted all-modss all-modss-sorted all-dates all-dates-sorted

for D in "$@"; do
  echo "$(date -Iseconds) Checking for existence of both ALTO, MODS, PDF and XML files in directory ${D}"
  P="$(basename "${D}")"
  find "${D}/${ALTO}/" -type f -printf '%f\n' | cut -d. -f1 | sort -u > "${P}"-altos
  find "${D}/${MODS}/" -type f -printf '%f\n' | cut -d. -f1 | sed -s 's/-MODS//' | sort -u > "${P}"-modss
  find "${D}/${PDF}/"  -type f -printf '%f\n' | cut -d. -f1 | sort -u > "${P}"-pdfs
  find "${D}/${XML}/"  -type f -printf '%f\n' | cut -d. -f1 | cut -d_ -f1 | sort -u > "${P}"-xmls
  cat ${P}-altos >> all-altos
  cat ${P}-modss >> all-modss
  cat ${P}-pdfs >> all-pdfs
  cat ${P}-xmls >> all-xmls
  diff -u "${P}"-pdfs "${P}"-altos
  diff -u "${P}"-pdfs "${P}"-modss
  diff -u "${P}"-pdfs "${P}"-xmls

  echo "$(date -Iseconds) Extracting all dates in directory ${D}"
  grep -r dateAvailableStart "${D}/${XML}/" | cut -d\> -f2 | cut -dT -f1 > "${P}"-dates 
  cat ${P}-dates >> all-dates
done

echo "$(date -Iseconds) Checking for existence of both ALTO, MODS, PDF and XML files all directories"
sort -u all-altos > all-altos-sorted
sort -u all-modss > all-modss-sorted
sort -u all-pdfs > all-pdfs-sorted
sort -u all-xmls > all-xmls-sorted
diff -u all-pdfs-sorted all-altos-sorted
diff -u all-pdfs-sorted all-modss-sorted
diff -u all-pdfs-sorted all-xmls-sorted

echo "$(date -Iseconds) Checking for existence of all sequential dates"
sort -u all-dates > all-dates-sorted
cur=$(head -n 1 all-dates-sorted)
tail -n +2 all-dates-sorted | while read date; do
  if [ ! "$(date -d "$cur +1 day" +%Y-%m-%d)" == $date ]; then 
    echo "ERROR! No XML files for dates $(date -d "$cur +1 day" +%Y-%m-%d) to $(date -d "$date -1 day" +%Y-%m-%d)"
  fi
  cur=$date;
done
