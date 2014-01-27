#!/bin/bash
cd $(dirname $(readlink -f $0))
lockfile -r 0 /tmp/kfc/var/lock/crontv2 || exit 1
find /sbftp-home/scan-dk/OUT/TV\ Live/* -maxdepth 0 -mmin +600 -printf %f\\n | while read i; do
    cd $(dirname $(readlink -f $0))
    if [ \! -e var/lock/tv2"$i" ]; then
	touch var/lock/tv2"$i"
        ./pbcoretesttv2.sh /sbftp-home/scan-dk/OUT/TV\ Live/"$i"/XML tv2"$i".pbcore;
        ./martin tv2"$i".pbcore
        ./pdfbatchtv2.sh /sbftp-home/scan-dk/OUT/TV\ Live/"$i" tv2"$i".batch
        ./ditte /sbftp-home/scan-dk/OUT/TV\ Live/"$i" tv2"$i".batch
        mkdir -p ~/public_html/kfc/source/tv2$i
        ./linkfilestv2.sh /sbftp-home/scan-dk/OUT/TV\ Live/"$i" ~/public_html/kfc/source/tv2$i
        cd ~/quack
        ./quack.sh ~/public_html/kfc/source/tv2$i ~/public_html/kfc/tv2$i
    fi
done
cd $(dirname $(readlink -f $0))
rm -f /tmp/kfc/var/lock/crontv2
