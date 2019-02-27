#!/bin/bash
if find logfile.txt;
then
    cat logfile.txt >> logfile_prev.txt
fi

command time -v /home/staphb/scripts/nanopore-scripts/nanopore-data-wrangling.sh |& tee logfile.txt
