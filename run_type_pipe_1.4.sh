#!/bin/bash
if find logfile.txt;
then
    cat logfile.txt >> logfile_prev.txt
fi
/home/staphb/scripts/type_pipe_1.4.sh |& tee logfile.txt
