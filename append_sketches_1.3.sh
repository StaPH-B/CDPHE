#! /bin/bash
# Last revised 7/24/18 - CJK


#This function will check to make sure the directory doesn't already exist before trying to create it
make_directory () {
    if [[ $1=~"/" ]]; then
        if [[ -n "$(find -path $1 2>/dev/null)" ]]; then
            echo "Directory "$1" already exists"
        else
            mkdir $1
        fi;
    else
        if [[ -n "$(find $1 2>/dev/null)" ]]; then
            echo "Directory "$1" already exists"
        else
            mkdir $1
        fi;
    fi
}

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

#Make sure Basespace is connected
yes n | basemount /home/staphb/Basespace/

#Make sure the google storage bucket is connected/mounted to vm
gcsfuse test-20170718 ~/backup

#make_directory /home/staphb/databases/mash/mash_hist_db/
mkdir /home/staphb/databases/mash/mash_hist_db/ 
echo "Copying historical mash database from google storage bucket to /home/staphb/databases/mash/mash_hist_db/"
#The below line looks for .msh files in the storage bucket, then lists the most recently modified file, then lists the full path of that file. THEN, the copy command copies that file to the specified path on the VM.
cp $(readlink -f $(ls -t $(find ~/backup/logan/mash/*.msh -type f) | head -n 1)) /home/staphb/databases/mash/mash_hist_db/

#set the mash historical database path for use in loop structure below.
mash_hist_db=/home/staphb/databases/mash/mash_hist_db/
echo "Path for mash_hist_db is set to: "$mash_hist_db

#This section makes sure that the current sequencing run hasn't already been added
for i in /home/staphb/Basespace/Projects/*$SEQ_NUM*; do
    if [[ "${i}" =~ "SEQ" ]]; then
        if [[ ! "${i}" =~ "IDSEQ" ]]; then
            for h in "${i}/Samples/"*"/Files"; do
                PNUSA=$(echo $h | cut -d'/' -f8)
                cat $h/*R1_001.fastq* $h/*R2_001.fastq* > ${PNUSA}.fastq.gz;
                mash sketch -m 2 ${PNUSA}.fastq.gz;
                mash dist ${PNUSA}.fastq.gz.msh $mash_hist_db/*.msh > ${PNUSA}_distance.tab
                cut -f2 ${PNUSA}_distance.tab > second_column.tab
                if [[ -n $(grep "${PNUSA}" second_column.tab) ]]; then
                    echo "This seq run has already been added to historical isolates."
                    rm second_column.tab
                    rm ${PNUSA}_distance.tab
                    rm ${PNUSA}.fastq.gz
                    rm ${PNUSA}.fastq.gz.msh
                    exit
                else
                    echo "Adding these isolates now!"
                    rm second_column.tab
                    rm ${PNUSA}_distance.tab
                    break 2
                fi;
            done;
        fi;
    fi
done

mv $mash_hist_db/*.msh $mash_hist_db/tmp.msh

for i in /home/staphb/Basespace/Projects/*$SEQ_NUM*; do
    if [[ "${i}" =~ "SEQ" ]]; then
        if [[ ! "${i}" =~ "IDSEQ" ]]; then
            for h in "${i}/Samples/"*"/Files"; do
                PNUSA=$(echo $h | cut -d'/' -f8)
                cat $h/*R1_001.fastq* $h/*R2_001.fastq* > ${PNUSA}.fastq.gz;
                mash sketch -m 2 ${PNUSA}.fastq.gz;
                mash paste wgsSketch${PNUSA}.msh ${PNUSA}.fastq.gz.msh $mash_hist_db/tmp.msh;
                mv wgsSketch${PNUSA}.msh $mash_hist_db/tmp.msh;
                rm ${PNUSA}.fastq.gz;
                rm ${PNUSA}.fastq.gz.msh
            done;
        fi;
    fi;
done
mv $mash_hist_db/tmp.msh /home/staphb/backup/logan/mash/wgs_CO_sketches_$(date +'%m%d%y')_$SEQ_NUM.msh
