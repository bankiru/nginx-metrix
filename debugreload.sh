#!/usr/bin/env bash

WATCHPATH=`pwd`

TIMEFILE=$(mktemp)

EVENTS="-e modify -e attrib -e close_write -e moved_to -e moved_from -e move -e move_self -e create -e delete -e delete_self -e unmount"

inotifywait -rm ${EVENTS} --timefmt "%F_%T" --format "%T %e" ${WATCHPATH} | while read t e; do
    if [ ! -s ${TIMEFILE} ] || [ "`cat ${TIMEFILE}`" != "${t}" ]; then
        echo ${t} > ${TIMEFILE}
        (sleep 1; sudo service nginx restart; echo RESTARTED) &
    fi
done