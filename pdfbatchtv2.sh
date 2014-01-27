#!/bin/bash
D=$1
ANTAL=0
DEBUG=0
LOGFILE="${2:-log}"

ALTO=ALTO
MODSXML=MODS
PDF=PDF
TIFFHOME=/sbftp-home/scan-dk/TV2

date|tee $LOGFILE

ls "$D/$PDF/"*.pdf | while read I; do 
ANTAL=$(echo $ANTAL+1 | bc)
F=$(basename "$I")
echo $ANTAL: $F - $I
B=$(echo $F | cut -d'.' -f1)
FEJL=0

if [ $DEBUG -eq 1 ]; then echo ALTO check; fi
if [ ! -f "$D/$ALTO/"$B.xml ]; then echo Error: Missing ALTO: $F; FEJL=$(echo $FEJL+1|bc); fi

if [ $DEBUG -eq 1 ]; then echo MODS check; fi
if [ ! -f "$D/$MODSXML/"$B-MODS.xml ]; then echo Error: Missing MODS: $F; FEJL=$(echo $FEJL+1|bc); fi

if [ ! $FEJL -eq 0 ]; then echo Number of missing files: $FEJL; fi

if [ $DEBUG -eq 1 ]; then echo XML schema checks; fi
CALTO=$(xmllint --noout --schema alto-1-4-fixed.xsd "$D/$ALTO/"$B.xml 2>&1 | grep validates$ | wc -l); if [ ! $CALTO -eq 1 ]; then echo $B.xml \(ALTO\) fails to validate; fi
CMODS=$(xmllint --noout --schema mods-3-1.xsd "$D/$MODSXML/"$B-MODS.xml 2>&1 | grep validates$ | wc -l); if [ ! $CMODS -eq 1 ]; then echo $B-MODS.xml fails to validate; fi

if [ $DEBUG -eq 1 ]; then echo PDF file format check; fi
FORMAT=$(file "$D/$PDF/"$B.pdf | grep 'PDF document, version 1.6' | wc -l); if [ ! $FORMAT -eq 1 ]; then echo "Error: Wrong PDF format (assumed to be 1.6): $(file "$D/$PDF/"$B.pdf)"; fi
FORMAT2=$(jhove/jhove -l OFF "$D/$PDF/"$B.pdf | grep '^  Profile:.*ISO PDF/A-1' | wc -l); if [ ! $FORMAT2 -eq 1 ]; then echo "Error in PDF format (should be PDF-A): $(jhove/jhove -l OFF "$D/$PDF/"$B.pdf | grep '^  Profile')"; fi
FORMAT3=$(jhove/jhove -l OFF "$D/$PDF/"$B.pdf | grep '^  Status: Well-Formed and valid' | wc -l); if [ ! $FORMAT3 -eq 1 ]; then echo "Error in PDF format (invalid): $(jhove/jhove -l OFF "$D/$PDF/"$B.pdf | grep '^  Profile')"; fi

if [ $DEBUG -eq 1 ]; then echo ALTO contents check; fi
ALTOTIFFFIL=$(xpath -q -e "//fileName/text()" "$D/$ALTO/$B.xml"); ALTOTIFFDIR=$(echo $ALTOTIFFFIL|cut -d_ -f1); if [ ! -e $TIFFHOME/$ALTOTIFFDIR/$ALTOTIFFFIL ]; then echo "Error in ALTO file - referred TIFF file ($ALTOTIFFFIL) not found"; fi

if [ $DEBUG -eq 1 ]; then echo MODS contents check; fi
MODSIDENTIFIER=$(xpath -q -e "/mods:mods/mods:identifier[@type='local']/text()" "$D/$MODSXML/$B-MODS.xml"); if [ ! $MODSIDENTIFIER == $B ]; then echo "Error in MODS file - wrong identifier. Expected $B, was $MODSIDENTIFIER"; fi
MODSTIFFFIL="$(xpath -q -e "/mods:mods/mods:relatedItem/mods:identifier[@type='local']/text()" "$D/$MODSXML/$B-MODS.xml"|cut -d\" -f2).tif"; MODSTIFFDIR=$(echo $MODSTIFFFIL|cut -d_ -f1); if [ ! -e $TIFFHOME/$MODSTIFFDIR/$MODSTIFFFIL ]; then echo "Error in MODS file - referred TIFF file ($MODSTIFFFIL) not found"; fi
MODSSTARTDATE=$(xpath -q -e "/mods:mods/mods:subject/mods:temporal[@point='start']/text()" "$D/$MODSXML/$B-MODS.xml"); MODSENDDATE=$(xpath -q -e "/mods:mods/mods:subject/mods:temporal[@point='end']/text()" "$D/$MODSXML/$B-MODS.xml"); TIFFSTARTDATE=$(echo $MODSTIFFFIL|cut -d- -f1|tr . -); TIFFENDDATE=$(echo $MODSTIFFFIL|cut -d- -f2|cut -d_ -f1|tr . -); if [ "$MODSSTARTDATE" \< "$TIFFSTARTDATE" ] || [ "$MODSSTARTDATE" \> "$TIFFENDDATE" ] || [ "$MODSENDDATE" \< "$TIFFSTARTDATE" ] || [ "$MODSENDDATE" \> "$TIFFENDDATE" ]; then echo "Error in MODS file - start/stop dates $MODSSTARTDATE - $MODSENDDATE outside TIFF-file date range $TIFFSTARTDATE - $TIFFENDDATE"; fi
FILENAMEDATE=$(echo $B|cut -d- -f2-4); if [ "$MODSSTARTDATE" != "$FILENAMEDATE" ]; then echo "Error in MODS fil - start date $MODSSTARTDATE different from file name date $FILENAMEDATE"; fi
FILENAMESUFFIX=$(echo $B|rev|cut -d- -f1|rev|cut -d. -f1|sed -e 's/^0*//'); TIFFSUFFIX=$(echo $MODSTIFFFIL|cut -d_ -f2|cut -d. -f1|sed -e 's/^0*//'); if [ "$FILENAMESUFFIX" != "$TIFFSUFFIX" ]; then echo "Error in MODS file - MODS file ends with $FILENAMESUFFIX, but referred TIFF file ends with $TIFFSUFFIX."; fi

if [ $DEBUG -eq 1 ]; then echo PDF contents check; fi
PDFSIZE=$(stat -c %s  "$D/$PDF/"$B.pdf); if [ $PDFSIZE -lt 200000 ]; then echo "Error: Very small PDF file: File size $PDFSIZE"; fi

done | tee -a $LOGFILE
