#!/bin/bash
#Author: Logan Fink
#Usage: script to create a reference free phylogenetic tree from a set of fastq files
#Permission to copy and modify is granted without warranty of any kind
#Last revised 06/29/18
#This function will check if the file exists before trying to remove it
remove_file () {
    if [[ $1=~"/" ]]; then
        if [[ -n "$(find -path $1 2>/dev/null)" ]]; then
            rm -rf $1
        else
            echo "Continuing on"
        fi;
    else
        if [[ -n "$(find $1 2>/dev/null)" ]]; then
            rm -rf $1;
        else
            echo "Continuing on"
        fi;
    fi
}
#This function wid check to make sure the directory doesn't already exist before trying to create it
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
##### Move all fastq files from fastq_files directory up one directory, remove fastq_files folder #####
if [[ -n "$(find ./fastq_files)" ]]; then
    mv ./fastq_files/* .
    rm -rf ./fastq_files
fi

declare -a srr=() #PASTE IN ANY SRR NUMBERS INTO FILE named: SRR
while IFS= read -r line; do
    srr+=("$line")
done < ./SRR
#find . -maxdepth 1 -name "*fastq*" |cut -d '-' -f 1|cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiters here are '-' and '_')
find . -maxdepth 1 -name "*fastq*" |cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiters here are '_')
declare -a tmp=()
tmp1='tmp1'
tmpfile=`cat $tmp1`
for line in $tmpfile; do
    tmp=("${tmp[@]}" "$line");
done
id=($(printf "%s\n" "${tmp[@]}"|sort -u)) #Get all unique values and output them to array
id=("${id[@]}" "${srr[@]}") #Combine the automatically generated list with the SRR list
remove_file tmp

##### Fetch and fastq-dump all reads from NCBI identified by "SRR" #####
for i in ${id[@]}; do
    if [[ $i =~ "SRR" ]]; then
        if (find ./*$i*); then
            echo "Files are here."
        else
            echo 'prefetching '$i'...'
            prefetch $i
            echo 'dumping reads '$i'...'
            fastq-dump --gzip --skip-technical --readids --dumpbase --split-files --clip $i
        fi
    fi
done

##### These are the QC trimming scripts as input to trimClean #####
make_directory clean
echo "cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning"
for i in *R1_001.fastq.gz; do
    b=`basename ${i} _R1_001.fastq.gz`;
    if [[ -n "$(find . -maxdepth 2 -name ${b}.cleaned.fastq.gz)" ]]; then
        continue
    else
        run_assembly_shuffleReads.pl ${b}"_R1_001.fastq.gz" ${b}"_R2_001.fastq.gz" > clean/${b}.fastq;
        echo ${b};
        run_assembly_trimClean.pl -i clean/${b}.fastq -o clean/${b}.cleaned.fastq.gz --nosingletons;
        remove_file clean/${b}.fastq;
    fi
done
for i in *_1.fastq.gz; do
    b=`basename ${i} _1.fastq.gz`;
    if find ./clean/${b}.cleaned.fastq.gz; then
        continue
    else
        run_assembly_shuffleReads.pl ${b}"_1.fastq.gz" ${b}"_2.fastq.gz" > clean/${b}.fastq;
        echo ${b};
        run_assembly_trimClean.pl -i clean/${b}.fastq -o clean/${b}.cleaned.fastq.gz --nosingletons;
        remove_file clean/${b}.fastq;
    fi
done
remove_file ./clean/\**

##### Run SPAdes de novo genome assembler on all cleaned, trimmed, fastq files #####
make_directory ./spades_assembly_trim
for i in ${id[@]}; do
    if [[ -n "$(find -path ./spades_assembly_trim/$i/contigs.fasta 2>/dev/null)" ]]; then #This will print out the size of the spades assembly if it already exists
        size=$(du -hs ./spades_assembly_trim/$i/contigs.fasta | awk '{print $1}');
        echo 'File exists and is '$size' big.'
    else
        echo 'constructing assemblies for '$i', could take some time...'
        echo "spades.py --pe1-12 ./clean/*"${i}"*.cleaned.fastq.gz -o spades_assembly_trim/"${i}"/"
        spades.py --pe1-12 ./clean/*${i}*.cleaned.fastq.gz -o spades_assembly_trim/${i}/
    fi
done

make_directory new_temp
make_directory new_temp/spades_assemblies
for i in ${id[@]}; do
    if [[ -n "$(find -path ./spades_assembly_trim/$i/contigs.fasta 2>/dev/null)" ]]; then
        continue
    else
        cp ./clean/${i}*.cleaned.fastq.gz new_temp/
        spades_file=./clean/${i}*.cleaned.fastq.gz
        echo $spades_file
        echo 'constructing assemblies for '$i', second try...'
        spades.py -o new_temp/spades_assemblies/${i}/ --pe1-12 ./new_temp/${i}_*.cleaned.fastq.gz
    fi
done
mv new_temp/spades_assemblies/* spades_assembly_trim/
remove_file new_temp

##### Run quast assembly statistics for verification that the assemblies worked #####
make_directory quast
for i in ${id[@]}; do
    quast.py spades_assembly_trim/$i/contigs.fasta -o quast/$i
done

##### Run prokka on all the isolates to get the core genomes and generate .gff files #####
make_directory ./prokka
for i in ${id[@]}; do
    if [[ -n "$(find -path ./prokka/$i)" ]]; then
        echo "Prokka has been run on this isolate."
    else
        echo "Prokka will now be run on "$i
        prokka spades_assembly_trim/$i/contigs.fasta --outdir prokka/$i --prefix $i
    fi
done

remove_file -r ./gff_files
make_directory ./gff_files #make directory to hold the .gff files output by prokka
cp prokka/*/*.gff gff_files/ #copy over the .gff files from prokka

##### Run roary using the .gff file folder #####
rm -rf roary
roary -p 8 -e -n -v -f ./roary ./gff_files/*.gff

##### Run raxml on the roary alignment to generate a tree #####
raxmlHPC -m GTRGAMMA -p 12345 -s roary/core_gene_alignment.aln -#20 -n phylo_output
rm -rf raxml/
make_directory raxml
mv RAxML* raxml/

##### Move all of the fastq.gz files into a folder #####
make_directory fastq_files
for i in ${id[@]}; do
    if [[ -n "$(find *$i*fastq.gz)" ]]; then
        mv *$i*fastq.gz fastq_files
    fi
done
