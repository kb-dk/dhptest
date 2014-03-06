#!/bin/bash

TIFFHOME=/sbftp-home/scan-dk/DR
MODSXML=MODS
ALTO=ALTO

if [ -z $2 ]; then
  echo "Usage: $0 <batchdir> <outputdir>"
  exit 1
fi

D=$1
OUT=$2

ls "$D/$ALTO/"*.xml | sort -R | head -n 100 | while read ALTOFILE; do
  B=$(basename "$ALTOFILE" .xml)
  MODSTIFFFIL="$(xpath -q -e "/mods:mods/mods:relatedItem/mods:identifier[@type='local']/text()" "$D/$MODSXML/$B-MODS.xml"|cut -d\" -f2).tif"
  MODSTIFFDIR=$(echo "$MODSTIFFFIL"|cut -d_ -f1) 
  TIFFFILE="$TIFFHOME/$MODSTIFFDIR/$MODSTIFFFIL"
  ln -s "$ALTOFILE" "$OUT/$B.alto.xml"
  ln -s "$TIFFFILE" "$OUT/$B.tif"
done
