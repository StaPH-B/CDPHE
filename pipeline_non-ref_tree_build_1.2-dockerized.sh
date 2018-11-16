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
            echo 'prefetching reads '$i' using sratoolkit docker container...'
            export i
            docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/sratoolkit:2.9.2 /bin/bash -c \
            'prefetch -O /data ${i}'
            echo 'now running fasterq-dump in container'
            docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/sratoolkit:2.9.2 /bin/bash -c \
            'fasterq-dump --skip-technical --split-files -t /data/tmp-dir -e 8 -O /data -p ${i}.sra'
            mv ${i}.sra_1.fastq ${i}_1.fastq
            mv ${i}.sra_2.fastq ${i}_2.fastq
            pigz ${i}_1.fastq
            pigz ${i}_2.fastq
            rm ${i}.sra
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
        echo "LYVESET CONTAINER RUNNING SHUFFLEREADS.PL"
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_shuffleReads.pl /data/${b}"_R1_001.fastq.gz" /data/${b}"_R2_001.fastq.gz" > clean/${b}.fastq;
        echo ${b};
        echo "LYVESET CONTAINER RUNNING TRIMCLEAN.PL"
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_trimClean.pl -i /data/clean/${b}.fastq -o /data/clean/${b}.cleaned.fastq.gz --nosingletons;
        remove_file clean/${b}.fastq;
    fi
done
for i in *_1.fastq.gz; do
    b=`basename ${i} _1.fastq.gz`;
    if find ./clean/${b}.cleaned.fastq.gz; then
        continue
    else
        echo "(run_assembly_shuffleReads.pl)Interleaving reads for:"${c}" using lyveset docker container"
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_shuffleReads.pl /data/${b}"_1.fastq.gz" /data/${b}"_2.fastq.gz" > clean/${b}.fastq;
        echo "(run_assembly_trimClean.pl) Trimming/cleaning reads for:"${c}" using lyveset docker container"
        docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/lyveset:2.0.1 \
        run_assembly_trimClean.pl -i /data/clean/${b}.fastq -o /data/clean/${b}.cleaned.fastq.gz --nosingletons;
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
        # make sure variable i is available to global env, to pass into container
        export i
        echo 'constructing assemblies for '$i', could take some time...'
        docker run -e i --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/spades:3.12.0 /bin/bash -c \
        'spades.py --pe1-12 /data/clean/${i}*.cleaned.fastq.gz --careful -o /data/spades_assembly_trim/${i}/'
        rm -rf ./spades_assembly_trim/$i/corrected \
		./spades_assembly_trim/$i/K21 \
                ./spades_assembly_trim/$i/K33 \
                ./spades_assembly_trim/$i/K55 \
                ./spades_assembly_trim/$i/K77 \
                ./spades_assembly_trim/$i/K99 \
                ./spades_assembly_trim/$i/K127 \
                ./spades_assembly_trim/$i/misc \
                ./spades_assembly_trim/$i/mismatch_corrector \
                ./spades_assembly_trim/$i/split_input \
                ./spades_assembly_trim/$i/tmp
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
        export i
        echo 'constructing assemblies for '$i', second try...'
        docker run -e i --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/spades:3.12.0 /bin/bash -c \
        'spades.py -o /data/new_temp/spades_assemblies/${i}/ --pe1-12 /data/new_temp/${i}_*.cleaned.fastq.gz --careful'
        rm -rf ./new_tmp/spades_assemblies/$i/corrected \
		./new_tmp/spades_assemblies/$i/K21 \
                ./new_tmp/spades_assemblies/$i/K33 \
                ./new_tmp/spades_assemblies/$i/K55 \
                ./new_tmp/spades_assemblies/$i/K77 \
                ./new_tmp/spades_assemblies/$i/K99 \
                ./new_tmp/spades_assemblies/$i/K127 \
                ./new_tmp/spades_assemblies/$i/misc \
                ./new_tmp/spades_assemblies/$i/mismatch_corrector \
                ./new_tmp/spades_assemblies/$i/split_input \
                ./new_tmp/spades_assemblies/$i/tmp
    fi
done
mv new_temp/spades_assemblies/* spades_assembly_trim/
remove_file new_temp

##### Run quast assembly statistics for verification that the assemblies worked #####
make_directory quast
for i in ${id[@]}; do
    docker run --rm=True -v $PWD:/data -u $(id -u):$(id -g) staphb/quast:5.0.0 \
    quast.py /data/spades_assembly_trim/$i/contigs.fasta -o /data/quast/$i
done

##### Run prokka on all the isolates to get the core genomes and generate .gff files #####
make_directory ./prokka
for i in ${id[@]}; do
    if [[ -n "$(find -path ./prokka/$i)" ]]; then
        echo "Prokka has been run on this isolate."
    else
        export i
        echo "Prokka will now be run on "$i
        docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/prokka:1.13.3 /bin/bash -c \
        'prokka /data/spades_assembly_trim/$i/contigs.fasta --outdir /data/prokka/$i --prefix $i'
    fi
done

remove_file -r ./gff_files
make_directory ./gff_files #make directory to hold the .gff files output by prokka
cp prokka/*/*.gff gff_files/ #copy over the .gff files from prokka

##### Run roary using the .gff file folder #####
rm -rf roary
docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/roary:3.12.0 /bin/bash -c \
'roary -p 8 -e -n -v -f /data/roary /data/gff_files/*.gff'

##### Run raxml on the roary alignment to generate a tree #####
docker run -e i --rm=True -u $(id -u):$(id -g) -v $PWD:/data staphb/lyveset:2.0.1-test /bin/bash -c \
'raxmlHPC -m GTRGAMMA -p 12345 -s /data/roary/core_gene_alignment.aln -#20 -n phylo_output'
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
