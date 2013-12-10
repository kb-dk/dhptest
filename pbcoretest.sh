#!/bin/bash
TIFFDIR=/sbftp-home/scan-dk/DR
rm -f output
echo checking directory: $1 | tee -a output
echo $(find "$1" | grep xml | grep -v -i md5 | wc -l) XML files in total | tee -a output
echo $(find "$1" -type d | egrep '\-(P|U)\-' | wc -l) pages in total | tee -a output
echo . | tee -a output
echo checking XML-schema for all PBCore-files | tee -a output
echo . | tee -a output
find "$1" | grep xml | grep -v -i md5 | while read I; do  xmllint --noout --schema pbcore-1.3.xsd "$I" 2>&1; done | grep -v validates | tee -a output
echo . | tee -a output
echo number of programs on a page \< 10 | tee -a output
echo . | tee -a output
find "$1" -type d | egrep '\-(P|U)\-' | while read I; do A=$(find "$I" | grep -i xml$ | wc -l); echo $A programmer - $I; done | sort -n | egrep '^[0-9] ' | tee -a output
echo . | tee -a output
echo checking running numbers _NNN for all programs | tee -a output
echo . | tee -a output
find "$1" -type d | egrep '\-(P|U)\-' | while read I; do T=0; rm -f numtjek; touch numtjek; find "$I" -type f | egrep -i "xml$" | rev | cut -d'_' -f1 | rev | cut -c1-3 | sort -n | egrep -o '[0-9]*' | while read J; do T=$(echo $T+1 | bc); T1=`printf %03d $T`; if [ ! $J -eq $T1 ]; then echo ERROR: filename:$J - expected:$T1 >> numtjek; fi; done; TE=$(cat numtjek | wc -l | awk '{print $1}'); if [ $TE -ge 1 ]; then echo ERROR in running number for $I | tee -a output; cat numtjek | tee -a output; fi; done
echo . | tee -a output
echo checking valid dates | tee -a output
echo . | tee -a output
find "$1" | grep xml$ | while read I; do rm -f datotjek; touch datotjek; cat "$I" | grep dateAvailable | egrep -v '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}' | egrep [0-9] > datotjek; T2=$(cat datotjek | wc -l); if [ $T2 -ge 1 ]; then echo $I | tee -a output; cat datotjek | tee -a output;fi; done
echo . | tee -a output
echo checking end dates after start dates | tee -a output
echo . | tee -a output
find "$1" | grep xml$ | while read I; do START=$(cat "$I" | grep dateAvailableStart | egrep '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}' | cut -d'>' -f2 | cut -d'<' -f1); END=$(cat "$I" | grep dateAvailableEnd | egrep '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}' | cut -d'>' -f2 | cut -d'<' -f1); if [ ! -z $START ]; then if [ ! -z $END ]; then START1=$(date -d "$START" "+%s" 2>/dev/null); END1=$(date -d "$END" "+%s" 2>/dev/null); if [ ! -z $START1 ]; then if [ ! -z $END1 ]; then if [ ! $END1 -ge $START1 ]; then echo End before Start ERROR: $START $END $I | tee -a output; fi; else echo End invalid: $END $END1 $I | tee -a output; fi; else echo Start invalid: $START $START1 $I | tee -a output; fi; fi; fi; done
echo . | tee -a output
echo checking for multiple publishers in one XML field | tee -a output
echo . | tee -a output
find "$1" | grep xml$ | while read I; do rm -f publishers; touch publishers; cat "$I" | egrep "<publisher>" | egrep -i '(og | og|eller | eller)[^<]' | grep -v -i kalundbog > publishers; T=$(cat publishers | wc -l); if [ $T -ge 1 ]; then echo $I | tee -a output; cat publishers | tee -a output; fi; done
echo . | tee -a output
echo checking identifiers | tee -a output
echo . | tee -a output
find "$1" | grep xml$ | while read I; do IDF=$(echo $I | rev | cut -d'/' -f1 | rev | sed 's/\.xml//g'); IDX=$(cat "$I" | egrep '<identifier>' | cut -d'>' -f2 | cut -d'<' -f1 | sed 's/ID\://g'); if [ ! $IDF == $IDX ]; then echo filename:$IDF - identifier:$IDX $I | tee -a output; fi; done
echo . | tee -a output
echo checking number of \'Has Part\' and \'Is Part Of\' relations | tee -a output
echo . | tee -a output
HP=$(find "$1" | grep xml$ | while read I; do grep -i "has part" "$I"; done | wc -l); IP=$(find "$1" | grep xml$ | while read I; do grep -i "is part" "$I"; done| wc -l); if [ ! $HP -eq $IP ]; then echo Number of \'Has Part\' and \'Is Part Of\' is not identical: $HP \/ $IP - $1 | tee -a output; fi
echo . | tee -a output
echo checking \'Has Part\' relations to existing XML-files and reverse \'Is Part of\' relations | tee -a output
echo . | tee -a output
find "$1" | grep xml$ | while read I; do grep -A1 -i "has part" "$I" | grep -i relationidentifier | while read J; do DIR=$(echo $I | rev | cut -d'/' -f2- | rev); ORID=$(echo $I | rev | cut -d'/' -f1 | rev | sed 's/\.xml//g'); RELID=$(echo $J | cut -d'>' -f2 | cut -d'<' -f1); if [ $ORID == $RELID ]; then echo $ORID has relation to itself - $I | tee -a output; fi; RELFILE=$(echo "$DIR/$RELID.xml"); if [ ! -f "$RELFILE" ]; then echo in $ORID.xml Has Part Relation to \'$RELID\' but file not found: $RELFILE | tee -a output; else ANTAL=$(grep -A1 -i "is part" "$RELFILE" | grep -i relationidentifier | grep $ORID | wc -l); if [ ! $ANTAL -eq 1 ]; then echo missing \'Is Part Of\' relation from $RELFILE pointing at $ORID | tee -a output; fi; fi; done; done
echo . | tee -a output
echo checking \'Is Part Of\' relations to existing XML-files and reverse \'Has Part\' relations | tee -a output
echo . | tee -a output
find "$1" | grep xml$ | while read I; do grep -A1 -i "is part" "$I" | grep -i relationidentifier | while read J; do DIR=$(echo $I | rev | cut -d'/' -f2- | rev); ORID=$(echo $I | rev | cut -d'/' -f1 | rev | sed 's/\.xml//g'); RELID=$(echo $J | cut -d'>' -f2 | cut -d'<' -f1); if [ $ORID == $RELID ]; then echo $ORID has relation to itself - $I | tee -a output; fi; RELFILE=$(echo "$DIR/$RELID.xml"); if [ ! -f "$RELFILE" ]; then echo in $ORID.xml Is Part Of Relation to \'$RELID\' but file not found: $RELFILE | tee -a output; else ANTAL=$(grep -A1 -i "has part" "$RELFILE" | grep -i relationidentifier | grep $ORID | wc -l); if [ ! $ANTAL -eq 1 ]; then echo missing \'Has Part\' relation from $RELFILE pointing at $ORID | tee -a output; fi; fi; done; done
echo . | tee -a output
echo checking for identical programs \(content except identifiers\) | tee -a output
echo . | tee -a output
find "$1" | grep xml$ | while read I; do echo $(cat "$I" | grep -v -i identifier | md5sum) $(echo $I | rev | cut -d'/' -f1 | rev); done > md5sums; cat md5sums | cut -d' ' -f1 | sort | uniq -c | awk '{print $1" "$2}' | grep -v '^1 ' | cut -d' ' -f2 | while read I; do echo $(grep $I md5sums | cut -d' ' -f3) | tee -a output; done
echo . | tee -a output
echo checking md5sums | tee -a output
echo . | tee -a output
find "$1" -type f | grep "\(md5\|txt\)$" | while read I; do F=$(echo $I | rev | cut -d'/' -f2- |rev); ls "$F" | grep xml$ | while read J; do T=$(grep $J "$I" | wc -l); if [ $T -eq 1 ]; then CS2=$(md5sum "$F/$J" | cut -d' ' -f1); T2=$(grep $CS2 "$I" | wc -l); if [ ! $T2 -eq 1 ]; then echo MD5 mismatch: $CS2 $J $(grep $J "$I") | tee -a output; fi; else echo file $J NOT found in MD5-file: $I | tee -a output; fi; done; done
echo . | tee -a output
echo checking dates within tiff date range
echo . | tee -a output
find "$1" | grep xml$ | while read I; do START=$(cat "$I" | grep dateAvailableStart | egrep -o '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}' | cut -dT -f1); TIFFSTART=$(cat "$I" | grep formatLocation | egrep -o "[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9]{4}\.[0-9]{2}\.[0-9]{2}" | cut -d- -f1 | tr . - ); TIFFEND=$(cat "$I" | grep formatLocation | egrep -o "[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9]{4}\.[0-9]{2}\.[0-9]{2}" | cut -d- -f2 | tr . - ); TIFFEND=$(date -d "$TIFFEND +1 day" +"%Y-%m-%d"); if [ "$START" \< "$TIFFSTART" ] || [ "$START" \> "$TIFFEND" ] ; then echo "PBCore date in \'$I\' ($START) outside TIFF daterange ($TIFFSTART - $TIFFEND)" | tee -a output; fi; done
echo . | tee -a output
echo checking tiff files exist
echo . | tee -a output
find "$1" | grep xml$ | while read I; do TIFFFILE=$(cat "$I" | grep "<formatLocation>" | cut -d ">" -f2 | cut -d "<" -f1); TIFFSUBDIR=$(echo $TIFFFILE | cut -d_ -f1 ); if [ ! -f "$TIFFDIR/$TIFFSUBDIR/$TIFFFILE" ] ; then echo "TIFF file $TIFFDIR/$TIFFSUBDIR/$TIFFFILE" referred in "$I" not found | tee -a output; fi; done
echo . | tee -a output

echo FINISH

