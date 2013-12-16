#!/bin/bash
LOG={$1:-log}
egrep -v '^[0-9]' $LOG | grep -v 'CET 2011' | grep -v TIF-tags
grep -B1 tags $LOG
