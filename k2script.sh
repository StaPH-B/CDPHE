#!/bin/bash
#Authors: Curtis Kapsak
# This script must be run in a similar fashion to type_pipe and other scripts.
# Needs to be run from the top-level DIR containing fastq files


#This function will check if the file exists before trying to remove it
remove_file() {
    if [ -e $1 ];then
        echo "File $1 has been removed"
        rm -rf $1
    fi
}
#This function will check to make sure the directory doesn't already exist before trying to create it
make_directory() {
    if [ -e $1 ]; then
        echo "Directory "$1" already exists"
    else
        mkdir $1
        echo "Directory "$1" has been created"
    fi
}

THREADS=$(nproc --all)
echo "Number of threads set to: $THREADS"
export THREADS

##### Move all fastq files from fastq_files directory up one directory, remove fastq_files folder #####
if [[ -e ./fastq_files ]]; then
    echo "Moving fastq files from ./fastq_files to ./ (top-level DIR)"
    mv ./fastq_files/* .
    rm -rf ./fastq_files
fi

declare -a srr=() #PASTE IN ANY SRR NUMBERS INTO FILE named: SRR
while IFS= read -r line; do
    srr+=("$line")
done < ./SRR 2>/dev/null
#find . -maxdepth 1 -name '*fastq*' |cut -d '-' -f 1|cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiters here are '-' and '_')
find . -maxdepth 1 -name '*fastq*' |cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiters here are '_')
declare -a tmp=()
tmp1='tmp1'
tmpfile=`cat $tmp1`
for line in $tmpfile; do
    tmp=("${tmp[@]}" "$line");
done
id=("${tmp[@]}" "${srr[@]}") #Combine the automatically generated list with the SRR list
id=($(printf "%s\n" "${id[@]}"|sort -u)) #Get all unique values and output them to an array
echo ${id[@]}
remove_file tmp


make_directory kraken2
for i in ${id[@]}; do
    if [[ -e ./kraken2/${i}.kraken2-output  ]]; then
        echo "Isolate ${i} has been krakked by kraken2 using custom GTDB database."
    else
        kraken2 --db ~/downloads/GTDB_Kraken/gtdbk2_bacterial \
                --gzip-compressed  \
                --paired  \
                --output kraken2/${i}.kraken2-output \
                --report kraken2/${i}.kraken2-report \
                --threads 30 \
                ./${i}*.fastq.gz # input PE reads
    fi
done

##### Move all of the fastq.gz files into a folder #####
make_directory fastq_files
for i in ${id[@]}; do
    if [[ -n "$(find *$i*fastq.gz)" ]]; then
        mv *$i*fastq.gz fastq_files
    fi
done
