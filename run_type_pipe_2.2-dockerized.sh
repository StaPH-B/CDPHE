#!/bin/bash
if find logfile.txt;
then
    cat logfile.txt >> logfile_prev.txt
fi

#Set all the variables that need to be set
while test $# -gt 0
do
    case $1 in
        -l)
            SEQUENCE_LEN=$2
            echo "Genome Size: $SEQUENCE_LEN"
            shift
            ;;
    esac
    shift
done
command time -v /home/staphb/scripts/type_pipe_2.2-dockerized.sh -l $SEQUENCE_LEN |& tee logfile.txt

