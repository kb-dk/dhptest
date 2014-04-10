#!/bin/bash
i=$1    
cd $(dirname $(readlink -f $0))
mkdir -p ~/public_html/kfc/source/$i
./linkfiles.sh /sbftp-home/scan-dk/OUT/DR\ Live/"$i" ~/public_html/kfc/source/$i
cd ~/quack
./quack.sh ~/public_html/kfc/source/$i ~/public_html/kfc/$i
