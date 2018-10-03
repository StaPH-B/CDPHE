#! /bin/bash

while test $# -gt 0
do
    case $1 in
        -n)
            SEQUENCE_NUM=$2
            shift
            ;;
        *)
            echo >$2 "Invalid argument: $1"
    esac
    shift
done

#Set the number to three digits
printf -v SEQ_NUM "%03d" $SEQUENCE_NUM

#mkdir SEQ${SEQ_NUM}
echo $SEQ_NUM

#mv SEQ050-SEQ71_sketches.msh tmp.msh
mv wgs_CO_sketches.msh tmp.msh 
num=1
for i in /home/staphb/BaseSpace/Projects/*$SEQ_NUM*; do
    if [[ "${i}" =~ "SEQ" ]]; then
        if [[ ! "${i}" =~ "IDSEQ" ]]; then
            for h in "${i}/Samples/"*"/Files"; do
                PNUSA=$(echo $h | cut -d'/' -f8)
                cat $h/*R1_001.fastq* $h/*R2_001.fastq* > ${PNUSA}.fastq.gz;
                mash sketch -m 2 ${PNUSA}.fastq.gz;
                mash paste wgsSketch${PNUSA}.msh ${PNUSA}.fastq.gz.msh tmp.msh;
                mv wgsSketch${PNUSA}.msh tmp.msh;
                rm ${PNUSA}.fastq.gz;
                rm ${PNUSA}.fastq.gz.msh
            done;
        fi;
    fi;
done
mv tmp.msh wgs_CO_sketches.msh
