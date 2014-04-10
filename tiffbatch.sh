#!/bin/bash
D=$1
ANTAL=0
DEBUG=0

TIF=""
CHECKSUM=../../FEJLRETTELSE\ 17-03-2014/$(basename $D)/CHECKSUM
MIXXML=../../FEJLRETTELSE\ 17-03-2014/$(basename $D)/MIXXML
TIFFTAGS=10

date | tee log

A=$(ls "$D/$TIF/"*.tif|wc -l); for I in $(seq 1 $A); do N=$(printf "%03d" $I); C=$(ls "$D/$TIF/"*_$N\.tif 2>&1 | grep -v tif$ | wc -l); if [ ! $C -eq 0 ]; then echo Error in sequence: $D: $N not found; fi; done|tee -a log

ls "$D/$TIF/"*.tif | while read I; do ANTAL=$(echo $ANTAL+1 | bc)
F=$(basename "$I")
echo $ANTAL: $F - $I
B=$(echo $F | rev | cut -d'.' -f2- | rev)
FEJL=0

if [ $DEBUG -eq 1 ]; then echo MIX check; fi
if [ ! -f "$D/$MIXXML/"$B-MIX.xml ]; then echo Error: Missing MIX: $F; FEJL=$(echo $FEJL+1|bc); fi
if [ ! -f "$D/$CHECKSUM/"$B-MIX.xml-MD5.txt ]; then echo Error: Missing checksum for MIX: $F; FEJL=$(echo $FEJL+1|bc); fi
MD=$(md5sum "$D/$MIXXML/"$B-MIX.xml | awk '{print $1}')
if [ -z $MD ]; then MD="FOOBAR"; fi
MDTEST2=$(egrep -i $MD "$D/$CHECKSUM/"$B-MIX.xml-MD5.txt | wc -l);  if [ ! $MDTEST2 -eq 1 ]; then echo Error in MD5 for MIX i MD5 file: $F; fi

if [ ! $FEJL -eq 0 ]; then echo Number of errors: $FEJL; fi

if [ $DEBUG -eq 1 ]; then echo MIX content check; fi
FNTEST=$(egrep objectIdentifierValue\>$B "$D/$MIXXML/"$B-MIX.xml | wc -l); if [ ! $FNTEST -eq 1 ]; then echo Error in objectIdentifier in MIX: $F; fi
FS=$(ls -l $I | awk '{print $5}')
FSTEST=$(egrep fileSize\>$FS "$D/$MIXXML/"$B-MIX.xml | wc -l); if [ ! $FSTEST -eq 1 ]; then echo Error in fileSize in MIX: $F; fi

if [ $DEBUG -eq 1 ]; then echo TIF-MD5-tjek; fi
MD=$(md5sum $I | awk '{print $1}');
if [ -z $MD ]; then MD="FOOBAR"; fi
MDTEST5=$(egrep -i messageDigest\>$MD "$D/$MIXXML/"$B-MIX.xml | wc -l); if [ ! $MDTEST5 -eq 1 ]; then echo Error in MD5 for TIF in MIX file: $F; fi

if [ $DEBUG -eq 1 ]; then echo XML schema check; fi
CMIX=$(xmllint --noout --schema mix20.xsd "$D/$MIXXML/"$B-MIX.xml 2>&1 | grep validates$ | wc -l); if [ ! $CMIX -eq 1 ]; then echo $B-MIX.xml fails to validate; fi

if [ $DEBUG -eq 1 ]; then echo TIF file format check; fi
FORMAT=$(file $I | grep 'TIFF image data' | wc -l); if [ ! $FORMAT -eq 1 ]; then echo Error in TIF format: $(file $I); fi
jhove2/jhove2.sh "$I" > jhove2.output 2> /dev/null
VALID=$(grep "^   isValid: true" jhove2.output | wc -l); if [ ! $VALID -eq 1 ]; then echo "Error in TIF format - not valid: $(grep "^   isValid:" jhove2.output)"; fi
VERSION=$(grep "^   TiffVersion: 6" jhove2.output | wc -l); if [ ! $VERSION -eq 1 ]; then echo "Error in TIF format - wrong version (should be 6): $(grep "^   TiffVersion:" jhove2.output)"; fi

if [ $DEBUG -eq 1 ]; then echo TIF tags check; fi
TAGS=$(tiffinfo $I 2>&1 | wc -l); if [ ! $TAGS -eq $TIFFTAGS ]; then echo Error in TIF tags: number: $TAGS \(expected $TIFFTAGS\); fi

done | tee -a log
# ./ditte "$1"
