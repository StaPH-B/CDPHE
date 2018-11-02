#!/bin/bash
if find logfile_non-ref.txt;
then
    cat logfile_non-ref.txt >> logfile_non-ref_prev.txt
fi
/home/staphb/scripts/pipeline_non-ref_tree_build_1.2-dockerized.sh |& tee logfile_non-ref.txt
