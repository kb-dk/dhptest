#!/bin/bash
LOG="${1:-log}"
echo Number of files analyzed: $(grep ^[0-9] $LOG | sort -u | wc -l) 
echo ALTO XML errors: $(./fejl.sh $LOG | egrep -i 'alto.*fails to validate' | wc -l) \(may have false positives\)
echo MODS XML errors: $(egrep -i 'mods.*fails to validate' $LOG | wc -l) \(may have false positives\)
AF=$(grep -i Error $LOG | grep -i -v "fails to validate" |wc -l);
echo Other errors: $AF; if [ $AF -ge 1 ]; then grep -i Error $LOG | grep -i -v "fails to validate"; fi
