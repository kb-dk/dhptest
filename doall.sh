#!/bin/bash
cd $(dirname $(readlink -f $0))
lockfile -r 0 /tmp/kfc/var/lock/cron || exit 1
find /sbftp-home/scan-dk/OUT/DR\ Live/* -maxdepth 0 -mmin +600 -printf %f\\n | while read i; do
    cd $(dirname $(readlink -f $0))
    if [ \! -e var/lock/"$i" ]; then
	touch var/lock/"$i"
        ./pbcoretest.sh /sbftp-home/scan-dk/OUT/DR\ Live/"$i"/XML "$i".pbcore;
        ./martin "$i".pbcore
        ./pdfbatch.sh /sbftp-home/scan-dk/OUT/DR\ Live/"$i" "$i".batch
        ./ditte /sbftp-home/scan-dk/OUT/DR\ Live/"$i" "$i".batch
        mkdir -p ~/public_html/kfc/source/$i
        ./linkfiles.sh /sbftp-home/scan-dk/OUT/DR\ Live/"$i" ~/public_html/kfc/source/$i
        cd ~/quack
        ./quack.sh ~/public_html/kfc/source/$i ~/public_html/kfc/$i
    fi
done
cd $(dirname $(readlink -f $0))
rm -f /tmp/kfc/var/lock/cron
