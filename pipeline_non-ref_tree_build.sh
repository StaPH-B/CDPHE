#!/bin/bash
declare -a srr=() #PASTE IN ANY SRR NUMBERS INTO FILE named: SRR
while IFS= read -r line; do
    srr+=("$line")
done < ./SRR
#find . -maxdepth 1 -name "*fastq*" |cut -d '-' -f 1|cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiters here are '-' and '_')
find . -maxdepth 1 -name "*fastq*" |cut -d '_' -f 1 |cut -d '/' -f 2 >tmp1 #output all fastq file identifiers in cwd to file tmp1 (the delimiter here is '_')
more tmp1
declare -a tmp=()
tmp1='tmp1'
tmpfile=`cat $tmp1`
for line in $tmpfile; do
    tmp=("${tmp[@]}" "$line");
done
ill=($(printf "%s\n" "${tmp[@]}"|sort -u)) #Get all unique values and output them to array
ill=("${ill[@]}" "${srr[@]}") #Combine the automatically generated list with the SRR list
#echo "${ill[@]}"
rm tmp
rm tmp1

##### Fetch and fastq-dump all reads from NCBI identified by "SRR" #####
for i in ${ill[@]}; do
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
mkdir clean
echo "cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning cleaning"
for i in *R1_001.fastq.gz; do
    b=`basename ${i} _R1_001.fastq.gz`;
    if find ./clean/${b}.cleaned.fastq.gz; then
        continue
    else
        run_assembly_shuffleReads.pl ${b}"_R1_001.fastq.gz" ${b}"_R2_001.fastq.gz" > clean/${b}.fastq;
        echo ${b};
        run_assembly_trimClean.pl -i clean/${b}.fastq -o clean/${b}.cleaned.fastq.gz --nosingletons;
        rm clean/${b}.fastq;
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
        rm clean/${b}.fastq;
    fi
done
echo 'Reads trimmed.'

##### Run SPAdes de novo genome assembler on all cleaned, trimmed, fastq files #####
mkdir $PWD/spades_assembly_trim
for i in ${ill[@]}; do
    if (find ./spades_assembly_trim/$i/contigs.fasta); then #This will print out the size of the spades assembly if it already exists
        size=$(du -s ./spades_assembly_trim/$i/contigs.fasta | awk '{print $1}');
        echo 'File exists and is '$size'MB big.'
    else
        echo 'constructing assemblies for '$i', could take some time...'
         spades.py --pe1-12 ./clean/*${i}*.cleaned.fastq.gz -o spades_assembly_trim/${i}/
    fi
done

##### Run quast assembly statistics for verification that the assemblies worked #####
mkdir $PWD/quast
for i in ${ill[@]}; do
    quast.py spades_assembly_trim/$i/contigs.fasta -o quast/$i
done

##### Run prokka on all the isolates to get the core genomes and generate .gff files #####
mkdir ./prokka
for i in ${ill[@]}; do
    if (find ./prokka/$i); then
        echo "Prokka has been run on this isolate."
    else
        echo "Prokka will now be run on "$i
        prokka spades_assembly_trim/$i/contigs.fasta --outdir prokka/$i --prefix $i
    fi
done

rm -r ./gff_files
mkdir ./gff_files #make directory to hold the .gff files output by prokka
cp prokka/*/*.gff gff_files/ #copy over the .gff files from prokka

##### Run roary using the .gff file folder #####
rm -r roary
roary -p 8 -e -n -v -f ./roary ./gff_files/*.gff

##### Run raxml using the GTRGAMMA model on the data to generate a tree #####
raxmlHPC -m GTRGAMMA -p 12345 -s roary/core_gene_alignment.aln -#20 -n phylo_output
rm -r raxml/
mkdir raxml
mv RAxML* raxml/
