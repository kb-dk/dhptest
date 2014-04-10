#!/bin/bash
i=$1
cd $(dirname $(readlink -f $0))
mkdir -p ~/public_html/kfc/source/tv2$i
./linkfilestv2.sh /sbftp-home/scan-dk/OUT/TV\ Live/"$i" ~/public_html/kfc/source/tv2$i
cd ~/quack
./quack.sh ~/public_html/kfc/source/tv2$i ~/public_html/kfc/tv2$i
