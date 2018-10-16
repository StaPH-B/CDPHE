#!/bin/bash
#USAGE: From the home directory (/home/staphb/) run:
# quality_and_coverage_X.X.sh  \
#                            -n xxx  \  #to specify the sequencing run number
#                            -l x       #to specify the sequencing run letter (if there is one)
#
#The script will copy all the E. coli, campy, shigella, listeria, vibrio, and
#pseudomonas isolates from their respective basepace folder, run CG_pipeline
#to clean the reads, then it runs the read metric script from the clean folder.
#
#This script will also call the run_type_pipe_X.X.sh script to run the cleaned
#reads through Kraken, Mash, SPAdes, QUAST, SeqSero, SISTR, Serotypefinder, and
#abricate

#Go through a parameters file with a line for each: species,genomesize,extension
declare -a spp_variables=()
while IFS= read -r line; do
    spp_variables+=("$line")
done < /home/staphb/scripts/spp_variables.txt

for line in ${spp_variables[@]}; do
    variables=(${line//,/ })
    species=${variables[0]}  #"salmonella"
    genome_length=${variables[1]} #5000000
    extension=${variables[2]} #"Salmonella"

    echo "$species"
    echo "$genome_length"
    echo "$extension"

    #First, go through the arguments and store seq file number
    while test $# -gt 0
    do
        case $1 in
            -n)
                SEQUENCE_NUM=$2
                shift
                ;;
            -l)
                LETTER=$2
                shift
                ;;
            *)
                echo >$2 "Invalid argument: $1"
        esac
        shift
    done

    #Set the number to three digits and add letter if exists
    printf -v SEQ_NUM "%03d" $SEQUENCE_NUM
    SEQ_NUM=$SEQ_NUM$LETTER

    #mkdir SEQ${SEQ_NUM}
    echo $SEQ_NUM

    #Make folder for SEQ run
    mkdir -p SEQ${SEQ_NUM}/${species}

    #Copy all the files from basespace into the newly created folder.
    yes n | basemount Basespace/
    cp ./Basespace/Projects/SEQ${SEQ_NUM}_QC_${extension}/Samples/*/Files/* SEQ${SEQ_NUM}/${species}

    #Check that there are actually fastq files, and if there aren't, end script and remove empty folders
    if [[ ! -z `find SEQ${SEQ_NUM}/${species} -maxdepth 1 -name "*fastq*"` ]]; then
        echo "This folder is not empty!"
    else
        echo "There are no fastq files here."
        rm -rf SEQ${SEQ_NUM}/${species}
        continue
    fi

    cd SEQ${SEQ_NUM}/${species}
    /home/staphb/scripts/run_type_pipe_2.2.sh -l "$genome_length"
    cd
done

for i in ./SEQ$SEQ_NUM/*; do
    if [[ -n $(find ${i}/clean/*.cleaned.fastq.gz 2>/dev/null) ]]; then
        echo "$i has data."
    else
        rm -r $i
    fi
done
